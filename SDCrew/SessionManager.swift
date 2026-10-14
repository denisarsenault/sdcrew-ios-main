//
//  SessionManager.swift
//  SDCrew
//
//  Created by Denis Arsenault  on 8/18/19.
//  Copyright © 2019 Satcom Direct, Inc. All rights reserved.
//

import UIKit
import SwiftyJSON

class SessionManager: NSObject, URLSessionDelegate {
    
    struct Token {
        let userName:String!
        let password:String!
    }
    
    enum ApiResult {
        case Successful
        case Failed
    }
    enum ApiType {
        case flightList
        case trailNumber
    }
//    var demoMode = false
    var demoMode = true
    var accessToken:Token?
    
    static let shared = SessionManager()
    
    override private init() {
        super.init()
        //getToken(completion: {_ in })
    }
    private func getPostString(params:[String:Any]) -> String
    {
        var data = [String]()
        for(key, value) in params
        {
            data.append(key + "=\(value)")
        }
        return data.map { String($0) }.joined(separator: "&")
    }
    
    
    
    
    private func getToken(completion:@escaping ((_ result:ApiResult)->Void) ) -> Void{
        
//        guard let url = URL(string: "\(gateway)/api/iop/remote/get_token") else{return}
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//
//        let bodyDict:[String:String] = ["username":"root","password":"next"]
//
//        request.httpBody = getPostString(params: bodyDict).data(using: .utf8)
//
//
//        let loginString = String(format: "%@:%@", "", "")
//        let loginData = loginString.data(using: String.Encoding.utf8)!
//        let base64LoginString = loginData.base64EncodedString()
//        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
//
//        let session = URLSession(configuration: .default, delegate: self,delegateQueue: .main)
//
//        session.dataTask(with: request, completionHandler: {(data,response,error)in
//            if error != nil {completion(.Failed)}
//            let urlResponse = response as? HTTPURLResponse
//            let statusCode = urlResponse?.statusCode
//            if statusCode == 200, let jsonData = data{
//                do{
//                    let json = try JSONSerialization.jsonObject(with: jsonData, options: [])
//                    guard let tokenDict = json as? [String: String] else {
//                        completion(.Failed)
//                        return
//                    }
//                    let name = tokenDict["key"]
//                    let secret = tokenDict["secret"]
//                    self.accessToken = Token(userName: name, password: secret)
//                    completion(.Successful)
//                }catch{
//                    completion(.Failed)
//                    print("Could not convert json data into Dictionary")
//                }
//            }else{
//                completion(.Failed)
//            }
//        }).resume()
        
    }
    
    private func reAuthenticate(type:ApiType,completion:@escaping apiCompletion) -> Void {
        self.getToken(completion: {result in
            switch result{
            case .Successful:
                self.hitApi(type: type, info: nil, completion: completion)
                break
            case .Failed:
                completion(.Failed,"Failed to get token",nil)
                break
            }
        })
    }
    
    typealias CompletionHandler = (_ sussess:Bool, _ error:Error?, _ responseValue:Any?) -> Void
    
