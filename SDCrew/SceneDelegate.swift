//
//  SceneDelegate.swift
//  SDCrew
//
//  Window-scene lifecycle delegate. The iOS 27 SDK requires apps to adopt the
//  UIScene life cycle, so window creation and URL handling live here instead of
//  in AppDelegate.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window

        // Keep the legacy AppDelegate.window reference valid for code that still reaches
        // for it (for example LoginSwitcher).
        (UIApplication.shared.delegate as? AppDelegate)?.window = window

        LoginSwitcher.updateRootVC()
        window.makeKeyAndVisible()

        // URLs delivered as part of the launch (e.g. an OAuth redirect that cold-starts the app).
        for context in connectionOptions.urlContexts {
            handle(url: context.url)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        for context in URLContexts {
            handle(url: context.url)
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }

    /// Forwards incoming URLs to AppDelegate, which owns the in-flight AppAuth session.
    private func handle(url: URL) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        _ = appDelegate.application(UIApplication.shared, open: url, options: [:])
    }
}
