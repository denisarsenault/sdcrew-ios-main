//
//  FlightDetailsViewController.swift
//  SDCrew
//
//  Created by Denis Arsenault on 8/7/19.
//  Copyright © 2019 Satcom Direct, Inc. All rights reserved.
//

import UIKit
import CoreData

class FlightDetailsViewController: UIViewController,UITableViewDelegate,UITableViewDataSource, ApproachCellDelegate,ApproachTypeCellDelegate,NotesCellDelegate,MeasurementCellDelegate{
    
    var expandedSectionHeaderNumber = 0;
    var tableItems = [["flight",["basic","departure","out/off","on/in"],[67.0,61.0,70.0,70.0]],
                          ["pilots",["basic","pilotInfo","time","track/hold","takeoffs","landings","approaches","approach"],[59.0,67.0,70.0,50.0,110.0,110.0,70.0,80.0]],
                         ["Fuel",["basic","burn","out/in","fuel burn","uplift","planned/actual"],[75.0,100.0,70.0,61.0,100.0,70.0]],
                         ["notes",[""],[73.0]]]
    var pilotItems:[String]!
    var pilotRowsHeights:[Double]!
    var pilots:[Pilot] = [Pilot]()
    var approaches:[[Approach]] = [[Approach]]()
    var fuel:Fuel?
    var note:Note?
    var coreDataManager = CoreDataManager()
    var flight:Flight!
    @IBOutlet weak var detailsTable: UITableView!
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var upperNavView: UIView!
    
    
    @IBOutlet weak var labelTail: UILabel!
    @IBOutlet weak var labelTripId: UILabel!
    @IBOutlet weak var labelDeparture: UILabel!
    @IBOutlet weak var imgViewAirplane: UIImageView!
    @IBOutlet weak var labelDestination: UILabel!
    @IBOutlet weak var labelDepTime: UILabel!
    @IBOutlet weak var labelDestTime: UILabel!
    @IBOutlet weak var imgViewCloud: UIImageView!
    
    @IBOutlet weak var btnLogout: UIButton!
    
    @IBOutlet weak var saveView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        upperNavView.layer.masksToBounds = false
        upperNavView.layer.shadowOffset = CGSize(width: 0, height: 5)
        upperNavView.layer.shadowRadius = 2
        upperNavView.layer.shadowOpacity = 0.2
        
        
        
//        for i in 0..<numberOfPilots{
//            if i == 0{
//                pilots.append(Pilot(name: "Martin", role: "pic", approaches: ["a","b","c"]))
//            }else{
//                pilots.append(Pilot(name: "Jerry", role: "Sic", approaches: ["a","c"]))
//            }
//        }
        fetchNotes()
        fetchFuel()
        fetchPilots()
        generatePilotItems()
        
        //setting values on custom navbar labels
        if let tempTailNum = flight.trailNumber{
            labelTail.text = tempTailNum
        }else{
            labelTail.text = "N/A"
        }
        
        if let tempTripId = flight.tripId{
            labelTripId.text = "Trip ID: \(tempTripId)"
        }else{
            labelTripId.text = "N/A"
        }
        
        if let tempDep = flight.startLoc{
            labelDeparture.text = tempDep
        }else{
            labelDeparture.text = "N/A"
        }
        
        if let tempDepTime = flight.flightStartDate{
            labelDepTime.text = self.getOnlyDate(fromFullDateObj: tempDepTime)
        }else{
            labelDepTime.text = "N/A"
        }
        
        if let tempDest = flight.endLoc{
            labelDestination.text = tempDest
        }else{
            labelDestination.text = "N/A"
        }
        
        if let tempDestTime = flight.flightStopDate{
            labelDestTime.text = self.getOnlyDate(fromFullDateObj: tempDestTime)
        }else{
            labelDestTime.text = "N/A"
        }
        
        if let color = flight.aircraftUIColor {
            imgViewAirplane.setImageColor(color: color)
        }
        let gesture = UITapGestureRecognizer(target: self, action:  #selector(self.savePressed))
        self.saveView.addGestureRecognizer(gesture)
    }
    
