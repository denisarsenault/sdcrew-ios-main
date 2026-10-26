//
//  FlightLegListViewController.swift
//  SDCrew
//
//  Created by Denis Arsenault  on 8/18/19.
//  Copyright © 2019 Satcom Direct, Inc. All rights reserved.
//

import UIKit
import SwiftUI
import SwiftyJSON

class FlightLegListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
   
    @IBOutlet weak var flightTable: UITableView!
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var navBar: UIView!
    @IBOutlet weak var cloudStatusImageView: UIImageView!
    var customSegment:BMSegmentedControl?
    let coreDataManager = CoreDataManager()
    @IBOutlet weak var flightLegTableView: UITableView!
    
    var loggedFlights:[Flight] = [Flight]()
    var notLoggedFlights:[Flight] = [Flight]()
    
    let messageFrame = UIView()
    var activityIndicator = UIActivityIndicatorView()
    var strLabel = UILabel()
    let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    
    @IBOutlet weak var getLatestView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        navBar.layer.masksToBounds = false
        navBar.layer.shadowOffset = CGSize(width: 0, height: 5)
        navBar.layer.shadowRadius = 2
        navBar.layer.shadowOpacity = 0.2
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: flightLegTableView.frame.width, height: 10))
        headerView.backgroundColor = .clear
        flightLegTableView.tableHeaderView = headerView
        
        let segmentFrame = CGRect(x: 20, y: navBar.frame.height - 50, width: self.view.frame.width - 40, height: 54)
        customSegment = BMSegmentedControl(withIcon: segmentFrame, items: ["NOT LOGGED","LOGGED"], icons: [UIImage(named: "notLoggedCircle")!,UIImage(named: "loggedTick")!], selectedIcons: [UIImage(named: "notLoggedCircle")!,UIImage(named: "loggedTick")!], backgroundColor: UIColor.clear, thumbColor: UIColor.cyan, textColor: UIColor.white, selectedTextColor: UIColor.white, orientation: ComponentOrientation.leftRight)
        navBar.addSubview(customSegment!)
        customSegment?.addTarget(self, action: #selector(segmentChanged) , for: .valueChanged)
        self.updateFlights()
        

        
        
        var headersDict : [String:String] = [String:String]();
        if let tempToken = UserDefaults.standard.value(forKey: AppConfig.UserdefaultKeys.ACCESS_TOKEN){
            headersDict["Authorization"] = "Bearer \(tempToken as! String)"
        }
        //"Bearer \(UserDefaults.standard.value(forKey: AppConfig.UserdefaultKeys.ACCESS_TOKEN))"
        
        
        /*var bodyDict : [String:Any] = [String:Any]();
         bodyDict = [
         "postedFlightId": 17011,
         "rejectedTakeoffs": 0,
         "legNotes": "Logged from iPhone 777",
         "departmentId": 234,
         "businessCategoryId": 240
         ]*/
        
        // fetch leglist from server
//        let legListurlString = "https://sd-postflight-api.pub.sddev.local/api/MobileFlightList/List"
//        SessionManager.shared.performUrlDataTask(withUrlString: legListurlString, httpMethod: "GET", headers: headersDict, body: nil, timeoutInterval: 60) { (success, error, responseDict) in
//            if(success){
//                if let responseError = error{
//                    print(responseError.localizedDescription)
//                }else{
//                    print(responseDict)
//                }
//            }else{
//                print(error!.localizedDescription)
//            }
//        }
        
        // fetch approach types from server
//        let apprtypeurlString = "https://sd-postflight-api.pub.sddev.local/api/Reference/approachType"
//        SessionManager.shared.performUrlDataTask(withUrlString: apprtypeurlString, httpMethod: "GET", headers: headersDict, body: nil, timeoutInterval: 60) { (success, error, responseDict) in
//            if(success){
//                if let responseError = error{
//                    print(responseError.localizedDescription)
//                }else{
//                    print(responseDict)
//                }
//            }else{
//                print(error!.localizedDescription)
//            }
//        }
        
        // fetch tail numbers from server
//        let tailnumurlString = "https://sd-postflight-api.pub.sddev.local/api/AircraftProfile/AircraftProfileDtos"
//        SessionManager.shared.performUrlDataTask(withUrlString: tailnumurlString, httpMethod: "GET", headers: headersDict, body: nil, timeoutInterval: 60) { (success, error, responseDict) in
//            if(success){
//                if let responseError = error{
//                    print(responseError.localizedDescription)
//                }else{
//                    print(responseDict)
//                }
//            }else{
//                print(error!.localizedDescription)
//            }
//        }
        let gesture = UITapGestureRecognizer(target: self, action:  #selector(self.getLatestPressed))
        self.getLatestView.addGestureRecognizer(gesture)
        
        NotificationCenter.default.addObserver(self, selector: #selector(dataReceived(notification:)), name: Notification.Name(rawValue: "flightDataReceived"), object: nil)
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
        
        self.getLatestView.isUserInteractionEnabled = false
        self.getLatestView.alpha = 0.2
    }
    
    func stopActivityIndicator(){
        activityIndicator.stopAnimating()
        effectView.removeFromSuperview()
        self.getLatestView.isUserInteractionEnabled = true
        self.getLatestView.alpha = 1.0
    }
    
    @objc func getLatestPressed(sender : UITapGestureRecognizer) {
        self.startActivityIndicator("Loading...")

        // Demo mode: the post-flight API is only reachable on the corporate network, so reload
        // from the bundled demo data instead of waiting 60 s for the request to time out.
        if SessionManager.shared.demoMode {
            SessionManager.shared.loadDemoDataIntoCoreData {
                self.stopActivityIndicator()
            }
            return
        }

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
                                self.stopActivityIndicator()
                            }
                        }else{
                            print(error!.localizedDescription)
                            self.stopActivityIndicator()
                        }
                    }
                    
                    print(responseDict)
                    self.stopActivityIndicator()
                }
            }else{
                print(error!.localizedDescription)
                self.stopActivityIndicator()
            }
        }
        
    }
    @objc func dataReceived(notification:Notification) -> Void {
        self.updateFlights()
    }
    override func viewDidLayoutSubviews() {
        customSegment?.frame = CGRect(x: 20, y: navBar.frame.height - 50, width: self.view.frame.width - 40, height: 54)
        customSegment?.layoutSubviews()
    }
    
    @objc func segmentChanged(){
        self.flightLegTableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func updateFlights() -> Void {
        var predicate = NSPredicate(format:"isLogged == YES")
        let sort = NSSortDescriptor(key: #keyPath(Flight.flightStartDate), ascending: true)
        loggedFlights = (coreDataManager.fetchData(type: .Flight, predicate: predicate, descriptor: sort) as? [Flight]) ?? [Flight]()
        
        predicate = NSPredicate(format:"isLogged == NO")
        notLoggedFlights = (coreDataManager.fetchData(type: .Flight, predicate: predicate, descriptor: sort) as? [Flight]) ?? [Flight]()
        self.flightTable.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if customSegment?.selectedIndex == 0{
            return notLoggedFlights.count
        }
        else{
            return loggedFlights.count
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FlightsTableViewCell") as! FlightsTableViewCell
        var flight:Flight!
        if customSegment?.selectedIndex == 0{
            flight = notLoggedFlights[indexPath.section]
        }else{
            flight = loggedFlights[indexPath.section]
        }
        
        cell.tripIdLbl.text = flight.tripId
        cell.flightSourceLbl.text = flight.startLoc
        cell.flightDestinationLbl.text = flight.endLoc
        if let color = flight.aircraftUIColor {
            cell.aircraftImg.setImageColor(color: color)
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MMM-yyyy"
        if let date = flight.flightStartDate{
          cell.takeOffDateLbl.text = formatter.string(from:date)
        }else{
            cell.takeOffDateLbl.text = ""
        }
        if let date = flight.flightStopDate{
            cell.landingDateLbl.text = formatter.string(from:date)
        }else{
            cell.landingDateLbl.text = ""
        }
        cell.flightNameLbl.text = flight.trailNumber

        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        return headerView
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "FlightDetails", bundle: nil)
        let flightDetails:FlightDetailsViewController = storyboard.instantiateViewController(withIdentifier: "FlightDetailsViewController") as! FlightDetailsViewController
        if customSegment?.selectedIndex == 0{
            flightDetails.flight = notLoggedFlights[indexPath.section]
        }else{
            flightDetails.flight = loggedFlights[indexPath.section]
        }
        
        self.navigationController?.pushViewController(flightDetails, animated: true)
    }
    @IBAction func logoutButtonPressed(_ sender: UIButton) {
        let session = SessionStore.shared
        let alertController = UIAlertController(title: session.currentUser?.fullName,
                                                message: session.currentUser?.role.displayName,
                                                preferredStyle: .actionSheet)

        if session.isAdmin {
            alertController.addAction(UIAlertAction(title: "Manage Users", style: .default) { _ in
                self.presentUserAdministration()
            })
        }

        let logoutAction = UIAlertAction(title: "Sign Out", style: .destructive) { _ in
            self.coreDataManager.deleteEntity(types: [.Flight, .Pilot, .Fuel, .Note])
            LoginSwitcher.signOut()
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alertController.addAction(logoutAction)
        alertController.addAction(cancelAction)
        
        alertController.popoverPresentationController?.sourceView = self.logoutButton
        alertController.popoverPresentationController?.sourceRect = CGRect(x: self.logoutButton.bounds.width / 2.0, y: self.logoutButton.bounds.height / 2.0, width: 1.0, height: 1.0)
        
        self.present(alertController, animated: true, completion: nil)

    }

    /// Presents the SwiftUI user administration screens modally. Modal presentation is used
    /// because this screen hides the navigation bar, which a pushed controller would inherit.
    private func presentUserAdministration() {
        let admin = UIHostingController(rootView: UserAdminView(store: SessionStore.shared))
        admin.modalPresentationStyle = .formSheet
        present(admin, animated: true)
    }

}


extension UIImageView {
    func setImageColor(color: UIColor) {
        let templateImage = self.image?.withRenderingMode(.alwaysTemplate)
        self.image = templateImage
        self.tintColor = color
    }
}

