//
//  LoginSwitcher.swift
//  SDCrew
//
//  Created by Denis Arsenault on 8/19/19.
//  Copyright © 2019 Satcom Direct, Inc. All rights reserved.
//

import UIKit

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

    static func updateRootVC(){

        let status = UserDefaults.standard.bool(forKey: AppConfig.UserdefaultKeys.LOGGED_IN_STATUS_KEY)
        let rootVC : UIViewController

        if(status == true){
            let storyBoard = UIStoryboard(name: "FlightLegList", bundle: nil)
            rootVC = storyBoard.instantiateViewController(withIdentifier: "FlightLegListNav")
        }else{
            rootVC = UIStoryboard(name: "Login", bundle: nil).instantiateViewController(withIdentifier: "LoginViewController")
        }

        mainWindow?.rootViewController = rootVC
    }

}
