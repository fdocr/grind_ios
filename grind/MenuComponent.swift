//
//  MenuComponent.swift
//  grind
//
//  Bridge component named "menu". The web side (rendered only inside the native
//  apps, see shared/_native_menu) sends a "connect" message on every page. In
//  response we add a hamburger button to the navigation bar. Tapping it replies
//  to that same "connect" message, which tells the web to toggle its existing nav
//  menu panel — reusing the web menu (Home, My Rounds, Sign in/out, About, admin)
//  as the single source of truth.
//
//  Message protocol (must match the web menu_bridge controller):
//    web -> native  "connect" { title }   (page rendered the menu)
//    native -> web  reply(to: "connect")  (button tapped -> toggle web panel)
//

import Foundation
import HotwireNative
import UIKit

final class MenuComponent: BridgeComponent {
    override nonisolated class var name: String { "menu" }

    override func onReceive(message: Message) {
        guard message.event == "connect" else { return }
        addMenuButton(with: message)
    }

    private var viewController: UIViewController? {
        delegate?.destination as? UIViewController
    }

    private func addMenuButton(with message: Message) {
        guard let viewController else { return }

        let data: MessageData? = message.data()
        let title = data?.title ?? "Menu"

        let action = UIAction { [weak self] _ in
            self?.reply(to: "connect")
        }
        let item = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal"),
            primaryAction: action
        )
        item.accessibilityLabel = title
        viewController.navigationItem.rightBarButtonItem = item
    }

    private struct MessageData: Decodable {
        let title: String?
    }
}