    func performUrlDataTask(withUrlString:String, httpMethod:String, headers:[String:String], body:[String:Any]?, timeoutInterval:Double, completionHandler:@escaping CompletionHandler) -> Void {
        
        var url:URL!
        guard let tempUrl = URL(string: withUrlString) else{
            let errorObj = NSError(domain:withUrlString, code:1001, userInfo:[ NSLocalizedDescriptionKey: "Failed to generate Url"]) as Error
            completionHandler(false,errorObj,nil)
            return
        }
        url = tempUrl
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.timeoutInterval = timeoutInterval
        
        for (key, value) in headers {
            print("(\(key): ,\(value))")
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let tempBody = body {
            
            guard let httpBody = try? JSONSerialization.data(withJSONObject: tempBody, options: []) else {
                let errorObj = NSError(domain:withUrlString, code:1002, userInfo:[ NSLocalizedDescriptionKey: "Failed to json serialisation"]) as Error
                completionHandler(false,errorObj,nil)
                return
            }
            request.httpBody = httpBody
        }
        
        let session = URLSession(configuration: .default, delegate: self,delegateQueue: .main)
        session.dataTask(with: request, completionHandler: {(data,response,error)in
            if error != nil {
                completionHandler(false,error,nil)
                return
            }
            let urlResponse = response as? HTTPURLResponse
            let statusCode = urlResponse?.statusCode
            if statusCode == 200{
                if(httpMethod == "GET"){
                    guard let jsonData = data else{
                        let errorObj = NSError(domain:withUrlString, code:1003, userInfo:[ NSLocalizedDescriptionKey: "No data is found"]) as Error
                        completionHandler(true,errorObj,nil)
                        return
                    }
                    
                    guard let tempJsonData = try? JSON(data: jsonData) else {
                        let errorObj = NSError(domain:withUrlString, code:1004, userInfo:[ NSLocalizedDescriptionKey: "Failed to parse json"]) as Error
                        completionHandler(true,errorObj,nil)
                        return
                    }
                    completionHandler(true,nil,tempJsonData)
                }else{
                    completionHandler(true,nil,["statusCode":statusCode as Any])
                }
            }else if statusCode == 401{
                // to do
                UserDefaults.standard.set(false, forKey: AppConfig.UserdefaultKeys.LOGGED_IN_STATUS_KEY)
                LoginSwitcher.updateRootVC()
                
                let errorObj = NSError(domain:withUrlString, code:401, userInfo:[ NSLocalizedDescriptionKey: "Unauthorized error"]) as Error
                completionHandler(true,errorObj,nil)
            }else{
                let errorObj = NSError(domain:withUrlString, code:statusCode!, userInfo:[ NSLocalizedDescriptionKey: "\(statusCode ?? 0) error"]) as Error
                completionHandler(false,errorObj,nil)
            }
        }).resume()
    }
    
    typealias apiCompletion = (_ result:ApiResult,_ msg:String?,_ dataDict:JSON?)->Void
    
    private func hitApi(type:ApiType,info:[String:String]?, completion: @escaping apiCompletion) -> Void {
        
        if demoMode == true {
            returnDemoData(type: type, info: info, completion: completion)
            return
        }
        
//        guard let token = self.accessToken else {
//            reAuthenticate(type: type, completion: completion)
//            return
//        }
        
        var url:URL!
        
        switch type {
        case .flightList:
            guard let tempUrl = URL(string: "https://sd-postflight-api.pub.sddev.local/api/MobileFlightList/List") else{
                completion(.Failed,"Failed to generate Url",nil)
                return
            }
            url = tempUrl
            break
        case .trailNumber:
            break
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        guard let tokenKey = UserDefaults.standard.value(forKey: AppConfig.UserdefaultKeys.ACCESS_TOKEN) as? String else {return} // AppConfig.UserdefaultKeys.ACCESS_TOKEN
        
        request.setValue("Bearer \(tokenKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60
        
        let session = URLSession(configuration: .default, delegate: self,delegateQueue: .main)
        session.dataTask(with: request, completionHandler: {(data,response,error)in
            if error != nil {
                completion(.Failed,error?.localizedDescription,nil)
                return
            }
            let urlResponse = response as? HTTPURLResponse
            let statusCode = urlResponse?.statusCode
            if statusCode == 200{
                do{
                    guard let jsonData = data else{
                        completion(.Failed,"No data is found in API response",nil)
                        return
                    }
                    let json = try JSON(data: jsonData)
                    
                    completion(.Successful,error?.localizedDescription,json)
                    
                }catch{
                    print("Could not convert json data into Dictionary")
                    completion(.Failed,"Failed to parse json",nil)
                }
            }else if statusCode == 401{
                self.reAuthenticate(type: type, completion: completion)
            }
        }).resume()
    }
    
    func getFlightList(completion:@escaping apiCompletion) -> Void{
        
        self.hitApi(type: .flightList, info: nil, completion: completion)
    }
    
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let serverTrust = challenge.protectionSpace.serverTrust {
            completionHandler(URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust: serverTrust))
        }
    }
    
    //MARK: DEMO
    
    func returnDemoData(type:ApiType,info:[String:String]?,completion:@escaping apiCompletion) -> Void {
        
        guard let url = Bundle.main.url(forResource: "DemoData", withExtension: "json") else{return}
        var json:JSON!
        do{
            let data = try Data(contentsOf: url)
           
            json = try JSON(data: data)
            
            
            
        }catch{
            print("Could not convert json data into Dictionary")
            completion(.Failed,"Failed to parse json",nil)
        }
        
        switch type {
        case .flightList:
            let flightJson = json?["flightList"]
            completion(.Successful,nil,flightJson)
            break
        default:
            let flightJson = json?["trailNumber"]
            completion(.Successful,nil,flightJson)
            break
        }
        
    }
}
