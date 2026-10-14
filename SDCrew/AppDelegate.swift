//
//  AppDelegate.swift
//  SDCrew
//
//  Created by Denis Arsenault on 8/7/19.
//  Copyright © 2019 Satcom Direct, Inc. All rights reserved.
//

import UIKit
import OAuthSwift
import CoreData
import AppAuth
import SwiftyJSON
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var currentAuthorizationFlow: OIDExternalUserAgentSession?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        // AppCenter 5.x dropped the "MS" prefix from its Swift API.
        AppCenter.start(withAppSecret: "883f6de7-c197-4cc9-b72f-35ef4356714f", services: [
            Analytics.self,
            Crashes.self
        ])
        let coreDataManager = CoreDataManager()
        // The window and root view controller are now set up in SceneDelegate.

        
//        SessionManager.shared.getFlightList { (apiResult, msg, dict) in
//
//            switch apiResult{
//            case .Successful:
//                if dict != nil{
//                    coreDataManager.deleteEntity(types: [.Flight,.Fuel,.Pilot])
//                    //var array = coreDataManager.fetchData(type: .Flight, predicate: nil)
//                    coreDataManager.insertData(types: [.Flight,.Fuel,.Pilot], jasonData: dict!)
//                    SessionManager.shared.returnDemoData(type: .trailNumber, info: nil, completion: { (result, msg, data) in
//                        coreDataManager.insertTrailId(aircrafts:data!)
//                    })
//                    //                    var headersDict : [String:String] = [String:String]();
//                    //                    headersDict["Authorization"] = "Bearer \(UserDefaults.standard.value(forKey: AppConfig.UserdefaultKeys.ACCESS_TOKEN) as! String)" //"Bearer
//                    //                    let tailnumurlString = "https://sd-postflight-api.pub.sddev.local/api/AircraftProfile/AircraftProfileDtos"
//                    //                    SessionManager.shared.performUrlDataTask(withUrlString: tailnumurlString, httpMethod: "GET", headers: headersDict, body: nil, timeoutInterval: 60) { (success, error, responseDict) in
//                    //                        if(success){
//                    //                            if let responseError = error{
//                    //                                print(responseError.localizedDescription)
//                    //                            }else{
//                    //
//                    //                                let aircrafts = responseDict as! Array<[String:Any]>
//                    //                                coreDataManager.insertTrailId(aircrafts: aircrafts)
//                    //                            }
//                    //                        }else{
//                    //                            print(error!.localizedDescription)
//                    //                        }
//                    //                    }
//
//                    //array = coreDataManager.fetchData(type: .Flight, predicate: nil)
//
//                }
//                break
//            case .Failed:
//                break
//
//            }
//
//        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        saveContext()

    }

    // MARK: - UIScene life cycle

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }

//    func application(_ app: UIApplication,
//                     open url: URL,
//                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
//
//        OAuthSwift.handle(url: url)
//        return true
//    }
    internal func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        if let authorizationFlow = self.currentAuthorizationFlow, authorizationFlow.resumeExternalUserAgentFlow(with: url) {
            self.currentAuthorizationFlow = nil
            return true
        }
        
        return false
    }
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "CoreSDCrew")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

        


}

