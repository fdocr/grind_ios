//
//  GeolocationComponent.swift
//  grind
//
//  Bridge component named "geolocation". It streams high-accuracy CoreLocation
//  updates to the web "distances" Stimulus controller, so the WKWebView never
//  has to prompt for location itself (avoiding the double permission prompt).
//  The web side falls back to navigator.geolocation when this component isn't
//  registered (i.e. in a browser/PWA).
//
//  Message protocol (must match the Android component and the web controller):
//    web -> native  "start"  (begin streaming)
//    native -> web  reply(to: "start") { latitude, longitude, accuracy }
//                   reply(to: "start") { error: "denied" | "unavailable" }
//    web -> native  "stop"   (stop streaming, no reply)
//

import CoreLocation
import Foundation
import HotwireNative
import UIKit

final class GeolocationComponent: BridgeComponent {
    override nonisolated class var name: String { "geolocation" }

    private lazy var provider: LocationProvider = {
        let provider = LocationProvider()
        provider.onUpdate = { [weak self] latitude, longitude, accuracy in
            Task { @MainActor in
                self?.replyWithLocation(latitude: latitude, longitude: longitude, accuracy: accuracy)
            }
        }
        provider.onDenied = { [weak self] in
            Task { @MainActor in self?.reply(error: "denied") }
        }
        provider.onUnavailable = { [weak self] in
            Task { @MainActor in self?.reply(error: "unavailable") }
        }
        return provider
    }()

    // Tracks whether we've already asked at least once, so a *repeated* attempt
    // while access is denied escalates to the native "Open Settings" prompt.
    private var hasRequestedOnce = false

    override func onReceive(message: Message) {
        switch message.event {
        case "start":
            handleStart()
        case "stop":
            provider.stop()
        default:
            break
        }
    }

    /// Modal sessions can keep the web view alive after dismiss; stop CoreLocation
    /// when the destination leaves the hierarchy so GPS does not keep streaming.
    override func onViewDidDisappear() {
        provider.stop()
    }

    private func handleStart() {
        switch provider.authorizationStatus {
        case .denied, .restricted:
            if hasRequestedOnce {
                presentSettingsPrompt()
            }
            hasRequestedOnce = true
            reply(error: "denied")
        default:
            hasRequestedOnce = true
            provider.start()
        }
    }

    private func replyWithLocation(latitude: Double, longitude: Double, accuracy: Double) {
        reply(to: "start", with: LocationData(latitude: latitude, longitude: longitude, accuracy: accuracy))
    }

    private func reply(error: String) {
        reply(to: "start", with: ErrorData(error: error))
    }

    private func presentSettingsPrompt() {
        guard let viewController = delegate?.destination as? UIViewController else { return }

        let alert = UIAlertController(
            title: "Location access needed",
            message: "Enable location for Grind in Settings to see live distances to the green.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Not now", style: .cancel))
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        viewController.present(alert, animated: true)
    }

    private struct LocationData: Encodable {
        let latitude: Double
        let longitude: Double
        let accuracy: Double
    }

    private struct ErrorData: Encodable {
        let error: String
    }
}

/// Thin CoreLocation wrapper. Kept separate from the @MainActor bridge component
/// so it can be the (non-isolated) CLLocationManagerDelegate. It only ever hands
/// back Sendable primitives, so results can hop to the main actor safely.
final class LocationProvider: NSObject, CLLocationManagerDelegate {
    var onUpdate: ((Double, Double, Double) -> Void)?
    var onDenied: (() -> Void)?
    var onUnavailable: (() -> Void)?

    private let manager = CLLocationManager()
    private var isActive = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
    }

    var authorizationStatus: CLAuthorizationStatus {
        manager.authorizationStatus
    }

    func start() {
        isActive = true
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            onDenied?()
        @unknown default:
            onDenied?()
        }
    }

    func stop() {
        isActive = false
        manager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard isActive else { return }
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            onDenied?()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        onUpdate?(location.coordinate.latitude, location.coordinate.longitude, location.horizontalAccuracy)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError, clError.code == .denied {
            onDenied?()
        } else {
            onUnavailable?()
        }
    }

    deinit {
        manager.stopUpdatingLocation()
    }
}
