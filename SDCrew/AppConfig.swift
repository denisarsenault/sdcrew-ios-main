//
//  AppConfig.swift
//  SDCrew
//
//  Created by Denis Arsenault on 8/19/19.
//  Copyright © 2019 Satcom Direct, Inc. All rights reserved.
//

import UIKit

class AppConfig: NSObject {
    
    struct UserdefaultKeys {
        static let LOGGED_IN_STATUS_KEY = "loginStatus"
        static let ACCESS_TOKEN = "access_token_auth"
    }
    
    struct Auth0RequestParams {
        static let IDENTIFIER_URL = "https://identity.satcomdev.com"
        static let CLIENT_ID = "CrewMobileClient"
        static let REDIRECT_URI = "sdcrew://callback"
        static let STATE_KEY = "state"
        static let RESPONSE_TYPE = "code id_token"
        static let SCOPES = ["openid", "profile", "offline_access", "sdportalapi"]
    }

}
