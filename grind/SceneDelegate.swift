//
//  SceneDelegate.swift
//  grind
//

import HotwireNative
import UIKit

let rootURL = URL(string: "https://grind.fdo.cr")!
//let rootURL = URL(string: "https://fernandos-macbook-air.tail5b20ea.ts.net")!

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private var navigator = Navigator(configuration: Navigator.Configuration(name: "main", startLocation: rootURL))

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = .white
        window.tintColor = UIColor(red: 39 / 255, green: 111 / 255, blue: 84 / 255, alpha: 1)
        self.window = window

        // Get URL components from the incoming user activity.
        guard let userActivity = connectionOptions.userActivities.first,
            userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let incomingURL = userActivity.webpageURL,
            let currentURL = navigator.activeWebView.url,
              incomingURL.lastPathComponent != currentURL.lastPathComponent else {

            window.rootViewController = navigator.rootViewController
            window.makeKeyAndVisible()
            navigator.start()
            return
        }

        window.rootViewController = navigator.rootViewController
        window.makeKeyAndVisible()
        navigator.start()
        guard incomingURL.lastPathComponent != "/" else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            navigator.route(incomingURL)
        }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard let incomingURL = userActivity.webpageURL,
              let currentURL = navigator.activeWebView.url,
              incomingURL.lastPathComponent != currentURL.lastPathComponent else { return }

        navigator.activeNavigationController.popToRootViewController(animated: true)

        guard incomingURL.lastPathComponent != "/" else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            navigator.route(incomingURL)
        }
    }
}
