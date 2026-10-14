//
//  LoginViewController.swift
//  SDCrew
//
//  Created by Denis Arsenault on 8/19/19.
//  Copyright © 2019 Satcom Direct, Inc. All rights reserved.
//

import UIKit
//import OAuthSwift
import AppAuth
import CoreData
import SwiftyJSON

typealias PostRegistrationCallback = (_ configuration: OIDServiceConfiguration?, _ registrationResponse: OIDRegistrationResponse?) -> Void

class LoginViewController: UIViewController, OIDAuthStateChangeDelegate, OIDAuthStateErrorDelegate {
    
    @IBOutlet weak var btnLogin: UIButton!
    @IBOutlet weak var labelVersion: UILabel!
    @IBOutlet weak var labelEnv: UILabel!
    
    let imagePicker = UIImagePickerController()
    let messageFrame = UIView()
    var activityIndicator = UIActivityIndicatorView()
    var strLabel = UILabel()
    let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    
    private var authState: OIDAuthState?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btnLogin.layer.cornerRadius = 4
    }
    
    func startActivityIndicator(_ title: String) {
        strLabel.removeFromSuperview()
        activityIndicator.removeFromSuperview()
        effectView.removeFromSuperview()
        
        strLabel = UILabel(frame: CGRect(x: 50, y: 0, width: 160, height: 46))
        strLabel.text = title
        strLabel.font = .systemFont(ofSize: 14, weight: .medium)
        strLabel.textColor = UIColor(white: 0.9, alpha: 0.7)
        
        effectView.frame = CGRect(x: view.frame.midX - strLabel.frame.width/2, y: view.frame.midY - strLabel.frame.height/2 , width: 160, height: 46)
        effectView.layer.cornerRadius = 15
        effectView.layer.masksToBounds = true
        
        activityIndicator = UIActivityIndicatorView(style: .white)
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 46, height: 46)
        activityIndicator.startAnimating()
        
        effectView.contentView.addSubview(activityIndicator)
        effectView.contentView.addSubview(strLabel)
        view.addSubview(effectView)
        
        self.btnLogin.isUserInteractionEnabled = false
        self.btnLogin.alpha = 0.2
    }
    
    func stopActivityIndicator(){
        activityIndicator.stopAnimating()
        effectView.removeFromSuperview()
        self.btnLogin.isUserInteractionEnabled = true
        self.btnLogin.alpha = 1.0
    }
    
    @IBAction func btnLoginPressed(_ sender: UIButton) {
        self.startActivityIndicator("Please wait")
        guard let issuer = URL(string: AppConfig.Auth0RequestParams.IDENTIFIER_URL) else {
            self.showAlertViewController(titleText: "Url Error", messageText: "Error creating URL for : \(AppConfig.Auth0RequestParams.IDENTIFIER_URL)", leftSideText: "Dismiss", rightSideText: "")
            return
        }
        
        print("Fetching configuration for issuer: \(issuer)")
        
        // discovers endpoints
        OIDAuthorizationService.discoverConfiguration(forIssuer: issuer) { configuration, error in
            
            guard let config = configuration else {
                self.showAlertViewController(titleText: "Auth0 Error", messageText: "Error retrieving discovery document: \(error?.localizedDescription ?? "DEFAULT_ERROR")", leftSideText: "Dismiss", rightSideText: "")
                self.setAuthState(nil)
                self.stopActivityIndicator()
                return
            }
            
            print("Got configuration: \(config)")
            
            //if let clientId = AppConfig.Auth0RequestParams.CLIENT_ID {
            self.doAuthWithAutoCodeExchange(configuration: config, clientID: AppConfig.Auth0RequestParams.CLIENT_ID, clientSecret: nil)
            /*} else {
             self.doClientRegistration(configuration: config) { configuration, response in
             
             guard let configuration = configuration, let clientID = response?.clientID else {
             self.logMessage("Error retrieving configuration OR clientID")
             return
             }
             
             self.doAuthWithAutoCodeExchange(configuration: configuration,
             clientID: clientID,
             clientSecret: response?.clientSecret)
             }
             }*/
        }
    }
    
    func doAuthWithAutoCodeExchange(configuration: OIDServiceConfiguration, clientID: String, clientSecret: String?) {
        UserDefaults.standard.set(nil, forKey: AppConfig.UserdefaultKeys.ACCESS_TOKEN)
        guard let redirectURI = URL(string: AppConfig.Auth0RequestParams.REDIRECT_URI) else {
            print("Error creating URL for : \(AppConfig.Auth0RequestParams.REDIRECT_URI)")
            return
        }
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("Error accessing AppDelegate")
            return
        }
        
        // builds authentication request
        let request = OIDAuthorizationRequest(configuration: configuration,
                                              clientId: clientID,
                                              //   clientSecret: "",
            scopes: AppConfig.Auth0RequestParams.SCOPES,//[OIDScopeOpenID, OIDScopeProfile, OIDOfflineAccess, OIDSDPortalAPI],
            //scope: "openid profile sdportalapi offline_access",
            redirectURL: redirectURI,
            responseType: AppConfig.Auth0RequestParams.RESPONSE_TYPE,//OIDResponseTypeCode + " " +  OIDResponseTypeIDToken,
            // state: "",
            // nonce: "Hi",
            // codeVerifier:verifier,
            // codeChallenge:OIDAuthorizationRequest.codeChallengeS256(forVerifier: verifier),
            // codeChallengeMethod: OIDOAuthorizationRequestCodeChallengeMethodS256,
            additionalParameters: nil)
        
        // performs authentication request
        print("Initiating authorization request with scope: \(request.scope ?? "DEFAULT_SCOPE")")
        
        
        appDelegate.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, presenting: self) { authState, error in
            
            
            if let authState = authState {
                self.setAuthState(authState)
                print("Got authorization tokens. Access token: \(authState.lastTokenResponse?.accessToken ?? "DEFAULT_TOKEN")")
                guard let tokenExchangeRequest = self.authState?.lastAuthorizationResponse.tokenExchangeRequest() else {
                    print("Error creating authorization code exchange request")
                    return
                }
                
                print("Performing authorization code exchange with request \(tokenExchangeRequest)")
                
                OIDAuthorizationService.perform(tokenExchangeRequest) { response, error in
                    
                    if let tokenResponse = response {
                        print("Received token response with accessToken: \(tokenResponse.accessToken ?? "DEFAULT_TOKEN")")
                        //self.showAlertViewController(titleText: "Success!", messageText: "Got authorization tokens. Access token: \(tokenResponse.accessToken ?? "DEFAULT_TOKEN")", leftSideText: "Ok", rightSideText: "")
                        self.stopActivityIndicator()
                        UserDefaults.standard.set(tokenResponse.accessToken, forKey: AppConfig.UserdefaultKeys.ACCESS_TOKEN)
                        UserDefaults.standard.set(true, forKey: AppConfig.UserdefaultKeys.LOGGED_IN_STATUS_KEY)
                        
                        
                        var headersDict : [String:String] = [String:String]();
                        if let tempToken = UserDefaults.standard.value(forKey: AppConfig.UserdefaultKeys.ACCESS_TOKEN){
                            headersDict["Authorization"] = "Bearer \(tempToken as! String)"
                        }
                        //"Bearer \(UserDefaults.standard.value(forKey: AppConfig.UserdefaultKeys.ACCESS_TOKEN))"
                    
                        let coreDataManager =  CoreDataManager()
                        // fetch leglist from server
                        let legListurlString = "https://sd-postflight-api.pub.sddev.local/api/MobileFlightList/List"
                        SessionManager.shared.performUrlDataTask(withUrlString: legListurlString, httpMethod: "GET", headers: headersDict, body: nil, timeoutInterval: 60) { (success, error, responseDict) in
                            if(success){
                                if let responseError = error{
                                    print(responseError.localizedDescription)
                                }else{
                                    coreDataManager.insertData(types: [.Flight,.Fuel,.Pilot,.Note], jasonData: responseDict! as! JSON)
                                    // fetch tail numbers from server
                                    let tailnumurlString = "https://sd-postflight-api.pub.sddev.local/api/AircraftProfile/AircraftProfileDtos"
                                    SessionManager.shared.performUrlDataTask(withUrlString: tailnumurlString, httpMethod: "GET", headers: headersDict, body: nil, timeoutInterval: 60) { (success, error, responseDict) in
                                        if(success){
                                            if let responseError = error{
                                                print(responseError.localizedDescription)
                                            }else{
                                                print(responseDict)
                                                coreDataManager.insertTrailId(aircrafts:responseDict! as! JSON)
                                                
                                                NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: "flightDataReceived")))
                                            }
                                        }else{
                                            print(error!.localizedDescription)
                                        }
                                    }
                                    
                                    print(responseDict)
                                }
                            }else{
                                print(error!.localizedDescription)
                            }
                        }
                        
                        LoginSwitcher.updateRootVC()
                    } else {
                        print("Token exchange error: \(error?.localizedDescription ?? "DEFAULT_ERROR")")
                        self.stopActivityIndicator()
                        self.showAlertViewController(titleText: "Auth0 error", messageText: "Token exchange error: \(error?.localizedDescription ?? "DEFAULT_ERROR")", leftSideText: "Dismiss", rightSideText: "")
                    }
                    self.stopActivityIndicator()
                    self.authState?.update(with: response, error: error)
                }
            } else {
                self.showAlertViewController(titleText: "Auth0 error", messageText: "Authorization error: \(error?.localizedDescription ?? "DEFAULT_ERROR")", leftSideText: "Dismiss", rightSideText: "")
                print("Authorization error: \(error?.localizedDescription ?? "DEFAULT_ERROR")")
                self.stopActivityIndicator()
                self.setAuthState(nil)
            }
        }
    }
    
    @IBAction func btnTestLoginPressed(_ sender: UIButton) {
        UserDefaults.standard.set(true, forKey: AppConfig.UserdefaultKeys.LOGGED_IN_STATUS_KEY)
        LoginSwitcher.updateRootVC()
    }
    
    //MARK:- Auth0 Funcs
    func loadState() {
        guard let data = UserDefaults.standard.object(forKey: AppConfig.Auth0RequestParams.STATE_KEY) as? Data else {
            return
        }
        
        if let authState = NSKeyedUnarchiver.unarchiveObject(with: data) as? OIDAuthState {
            self.setAuthState(authState)
        }
    }
    
    func setAuthState(_ authState: OIDAuthState?) {
        if logoutPressed{
            /*if (self.authState == authState) {
             return;
             }*/
            guard let issuer = URL(string: AppConfig.Auth0RequestParams.IDENTIFIER_URL) else {
                self.showAlertViewController(titleText: "Url Error", messageText: "Error creating URL for : \(AppConfig.Auth0RequestParams.IDENTIFIER_URL)", leftSideText: "Dismiss", rightSideText: "")
                return
            }
            
            guard let redirectURI = URL(string: AppConfig.Auth0RequestParams.REDIRECT_URI) else {
                print("Error creating URL for : \(AppConfig.Auth0RequestParams.REDIRECT_URI)")
                return
            }
            
            
            /***************/
            
            let endSessionUrl = issuer.appendingPathComponent("connect/endsession")
            
            let config = OIDServiceConfiguration.init(authorizationEndpoint: endSessionUrl, tokenEndpoint: endSessionUrl)
            
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                print("Error accessing AppDelegate")
                return
            }
            
            //guard let idToken =  else {return}
            let additionalParams = [
                "post_logout_redirect_uri":"sdcrew://logout",
                "id_token_hint":UserDefaults.standard.value(forKey: AppConfig.UserdefaultKeys.ACCESS_TOKEN) as! String
            ]
            
            /*OIDAuthorizationRequest(configuration: config,
             clientId: AppConfig.Auth0RequestParams.CLIENT_ID,
             clientSecret: "",
             scope: "openid profile offline_access sdportalapi",
             redirectURL: "sdcrew://callback",
             responseType: AppConfig.Auth0RequestParams.RESPONSE_TYPE,
             state: nil,
             codeVerifier: nil,
             codeChallenge: nil,
             codeChallengeMethod: nil,
             additionalParameters: nil)*/
            
            let request = OIDAuthorizationRequest(configuration: config,
                                                  clientId: AppConfig.Auth0RequestParams.CLIENT_ID,
                                                  clientSecret: "",
                                                  scopes: AppConfig.Auth0RequestParams.SCOPES,
                                                  redirectURL: redirectURI,
                                                  responseType: AppConfig.Auth0RequestParams.RESPONSE_TYPE,
                                                  //state: OIDAuthorizationRequest.generateState(),
                //codeVerifier: OIDAuthorizationRequest.generateCodeVerifier(),
                //codeChallenge: OIDAuthorizationRequest.generateCodeVerifier(),
                //codeChallengeMethod: "plain",
                additionalParameters: additionalParams)
            
            
            appDelegate.currentAuthorizationFlow = OIDAuthorizationService.present(request, presenting: self) { (authState, error) in
                
                //LoginData.sharedInstance.removeState()
                //completionClosure(true,nil)
            }
            
            
            /***************/
            ////////////tried but no luck :(
            /*let endSessionUrl = issuer.appendingPathComponent("connect/endsession")
            
            let config = OIDServiceConfiguration.init(authorizationEndpoint: endSessionUrl, tokenEndpoint: endSessionUrl)
            
            let config2 = OIDServiceConfiguration.init(authorizationEndpoint: endSessionUrl, tokenEndpoint: URL(string: "https://identity.satcomdev./connect/token")!, issuer: issuer, registrationEndpoint: nil, endSessionEndpoint: endSessionUrl)
            
            let request = OIDEndSessionRequest(configuration: config2, idTokenHint: UserDefaults.standard.value(forKey: AppConfig.UserdefaultKeys.ACCESS_TOKEN) as! String, postLogoutRedirectURL: URL(string: "sdcrew://logout")!, additionalParameters: nil)
            /*OIDAuthorizationRequest(configuration: config,
             clientId: AppConfig.Auth0RequestParams.CLIENT_ID,
             clientSecret: "",
             scope: "openid profile offline_access sdportalapi",
             redirectURL: "sdcrew://callback",
             responseType: AppConfig.Auth0RequestParams.RESPONSE_TYPE,
             state: nil,
             codeVerifier: nil,
             codeChallenge: nil,
             codeChallengeMethod: nil,
             additionalParameters: nil)*/
            let agent = OIDExternalUserAgentIOS(presenting: self)!
            let sess = OIDAuthorizationService.presssentEndSessionRequest(request, externalUserAgent: agent) { (res, err) in
                print("logout")
             }
            ////////////tried but no luck :(
            */
            self.authState = authState;
            self.authState?.stateChangeDelegate = self;
            self.saveState()
        }else{
            if (self.authState == authState) {
                return;
            }
            
            self.authState = authState;
            self.authState?.stateChangeDelegate = self;
            self.saveState()
        }
    }
    
    func saveState() {
        
        var data: Data? = nil
        
        if let authState = self.authState {
            data = NSKeyedArchiver.archivedData(withRootObject: authState)
        }
        
        UserDefaults.standard.set(data, forKey: AppConfig.Auth0RequestParams.STATE_KEY)
        UserDefaults.standard.synchronize()
    }
    
    func didChange(_ state: OIDAuthState) {
        self.saveState()
    }
    
    func authState(_ state: OIDAuthState, didEncounterAuthorizationError error: Error) {
        self.showAlertViewController(titleText: "Auth0 Error", messageText: "Received authorization error: \(error)", leftSideText: "Dismiss", rightSideText: "")
        print("Received authorization error: \(error)")
    }
    
    func refreshToken(){
        /*
         var temp = self.authState?.tokenRefreshRequest()
         //authState?.refreshToken = "wdelfhjwdkfhdkswfhj"
         // authState?.lastTokenResponse?.accessToken = "wdelfhjwdkfhdkswfhj"
         OIDAuthorizationService.perform(temp!) { response, error in
         
         if let tokenResponse = response {
         self.logMessage("Received token response with accessToken: \(tokenResponse.accessToken ?? "DEFAULT_TOKEN")")
         } else {
         self.logMessage("Token exchange error: \(error?.localizedDescription ?? "DEFAULT_ERROR")")
         }
         self.authState?.update(with: response, error: error)
         }
         return
         */
    }
    var logoutPressed = false
    func logoutAuth0(){
        logoutPressed = true
        UserDefaults.standard.set(false, forKey: AppConfig.UserdefaultKeys.LOGGED_IN_STATUS_KEY)
        LoginSwitcher.updateRootVC()
        self.setAuthState(nil)
//        UserDefaults.standard.set(false, forKey: AppConfig.UserdefaultKeys.LOGGED_IN_STATUS_KEY)
//        LoginSwitcher.updateRootVC()
    }
    
    func showAlertViewController(titleText:String,messageText:String,leftSideText:String,rightSideText:String){
        let alertController = UIAlertController(title: titleText, message: messageText, preferredStyle: .alert)
        
        let leftAction = UIAlertAction(title: leftSideText, style: .default, handler: nil)
        let rightAction = UIAlertAction(title: rightSideText, style: .default, handler: nil)
        
        if rightSideText == ""{
            alertController.addAction(leftAction)
        }else{
            alertController.addAction(leftAction)
            alertController.addAction(rightAction)
        }
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    
}

extension Bundle {
    static func appName() -> String {
        guard let dictionary = Bundle.main.infoDictionary else {
            return ""
        }
        if let version : String = dictionary["CFBundleName"] as? String {
            return version
        } else {
            return ""
        }
    }
    
    static func appBundleId() -> String {
        guard let dictionary = Bundle.main.infoDictionary else {
            return ""
        }
        if let version : String = dictionary["CFBundleIdentifier"] as? String {
            return version
        } else {
            return ""
        }
    }
}
