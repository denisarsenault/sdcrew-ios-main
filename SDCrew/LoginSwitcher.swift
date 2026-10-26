//
//  LoginSwitcher.swift
//  SDCrew
//
//  Created by Denis Arsenault on 8/19/19.
//  Copyright © 2019 Satcom Direct, Inc. All rights reserved.
//

import UIKit
import SwiftUI

/// Chooses the window's root view controller from the CloudKit session state.
@MainActor
class LoginSwitcher{

    /// The app's main window. Prefers the window owned by the active window scene and
    /// falls back to the legacy AppDelegate.window reference.
    private static var mainWindow: UIWindow? {
        let sceneWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .sorted { $0.activationState.rawValue < $1.activationState.rawValue }
            .compactMap { ($0.delegate as? SceneDelegate)?.window }
            .first
        return sceneWindow ?? (UIApplication.shared.delegate as? AppDelegate)?.window
    }

    /// Shows the flight leg list when the device's iCloud account is an active app user,
    /// otherwise the access gate (iCloud check, first-admin setup, invite code, blocked states).
    static func updateRootVC(){
        let store = SessionStore.shared
        let rootVC: UIViewController

        if store.isAuthorized {
            let storyBoard = UIStoryboard(name: "FlightLegList", bundle: nil)
            rootVC = storyBoard.instantiateViewController(withIdentifier: "FlightLegListNav")
        } else {
            rootVC = UIHostingController(rootView: AccessGateView(store: store, onAuthorized: handleAuthorized))
        }

        mainWindow?.rootViewController = rootVC
    }

    /// Returns to the access gate. The next sign-in re-checks the device's iCloud account.
    static func signOut() {
        UserDefaults.standard.set(false, forKey: AppConfig.UserdefaultKeys.LOGGED_IN_STATUS_KEY)
        SessionStore.shared.signOut()
        updateRootVC()
    }

    private static func handleAuthorized() {
        UserDefaults.standard.set(true, forKey: AppConfig.UserdefaultKeys.LOGGED_IN_STATUS_KEY)

        // Until flight data moves to CloudKit (Phase 2), demo mode seeds the flight list.
        if SessionManager.shared.demoMode {
            SessionManager.shared.loadDemoDataIntoCoreData {
                updateRootVC()
            }
        } else {
            updateRootVC()
        }
    }

}