    @objc func savePressed(sender : UITapGestureRecognizer) {
        let alertController = UIAlertController(title:nil ,message:nil, preferredStyle: .actionSheet)
        
        let saveOnlyAction = UIAlertAction.init(title: "Save Only", style: .default) { (action) in
            self.coreDataManager.saveObject(type: .Flight, obj: self.flight)
        }
        
        let saveAndLogAction = UIAlertAction.init(title: "Save & Log Flight", style: .default) { (action) in
            self.coreDataManager.saveObject(type: .Flight, obj: self.flight)
            //post api
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(saveOnlyAction)
        alertController.addAction(saveAndLogAction)
        alertController.addAction(cancelAction)
        
        alertController.popoverPresentationController?.sourceView = self.saveView
        alertController.popoverPresentationController?.sourceRect = CGRect(x: self.saveView.bounds.width / 2.0, y: self.saveView.bounds.height / 2.0, width: 1.0, height: 1.0)
        
        self.present(alertController, animated: true, completion: nil)
        
        
    }
    
    @IBAction func btnLogoutPressed(_ sender: UIButton) {
        let alertController = UIAlertController(title:nil ,message:nil, preferredStyle: .actionSheet)
        
        let logoutAction = UIAlertAction.init(title: "Logout", style: .default) { (action) in
//            UserDefaults.standard.set(false, forKey: AppConfig.UserdefaultKeys.LOGGED_IN_STATUS_KEY)
//            LoginSwitcher.updateRootVC()
            var loginObj = LoginViewController()
            loginObj.logoutAuth0()
            self.coreDataManager.deleteEntity(types: [.Flight, .Pilot, .Fuel, .Note])
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(logoutAction)
        alertController.addAction(cancelAction)
        
        alertController.popoverPresentationController?.sourceView = self.btnLogout
        alertController.popoverPresentationController?.sourceRect = CGRect(x: self.btnLogout.bounds.width / 2.0, y: self.btnLogout.bounds.height / 2.0, width: 1.0, height: 1.0)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(note:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(note:)), name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    func fetchFuel() -> Void {
        let predicate = NSPredicate(format:"postedFlightId == %@",flight.postedFlightId ?? "")
        
        let fuels = coreDataManager.fetchData(type: .Fuel, predicate: predicate, descriptor: nil) as? [Fuel] ?? [Fuel]()
        fuel = fuels.first
    }
    func fetchNotes() -> Void {
        let predicate = NSPredicate(format:"postedFlightId == %@",flight.postedFlightId ?? "")
        
        let notes = coreDataManager.fetchData(type: .Note, predicate: predicate, descriptor: nil) as? [Note] ?? [Note]()
        note = notes.first
    }
    func fetchPilots() -> Void {
        var predicate = NSPredicate(format:"postedFlightId == %@",flight.postedFlightId!)
        pilots = (coreDataManager.fetchData(type: .Pilot, predicate: predicate, descriptor: nil) as? [Pilot]) ?? [Pilot]()
        self.approaches.removeAll()
        for pilot in pilots{
            predicate = NSPredicate(format:"flightCrewMemberId == %@",pilot.flightCrewMemberId!)
            let tempApproaches = (coreDataManager.fetchData(type: .Approach, predicate: predicate, descriptor: nil) as? [Approach]) ?? [Approach]()
            self.approaches.append(tempApproaches)
        }
    }
    
    func generatePilotItems() -> Void {
        pilotItems = tableItems[1][1] as? [String]
        pilotRowsHeights = tableItems[1][2] as? [Double]
        var tempPilotItems = [String]()//= pilotItems
        var tempPilotRowsHeights = [Double]()//= pilotRowsHeights
        
        for i in 0..<pilots.count{
            tempPilotItems.insert(pilotItems[0], at: i)
            tempPilotRowsHeights.insert(pilotRowsHeights[0], at: i)
            for j in 1..<pilotItems.count - 1{
                // Basic Rows
                tempPilotItems.insert(pilotItems[j], at: tempPilotItems.count)
                tempPilotRowsHeights.insert(pilotRowsHeights[j], at: tempPilotRowsHeights.count)
            }
            for _ in 0..<approaches[i].count {
                //Number Of Approaches
                tempPilotItems.insert(pilotItems[pilotItems.count - 1], at: tempPilotItems.count)
                tempPilotRowsHeights.insert(pilotRowsHeights[pilotRowsHeights.count - 1], at: tempPilotRowsHeights.count)
            }
            
        }
        pilotItems = tempPilotItems
        pilotRowsHeights = tempPilotRowsHeights
        
    }
    
    var notesExtraHeight = 0.0
    func changeHeightOfNotesCell(extraHeight:Double) -> Bool {
        var notesExtraHeight = 0.0

        var heights = tableItems[3][2] as! [Double]
        var newHeight = heights[0]  + extraHeight
        if newHeight < 73.0{
             return false
        }else if newHeight > 200.0{
            return false
        }
        notesExtraHeight = notesExtraHeight + extraHeight
        heights[0] = newHeight
        tableItems[3][2] = heights
        
        detailsTable.beginUpdates()
        detailsTable.endUpdates()
        
//        let insets = UIEdgeInsets( top: 0, left: 0, bottom: CGFloat( notesExtraHeight + 10 ), right: 0 )
//        self.detailsTable.contentInset = insets
//        self.detailsTable.scrollIndicatorInsets = insets
        detailsTable.scrollToRow(at: IndexPath(row: 0, section: 3), at: .bottom, animated: true)
        return true
    }
    //MARK:- KEYBOARD HIDE/SHOW
    @objc func keyboardWillShow( note:NSNotification ){
        if let newFrame = (note.userInfo?[ UIResponder.keyboardFrameEndUserInfoKey ] as? NSValue)?.cgRectValue {
            if self.detailsTable.contentInset.bottom == 0{
                let insets = UIEdgeInsets( top: 0, left: 0, bottom: newFrame.height + 10, right: 0 )
                UIView.animate(withDuration: 0.2, animations: {
                    self.detailsTable.contentInset = insets
                    self.detailsTable.scrollIndicatorInsets = insets
                }) { (success) in
                    if success{
                        if var cell = self.detailsTable.cellForRow(at: IndexPath(row: 0, section: 3)) as? NotesCell{
                            cell.noteTextField.isScrollEnabled = true
                        }
                    }
                }
                UIView.animate(withDuration: 0.2) {
                    self.detailsTable.contentInset = insets
                    self.detailsTable.scrollIndicatorInsets = insets
                }
            }
            
        }
    }
    @objc func keyboardWillHide( note:NSNotification ){
        let insets = UIEdgeInsets( top: 0, left: 0, bottom: 0, right: 0 )
        if self.detailsTable.contentInset.bottom != 0{
            UIView.animate(withDuration: 0.2) {
                self.detailsTable.contentInset = insets
                self.detailsTable.scrollIndicatorInsets = insets
            }
        }
        
    }
    
    //MARK:- TableView Functions
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let items = tableItems[section][1] as! [String]
        
        if expandedSectionHeaderNumber == section{
            if section == 1 {
                return pilotItems.count
            }
            return items.count
        }else{
            if section == 1 {
                return pilots.count
            }
            return 1
        }
        
        
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var rowHeights = tableItems[indexPath.section][2] as! [Double]
        if indexPath.section == 1{
            rowHeights = pilotRowsHeights
        }
        if rowHeights.count > indexPath.row {
            
            return CGFloat(rowHeights[indexPath.row])
        }
        return  44
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let parentWidth = tableView.bounds.width
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: parentWidth, height: 30))
        let titleLabel = UILabel(frame: CGRect(x: 15, y: 10, width: parentWidth - 35, height: 20))
        if section == 0 {
            titleLabel.text = "OOO1"
        }else if section == 1{
            titleLabel.text = "Pilots"
        } else if section == 2 {
            titleLabel.text = "Fuel"
        }else if section == 3{
            titleLabel.text = "Notes"
        }
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.textColor = #colorLiteral(red: 0.2117647059, green: 0.6392156863, blue: 0.8549019608, alpha: 1)
        headerView.addSubview(titleLabel)
        
        if section != 3 {
            let collapseIcon = UIImageView(frame: CGRect(x: parentWidth - 30, y: 10, width: 15, height: 15))
            if self.expandedSectionHeaderNumber == section{
                collapseIcon.image = #imageLiteral(resourceName: "upArrow")
            }else{
                collapseIcon.image = #imageLiteral(resourceName: "downArrow")
            }
            
            headerView.addSubview(collapseIcon)
            
            collapseIcon.translatesAutoresizingMaskIntoConstraints = false
            let horizontalConstraint = NSLayoutConstraint(item: collapseIcon, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: headerView, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1, constant: -15)
            let verticalConstraint = NSLayoutConstraint(item: collapseIcon, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: headerView, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0)
            let widthConstraint = NSLayoutConstraint(item: collapseIcon, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 15)
            let heightConstraint = NSLayoutConstraint(item: collapseIcon, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 15)
            NSLayoutConstraint.activate([horizontalConstraint, verticalConstraint, widthConstraint, heightConstraint])
            let headerTapGesture = UITapGestureRecognizer(target: self, action: #selector(sectionHeaderTouched(_:)))
            
            headerView.addGestureRecognizer(headerTapGesture)
        }
        
        
        
        
        headerView.backgroundColor = #colorLiteral(red: 0.01960784314, green: 0.1098039216, blue: 0.2666666667, alpha: 1)
        headerView.roundCorners(corners: [.layerMinXMinYCorner,.layerMaxXMinYCorner], radius: 10)
        
        
        
        headerView.tag = section
        return headerView
    }
    
    func getDateTimeRoundValue(hour:Int,min:Int) -> Double {
        
        
        if hour == 0 && min == 0{
            return 0.0
        }
        
        var duration:Int = (hour * 60) + min // in minutes
        let threshold:Int = 3
        let modValue:Int = 6
        
        let remainderOfMinutes = duration % modValue
        duration = duration - threshold
        if(remainderOfMinutes >= threshold){
            duration = duration + modValue
        }
        return Double(duration)/60.000
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let maxRow = tableView.numberOfRows(inSection: indexPath.section)
        var cell:UITableViewCell = UITableViewCell()
        let secName = tableItems[indexPath.section][0] as! String
        var items = tableItems[indexPath.section][1] as! [String]
        if indexPath.section == 1{
            items = pilotItems
        }
        var pilotIndex = 0
        if indexPath.row < pilots.count{
            pilotIndex = indexPath.row
        }else{
            var index = indexPath.row - pilots.count
            for i in 0..<pilots.count{
                index = index - (6 + approaches[i].count)
                if index < 0{
                    pilotIndex = i
                    break
                }
            }
        }
        switch secName {
        case "flight":
            if items[indexPath.row] == "basic" {
                let basicCell = tableView.dequeueReusableCell(withIdentifier: "BasicFlightInfoCell") as! BasicFlightInfoCell
                basicCell.startLoc.text = flight.startLoc
                basicCell.endLoc.text = flight.endLoc
                if let startD = flight.flightStartDate,let stopD = flight.flightStopDate{
                    
                    let difference = Calendar.current.dateComponents([.hour, .minute], from: startD, to: stopD)
                    let formattedString = String(format: "%2ld:%2ld", difference.hour!, difference.minute!)

                    basicCell.flightTimeLbl.text = formattedString + " / " +  String(format: "%.1f", getDateTimeRoundValue(hour: difference.hour!, min: difference.minute!))
                }else{
                    basicCell.flightTimeLbl.text = ""
                }
                if let startD = flight.blockStartDate,let stopD = flight.blockStopDate{
                    let difference = Calendar.current.dateComponents([.hour, .minute], from: startD, to: stopD)
                    let formattedString = String(format: "%2ld:%2ld", difference.hour!, difference.minute!)
                    
                    basicCell.blockTimeLbl.text = formattedString + " / " +  String(format: "%.1f", getDateTimeRoundValue(hour: difference.hour!, min: difference.minute!))
                }else{
                    basicCell.blockTimeLbl.text = ""
                }
                
                cell = basicCell
            }else if items[indexPath.row] == "departure"{
                let singleCell = tableView.dequeueReusableCell(withIdentifier: "SingleInfoCell") as! SingleInfoCell
                singleCell.setTitle( title: "Departure Date", extens: nil)
                
                if let date = flight.flightStartDate{
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy MMM dd"
                    singleCell.infoLabel.text = formatter.string(from: date)
                    
                }
                
                
                cell = singleCell
            }else if items[indexPath.row] == "out/off"{
                let doubleCell = tableView.dequeueReusableCell(withIdentifier: "DoubleInfoCell") as! DoubleInfoCell
                
                doubleCell.setFirstTitle(title: "Out", extens: nil)
                doubleCell.setSecTitle(title: "Off", extens: nil)
                
                let formatter = DateFormatter()
                formatter.dateFormat = "hh:mm"
                
                if let date = flight.blockStartDate{
                    doubleCell.firstInfoTextField.text = formatter.string(from: date)
                    
                }
                
                if let date = flight.flightStartDate{
                    doubleCell.secInfoTextField.text = formatter.string(from: date)
                }
                
                doubleCell.firstNote.isHidden = false
                
                
                if let startD = flight.blockStartDate ,let stopD = flight.flightStartDate{
                    let difference = Calendar.current.dateComponents([.hour, .minute], from: startD, to: stopD)
                    let formattedString = String(format: "%2ld:%2ld", difference.hour!, difference.minute!)
                    
                    doubleCell.firstNote.text =  formattedString + " / " +  String(format: "%.1f", getDateTimeRoundValue(hour: difference.hour!, min: difference.minute!))
                }else{
                    doubleCell.firstNote.text =  ""
                }
                
                
                
                doubleCell.refreshBtn.isHidden = true
                doubleCell.leftRefreshBtn.isHidden = true
                cell = doubleCell
            }else if items[indexPath.row] == "on/in"{
                let doubleCell = tableView.dequeueReusableCell(withIdentifier: "DoubleInfoCell") as! DoubleInfoCell
                doubleCell.setFirstTitle(title: "On", extens: nil)
                doubleCell.setSecTitle(title: "In", extens: nil)
                
                let formatter = DateFormatter()
                formatter.dateFormat = "hh:mm"
                
                if let date = flight.flightStopDate{
                    doubleCell.firstInfoTextField.text = formatter.string(from: date)
                    
                }
                
                if let date = flight.blockStopDate{
                    doubleCell.secInfoTextField.text = formatter.string(from: date)
                }
                
                doubleCell.firstNote.isHidden = false
                
                
                if let startD = flight.flightStopDate ,let stopD = flight.blockStopDate{
                    let difference = Calendar.current.dateComponents([.hour, .minute], from: startD, to: stopD)
                    let formattedString = String(format: "%2ld:%2ld", difference.hour!, difference.minute!)
                    
                    doubleCell.firstNote.text =  formattedString + " / " +  String(format: "%.1f", getDateTimeRoundValue(hour: difference.hour!, min: difference.minute!))
                }else{
                    doubleCell.firstNote.text =  ""
                }
                
                
                
                doubleCell.refreshBtn.isHidden = true
                doubleCell.leftRefreshBtn.isHidden = true
                
                cell = doubleCell
            }
            break
        case "pilots":
            if items[indexPath.row] == "basic"{
                let basicCell = tableView.dequeueReusableCell(withIdentifier: "BasicPilotInfoCell") as! BasicPilotInfoCell
                basicCell.pilotName.text = (pilots[pilotIndex].firstName ?? "") + ", " + (pilots[pilotIndex].lastName ?? "")
                basicCell.pilotRoleLbl.text = pilots[pilotIndex].role
                basicCell.takeOffDayLabel.text = (pilots[pilotIndex].takeOffDay ?? "") + " " + "☼"
                basicCell.takeOffNightLbl.text = (pilots[pilotIndex].takeOffNight ?? "") + " " + "☽"
                basicCell.landingDayLbl.text = (pilots[pilotIndex].landingsDay ?? "") + " " + "☼"
                basicCell.landingNightLbl.text = (pilots[pilotIndex].landingsNight ?? "") + " " + "☽"
                
                cell = basicCell
            }else if items[indexPath.row] == "pilotInfo"{
                let roleCell = tableView.dequeueReusableCell(withIdentifier: "RoleInfoCell") as! RoleInfoCell
                roleCell.nameLbl.text = (pilots[pilotIndex].firstName ?? "") + ", " + (pilots[pilotIndex].lastName ?? "")
                roleCell.sicButton.isSelected = pilots[pilotIndex].role == "SIC" ? true: false
                roleCell.picButton.isSelected = pilots[pilotIndex].role == "PIC" ? true: false
                cell = roleCell
            }else if items[indexPath.row] == "track/hold"{
                let trackCell = tableView.dequeueReusableCell(withIdentifier: "TrackAndHoldCell") as! TrackAndHoldCell
                trackCell.trackSwitch.isOn = pilots[pilotIndex].track
                trackCell.holdSwitch.isOn = pilots[pilotIndex].hold
                cell = trackCell
            }else if items[indexPath.row] == "time"{
                let timeCell = tableView.dequeueReusableCell(withIdentifier: "DoubleInfoCell") as! DoubleInfoCell
                timeCell.setFirstTitle(title: "Inst Time", extens: nil)
                timeCell.setSecTitle(title: "Night Time", extens: nil)
                if pilots[pilotIndex].instTime != ""{
                    timeCell.firstInfoTextField.text = String(format: "%.1f", (Float(pilots[pilotIndex].instTime!)! / Float( 60.0)))
                }else{
                    timeCell.firstInfoTextField.text = ""
                }
                if pilots[pilotIndex].nightTime != ""{
                    timeCell.secInfoTextField.text = String(format: "%.1f", (Float(pilots[pilotIndex].nightTime!)! / Float( 60.0)))
                }else{
                    timeCell.secInfoTextField.text = ""
                }
                timeCell.firstNote.isHidden = true
                timeCell.refreshBtn.isHidden = true
                timeCell.leftRefreshBtn.isHidden = true
                cell = timeCell
            }else if items[indexPath.row] == "takeoffs"{
                let trackCell = tableView.dequeueReusableCell(withIdentifier: "TakeoffsCell") as! TakeoffsCell
                trackCell.setFirstTitle(title: "Day", extens: nil)
                trackCell.setSecTitle(title: "Night", extens: nil)
                
                trackCell.firstValue.text = pilots[pilotIndex].takeOffDay
                trackCell.secValue.text = pilots[pilotIndex].takeOffNight
                
                cell = trackCell
            }else if items[indexPath.row] == "landings"{
                let trackCell = tableView.dequeueReusableCell(withIdentifier: "TakeoffsCell") as! TakeoffsCell
                trackCell.setFirstTitle(title: "Day", extens: nil)
                trackCell.setSecTitle(title: "Night", extens: nil)
                
                trackCell.firstValue.text = pilots[pilotIndex].landingsDay
                trackCell.secValue.text = pilots[pilotIndex].landingsNight
                
                cell = trackCell
            }else if items[indexPath.row] == "approaches" {
                let approachesCell = tableView.dequeueReusableCell(withIdentifier: "ApproachesCell") as! ApproachesCell
                approachesCell.delegate = self
                approachesCell.indexPath = IndexPath(row:indexPath.row , section: pilotIndex)
                cell = approachesCell
            }else if items[indexPath.row] == "approach" {
                let approachTypeCell = tableView.dequeueReusableCell(withIdentifier: "ApproachTypeCell") as! ApproachTypeCell
                approachTypeCell.delegate = self
                approachTypeCell.evsCheckbox.isSelected = false
                approachTypeCell.indexPath = IndexPath(row:indexPath.row , section: pilotIndex)
                cell = approachTypeCell
            }
            break
        case "Fuel":
            if items[indexPath.row] == "basic" {
            
                let fuelSummaryCell = tableView.dequeueReusableCell(withIdentifier: "FuelSummaryCell") as? FuelSummaryCell
                
                var upliftUnit = "lbs"
                var burnUnit = "lbs"
                if fuel?.upliftQuantityTypeId == "1"{
                    upliftUnit = "gal"
                }else if fuel?.upliftQuantityTypeId == "2"{
                    upliftUnit = "ltr"
                }
                if fuel?.quantityTypeId == "1"{
                    burnUnit = "gal"
                }else if fuel?.quantityTypeId == "2"{
                    burnUnit = "ltr"
                }
                
                
                
                fuelSummaryCell?.totalLabel.text = fuel?.fuelBurn != nil && fuel?.fuelBurn != "" ? fuel!.fuelBurn! + " " + burnUnit : ""
                fuelSummaryCell?.plannedLabel.text = fuel?.plannedUp != nil && fuel?.plannedUp != "" ? fuel!.plannedUp! + " " + upliftUnit : ""
                fuelSummaryCell?.actualLabel.text = fuel?.actualUp != nil && fuel?.actualUp != ""  ? fuel!.actualUp! + " " + upliftUnit : ""
                var adjustVal = ""
                if let actual = fuel?.actualUp,actual != "" ,let planned = fuel?.plannedUp, planned != ""{
                    adjustVal = String( Float(actual)! - Float(planned)!)
                }
                
                fuelSummaryCell?.adjustLabel.text = adjustVal
                
                cell = fuelSummaryCell!
            }else if items[indexPath.row] == "burn"{
                let measurementCell = tableView.dequeueReusableCell(withIdentifier: "MeasurementCell") as! MeasurementCell
                measurementCell.titleLabel.text = "Burn"
                if let quantityTypeId = fuel?.quantityTypeId,quantityTypeId != ""{
                    measurementCell.unitSegment.selectedSegmentIndex = Int(quantityTypeId)!
                    
                }else{
                    measurementCell.unitSegment.selectedSegmentIndex = UISegmentedControl.noSegment
                }
                measurementCell.unitSegment.tag = indexPath.row
                measurementCell.delegate = self
                cell = measurementCell
            }else if items[indexPath.row] == "out/in"{
                let outInCell = tableView.dequeueReusableCell(withIdentifier: "DoubleInfoCell") as! DoubleInfoCell
                outInCell.setFirstTitle(title: "Out", extens: "*")
                outInCell.setSecTitle(title: "In", extens: nil)
                outInCell.firstInfoTextField.text = fuel?.fuelOut ?? ""
                outInCell.secInfoTextField.text = fuel?.fuelIn ?? ""
                
                outInCell.firstNote.isHidden = true
                
                cell = outInCell
            }else if items[indexPath.row] == "fuel burn"{
                let singleCell = tableView.dequeueReusableCell(withIdentifier: "SingleInfoCell") as! SingleInfoCell
                
                
                
                
                if let outV = fuel?.fuelOut,outV != "" ,let inV = fuel?.fuelIn, inV != ""{
                    singleCell.infoLabel.text = String( Float(outV)! - Float(inV)!)
                }else{
                    singleCell.infoLabel.text = ""
                }
                
                singleCell.setTitle( title: "Fuel Burn", extens: nil)
                cell = singleCell
            }else if items[indexPath.row] == "uplift"{
                let measurementCell = tableView.dequeueReusableCell(withIdentifier: "MeasurementCell") as! MeasurementCell
                measurementCell.titleLabel.text = "Uplift"
                if let quantityTypeId = fuel?.upliftQuantityTypeId,quantityTypeId != ""{
                    measurementCell.unitSegment.selectedSegmentIndex = Int(quantityTypeId)!
                    
                }else{
                    measurementCell.unitSegment.selectedSegmentIndex = UISegmentedControl.noSegment
                }
                measurementCell.unitSegment.tag = indexPath.row
                measurementCell.delegate = self
                cell = measurementCell
            }else if items[indexPath.row] == "planned/actual"{
                let timeCell = tableView.dequeueReusableCell(withIdentifier: "DoubleInfoCell") as! DoubleInfoCell
                timeCell.setFirstTitle(title: "Planned", extens: nil)
                timeCell.setSecTitle(title: "Actual", extens: nil)
                
                if let planned = fuel?.plannedUp{
                    timeCell.firstInfoTextField.text = planned
                }else{
                    timeCell.firstInfoTextField.text = ""
                }
                
                if let actual = fuel?.actualUp{
                    timeCell.secInfoTextField.text = actual
                }else{
                    timeCell.secInfoTextField.text = ""
                }
                

                timeCell.secNote.isHidden = false
                timeCell.firstNote.isHidden = true
                
                var adjustVal = ""
                if let actual = fuel?.actualUp,actual != "" ,let planned = fuel?.plannedUp, planned != ""{
                    adjustVal = String( Float(actual)! - Float(planned)!)
                }
                
                
                
                timeCell.secNote.text = "Adjust: " + adjustVal
                cell = timeCell
            }
            break
        case "notes":
            let notesCell = tableView.dequeueReusableCell(withIdentifier: "NotesCell") as! NotesCell
            notesCell.noteTextField.text = note?.legNotes
            notesCell.delegate = self
            cell = notesCell
            break
        default:
            break
        }
        if indexPath.row == maxRow - 1{
            cell.roundCorners(corners: [.layerMinXMaxYCorner,.layerMaxXMaxYCorner], radius: 10)
        }else{
            cell.roundCorners(corners: [.layerMinXMaxYCorner,.layerMaxXMaxYCorner], radius: 0)
        }
        
        return cell
        
    }
    
    func tableViewCollapeSection(_ section: Int) {
        let sectionData = tableItems[section][1] as! [String]
        

        self.expandedSectionHeaderNumber = -1;
        if (sectionData.count == 0) {
            return;
        } else {

            self.detailsTable.reloadSections([section], with: .fade)
        }
    }

    func tableViewExpandSection(_ section: Int) {
        let sectionData = tableItems[section][1] as! [String]


        if (sectionData.count == 0) {
            self.expandedSectionHeaderNumber = -1;
            return;
        } else {
            self.expandedSectionHeaderNumber = section
            self.detailsTable.reloadSections([section], with: .fade)

        }
    }
    
    @objc func sectionHeaderTouched(_ sender:UITapGestureRecognizer) -> Void {
        let headerView = sender.view
        let section = headerView!.tag
        
        if (self.expandedSectionHeaderNumber == -1) {
            self.expandedSectionHeaderNumber = section
            
            tableViewExpandSection(section)
        } else {
            if (self.expandedSectionHeaderNumber == section) {
                
                tableViewCollapeSection(section)
            } else {
                tableViewCollapeSection(self.expandedSectionHeaderNumber)
                
                tableViewExpandSection(section)
            }
        }
    }
    
    
//    func unitConversion(fromUnit:String?,toUnit:String?,value:String?) -> String? {
//        guard value != nil,var changedValue = Float( value! ) else {return value}
//        if fromUnit != nil,let from = Int(fromUnit!),toUnit != nil,let to = Int(toUnit!){
//            if from == 1{
//                changedValue = changedValue / 0.45
//            }else if from == 2 {
//                changedValue = changedValue / 0.11976
//            }
//            if to == 1 {
//                changedValue = changedValue * 0.45
//            }else if to == 2{
//                changedValue = changedValue * 0.11976
//            }
//        }else {return value}
//
//        return String(changedValue)
//    }
    
    //MARK:- DELEGATE METHOD
    
    func unitSegmentPressed(sender:UISegmentedControl,prevUnit:Int) -> Void{
        
        if sender.tag == 1{
            self.fuel?.quantityTypeId = String( sender.selectedSegmentIndex)
        }else if sender.tag == 4{
            self.fuel?.upliftQuantityTypeId = String( sender.selectedSegmentIndex)
        }
        self.coreDataManager.saveObject(type: .Fuel, obj: fuel!)
        
        DispatchQueue.main.async {
            
            self.detailsTable.reloadRows(at: [IndexPath(row: 0, section: 2)], with: .none)
            //self.detailsTable.cell
        }
    }
    
    func removeApproachButtonTapped(indexPath: IndexPath) {
        
        var approachRowNumber = indexPath.row - ((indexPath.section * 6) + 6) - pilots.count
        if (indexPath.section > 0) {
            for i in 0..<indexPath.section {
                approachRowNumber -= approaches[i].count
            }
        }
        
        DispatchQueue.main.async {
            let rowCount = self.detailsTable.numberOfRows(inSection: 1)
            var prevCell:UITableViewCell?
            if indexPath.row == rowCount - 1{
                prevCell = self.detailsTable.cellForRow(at: IndexPath(row: rowCount - 2, section: 1))
            }

            for i in  (indexPath.row + 1)..<rowCount {
                if let cell = self.detailsTable.cellForRow(at:IndexPath(row: i, section: 1)){
                    switch self.pilotItems[i] {
                    case "approaches" :
                        let tempCell = cell as! ApproachesCell
                        tempCell.indexPath = IndexPath(row: tempCell.indexPath.row - 1, section: tempCell.indexPath.section)
                        break
                    case "approach" :
                        let tempCell = cell as! ApproachTypeCell
                        tempCell.indexPath = IndexPath(row: tempCell.indexPath.row - 1, section: tempCell.indexPath.section)
                        break
                    default:
                        break
                    }
                }else{
                    break
                }
            }
            
            self.approaches[indexPath.section].remove(at: approachRowNumber)
            self.generatePilotItems()
            
            self.detailsTable.beginUpdates()
            self.detailsTable.deleteRows(at: [IndexPath(row: indexPath.row, section: 1)], with: .fade)
            self.detailsTable.endUpdates()

            prevCell?.roundCorners(corners: [.layerMinXMaxYCorner,.layerMaxXMaxYCorner], radius: 10)
            
        }
    }
    
    
    func addApproachButtonTapped(indexPath: IndexPath) {
        
        approaches[indexPath.section].append(Approach())
        generatePilotItems()
        let rowNumber = indexPath.row + approaches[indexPath.section].count
        DispatchQueue.main.async {
            
            let lastIndex = self.detailsTable.numberOfRows(inSection: 1)
            let prevCell = self.detailsTable.cellForRow(at: IndexPath(row: lastIndex - 1, section: 1))
            
            self.detailsTable.beginUpdates()
            self.detailsTable.insertRows(at: [IndexPath(row: rowNumber, section: 1)], with: .bottom)
            self.detailsTable.endUpdates()
            
            prevCell?.roundCorners(corners: [.layerMinXMaxYCorner,.layerMaxXMaxYCorner], radius: 0)
            
        }
    }
    
    func getOnlyDate(fromFullDateObj:Date) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM yyyy"
        let dateOnly = dateFormatter.string(from: fromFullDateObj)
        return dateOnly
    }

}

