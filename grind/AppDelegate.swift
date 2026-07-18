//
//  AppDelegate.swift
//  grind
//

import UIKit
import WebKit
import HotwireNative

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configureAppearance()

        let localPathConfigURL = Bundle.main.url(forResource: "path-configuration", withExtension: "json")!
//        let remotePathConfigURL = URL(string: "https://grind.fdo.cr/configurations/ios_v1.json")!
        let remotePathConfigURL = URL(string: "https://fernandos-macbook-air.tail5b20ea.ts.net/configurations/ios_v1.json")!

        Hotwire.registerBridgeComponents([
            GeolocationComponent.self,
            MenuComponent.self
        ])

        Hotwire.loadPathConfiguration(from: [
            .file(localPathConfigURL),
            .server(remotePathConfigURL)
        ])

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }

    // MARK: Appearance

    /// Opaque nav bar / loading surfaces aligned with the web styleguide tokens in
    /// `app/assets/tailwind/application.css` (card / foreground / primary).
    private enum BrandColor {
        /// `--color-card` / `--color-background`
        static let card = UIColor.white
        /// `--color-foreground` (#0f172a)
        static let foreground = UIColor(red: 15 / 255, green: 23 / 255, blue: 42 / 255, alpha: 1)
        /// `--color-primary-600` (#276f54) — same as AccentColor
        static let primary = UIColor(red: 39 / 255, green: 111 / 255, blue: 84 / 255, alpha: 1)
        /// `--color-border` (#e2e8f0)
        static let border = UIColor(red: 226 / 255, green: 232 / 255, blue: 240 / 255, alpha: 1)
    }

    private func configureAppearance() {
        configureNavigationBarAppearance()
        configureHotwireAppearance()
    }

    /// Match the web header: solid white bar, dark title, fairway-green controls.
    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = BrandColor.card
        appearance.shadowColor = BrandColor.border
        appearance.titleTextAttributes = [.foregroundColor: BrandColor.foreground]
        appearance.largeTitleTextAttributes = [.foregroundColor: BrandColor.foreground]

        let bar = UINavigationBar.appearance()
        bar.isTranslucent = false
        bar.tintColor = BrandColor.primary
        bar.standardAppearance = appearance
        bar.compactAppearance = appearance
        bar.scrollEdgeAppearance = appearance
        bar.compactScrollEdgeAppearance = appearance
    }

    /// Avoid the black blink while pages load (Hotwire defaults to `.systemBackground`,
    /// which is black in dark mode before the light web UI paints).
    private func configureHotwireAppearance() {
        // Modals dismiss via swipe-down; no Done/Close bar button.
        Hotwire.config.showDoneButtonOnModals = false

        Hotwire.config.defaultViewController = { url in
            GrindWebViewController(url: url)
        }

        Hotwire.config.makeCustomWebView = { configuration in
            let webView = WKWebView(frame: .zero, configuration: configuration)
            webView.isOpaque = true
            webView.backgroundColor = BrandColor.card
            webView.scrollView.backgroundColor = BrandColor.card
            #if DEBUG
            if #available(iOS 16.4, *) {
                webView.isInspectable = true
            }
            #endif
            return webView
        }

        Hotwire.config.defaultNavigationController = {
            let navigationController = HotwireNavigationController()
            navigationController.view.backgroundColor = BrandColor.card
            return navigationController
        }
    }
}
