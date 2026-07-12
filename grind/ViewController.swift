//
//  ViewController.swift
//  grind
//

import HotwireNative
import UIKit
import WebKit

/// Keeps native chrome white while Turbo visits load, matching the light web UI.
final class GrindWebViewController: HotwireWebViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        visitableView.backgroundColor = .white
    }
}
