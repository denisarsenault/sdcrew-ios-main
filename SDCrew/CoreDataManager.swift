//
//  CoreDataManager.swift
//  SDCrew
//
//  Created by Denis Arsenault on 9/1/19.
//  Copyright © 2019 Satcom Direct. All rights reserved.
//

import UIKit
import CoreData
import SwiftyJSON

extension Flight {
    /// Converts the persisted "r,g,b" aircraft colour string (0-255 components) into a UIColor.
    /// Returns nil when the stored value is missing or malformed.
    var aircraftUIColor: UIColor? {
        guard let colorStr = color else { return nil }
        let rgb = colorStr.components(separatedBy: ",")
        guard rgb.count == 3,
              let r = Float(rgb[0].trimmingCharacters(in: .whitespaces)),
              let g = Float(rgb[1].trimmingCharacters(in: .whitespaces)),
              let b = Float(rgb[2].trimmingCharacters(in: .whitespaces)) else {
            return nil
        }
        return UIColor(displayP3Red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1)
    }
}

class CoreDataManager: NSObject {
    
    enum EntityType {
        case Flight
        case Pilot
        case Fuel
        case Note
        case Approach
    }
    
    let appDelegate:AppDelegate!
    let managedContext:NSManagedObjectContext!

    override init() {
        appDelegate = (UIApplication.shared.delegate as! AppDelegate)
        managedContext = appDelegate.persistentContainer.viewContext
        
    }
    
    func insertTrailId(aircrafts:JSON) -> Void {
        let flights = fetchData(type: .Flight, predicate: nil, descriptor: nil) as! [Flight]
        let dataArray = aircrafts.arrayValue
        for flight:Flight in flights{
            
            if let aircraft = dataArray.first(where: {$0["aircraftProfileId"].stringValue == flight.aircraftProfileId}) {
                flight.trailNumber = aircraft["tailNumber"].stringValue
            }
            
        }
        
        do {
            try managedContext.save()
        } catch let error {
            print("Could not save" + error.localizedDescription)
        }
        
    }
    
    func insertData(types:[EntityType], jasonData:JSON) -> Void {
        
        let resultSet = jasonData["resultSet"].arrayValue
        
//        switch types {
//        case [.Flight]:
//
//            break
//        case [.Fuel]:
//            for result in resultSet{
//                let flightId = result["postedFlightId"].stringValue
//                let predicate = NSPredicate(format:"postedFlightId == %@",flightId)
//                let dataArray = fetchData(type: .Fuel, predicate: predicate)
//            }
//            break
//        case [.Pilot]:
//            break
//        case [.Note]:
//            break
//        default:
//            break
//        }
        
        for result in resultSet{
            let flightId = result["postedFlightId"].stringValue
            let predicate = NSPredicate(format:"postedFlightId == %@",flightId)
            let dataArray = fetchData(type: .Flight, predicate: predicate, descriptor: nil)
            
            
            for i in 0..<types.count{
                if let entity = NSEntityDescription.entity(forEntityName: getEntityName(type: types[i]), in: managedContext){
                    var managedObj:NSManagedObject!
                    
                    
                    
                    if dataArray.count == 0 && types[i] == .Flight {
                        
                        if types[i] == .Flight{
                            
                        }
                        managedObj = NSManagedObject(entity: entity, insertInto: managedContext)
                        
                    }else{
                        switch types[i]{
                            
                        case .Flight:
                            managedObj = dataArray.first as? NSManagedObject
                            break
                        case .Pilot:
                            let crews = result["flightCrewMember"].arrayValue
                            let predicate = NSPredicate(format:"postedFlightId == %@",flightId)
                            let pilotsArray = fetchData(type: .Pilot, predicate: predicate, descriptor: nil)
                            
                            if pilotsArray.count > 0{
                                for j in 0..<pilotsArray.count{
                                    if j < crews.count{
                                         let crew = crews[j]
                                        let managedPilot = pilotsArray[j] as! Pilot
                                        if let flight = dataArray.first as? Flight{
                                            managedPilot.postedFlightId = flight.postedFlightId
                                            modifyManagedObject(type:types[i],managedObj:managedPilot,jason:crew)
                                        }
                                        
                                    }
                                }
                            }else{
                                for j in 0..<crews.count{
                                    let crew = crews[j]
                                    let managedPilot = NSManagedObject(entity: entity, insertInto: managedContext) as! Pilot
                                    if let flight = dataArray.first as? Flight{
                                        managedPilot.postedFlightId = flight.postedFlightId
                                        modifyManagedObject(type:types[i],managedObj:managedPilot,jason:crew)
                                    }
//                                    modifyManagedObject(type:types[i],managedObj:managedObj,jason:crew)
                                }
                            }
                            
                            
                            break
                        case .Fuel:
                            let predicate = NSPredicate(format:"postedFlightId == %@",flightId)
                            let fuelArray = fetchData(type: .Fuel, predicate: predicate, descriptor: nil)
                            if let fuel = fuelArray.first{
                                managedObj = fuel as! NSManagedObject
                            }else{
                                managedObj = NSManagedObject(entity: entity, insertInto: managedContext)
                            }
                            break
                        case .Note:
                            let predicate = NSPredicate(format:"postedFlightId == %@",flightId)
                            let noteArray = fetchData(type: .Note, predicate: predicate, descriptor: nil)
                            if let note = noteArray.first{
                                managedObj = note as! NSManagedObject
                            }else{
                                managedObj = NSManagedObject(entity: entity, insertInto: managedContext)
                            }
                            break
                        case .Approach:
                            break

                        }
                        
                        
                    }
                    if types[i] != .Pilot{
                        modifyManagedObject(type:types[i],managedObj:managedObj,jason:result)
                    }
                    
                }
            }
        }
        
        do {
            try managedContext.save()
        } catch let error {
            print("Could not save" + error.localizedDescription)
        }
    }
    
    func modifyManagedObject(type:EntityType, managedObj:NSManagedObject,jason:JSON) -> Void {
        switch type {
        case .Flight:
            (managedObj as! Flight).postedFlightId = jason["postedFlightId"].stringValue
            (managedObj as! Flight).flightId = jason["flightId"].stringValue
            (managedObj as! Flight).aircraftProfileId = jason["aircraftProfileId"].stringValue
            (managedObj as! Flight).tripId = jason["tripId"].stringValue
            (managedObj as! Flight).startLoc = jason["departureIcao"].stringValue
            (managedObj as! Flight).endLoc = jason["airportIcao"].stringValue
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ssZ"//"yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSS'Z'"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            (managedObj as! Flight).flightStartDate = dateFormatter.date(from: jason["flightStartDateTime"].stringValue)
            (managedObj as! Flight).flightStopDate = dateFormatter.date(from: jason["flightStopDateTime"].stringValue)
            
            (managedObj as! Flight).blockStopDate = dateFormatter.date(from: jason["postedFlightOooi"]["blockStopDateTime"] .stringValue)
            (managedObj as! Flight).blockStartDate = dateFormatter.date(from: jason["postedFlightOooi"]["blockStartDateTime"].stringValue)
            
            // The Core Data attribute is a String, so persist the raw "r,g,b" value from the
            // server and convert it to a UIColor at display time (see Flight.aircraftUIColor).
            (managedObj as! Flight).color = jason["aircraftColor"].stringValue
//            (managedObj as! Flight).outValue = dateFormatter.date(from: jason["automatedFlightData"]["oooi"]["automatedOutTime"].stringValue)
//            (managedObj as! Flight).offValue = dateFormatter.date(from: jason["automatedFlightData"]["oooi"]["automatedOffTime"].stringValue)
//            (managedObj as! Flight).onValue = dateFormatter.date(from: jason["automatedFlightData"]["oooi"]["automatedOnTime"].stringValue)
//            (managedObj as! Flight).in_Value = dateFormatter.date(from: jason["automatedFlightData"]["oooi"]["automatedInTime"].stringValue)
            (managedObj as! Flight).trailNumber = "SD002"
            (managedObj as! Flight).isLogged = jason["postFlightStatusName"].stringValue == "Logged" ? true : false
            
            break
        
        case .Pilot:
            
            (managedObj as! Pilot).firstName = jason["crewMember"]["firstName"].stringValue
            (managedObj as! Pilot).lastName = jason["crewMember"]["lastName"].stringValue
            (managedObj as! Pilot).flightCrewMemberId = jason["flightCrewMemberId"].stringValue
            
            (managedObj as! Pilot).role = jason["logbook"]["pic"].boolValue ? "PIC" : "SIC"
            (managedObj as! Pilot).takeOffDay = jason["logbook"]["dayTakeoffs"].stringValue
            (managedObj as! Pilot).takeOffNight = jason["logbook"]["nightTakeoffs"].stringValue
            (managedObj as! Pilot).landingsDay = jason["logbook"]["dayLandings"].stringValue
            (managedObj as! Pilot).landingsNight = jason["logbook"]["nightLandings"].stringValue
            (managedObj as! Pilot).instTime = jason["logbook"]["actualInstrumentDurationMinutes"].stringValue
            (managedObj as! Pilot).nightTime = jason["logbook"]["nightDurationMinutes"].stringValue
            (managedObj as! Pilot).track = jason["logbook"]["isTrackPerformed"].boolValue
            (managedObj as! Pilot).hold = jason["logbook"]["isHoldPerformed"].boolValue
            
            break
        case .Fuel:
            
            (managedObj as! Fuel).postedFlightId = jason["postedFlightFuel"]["postedFlightId"].stringValue
            (managedObj as! Fuel).fuelOut = jason["postedFlightFuel"]["fuelOut"].stringValue
            (managedObj as! Fuel).plannedUp = jason["postedFlightFuel"]["plannedUp"].stringValue
            (managedObj as! Fuel).upliftQuantityTypeId = jason["postedFlightFuel"]["upliftQuantityTypeId"].stringValue
            (managedObj as! Fuel).fuelBurn = jason["postedFlightFuel"]["fuelBurn"].stringValue
            (managedObj as! Fuel).quantityTypeId = jason["postedFlightFuel"]["quantityTypeId"].stringValue
            (managedObj as! Fuel).fuelOff = jason["postedFlightFuel"]["fuelOff"].stringValue
            (managedObj as! Fuel).fuelIn = jason["postedFlightFuel"]["fuelIn"].stringValue
            (managedObj as! Fuel).fuelOn = jason["postedFlightFuel"]["fuelOn"].stringValue
            (managedObj as! Fuel).actualUp = jason["postedFlightFuel"]["actualUp"].stringValue
            break

        case .Note:
            
            (managedObj as! Note).postedFlightId = jason["postedFlightAdditional"]["postedFlightId"].stringValue
            (managedObj as! Note).legNotes = jason["postedFlightAdditional"]["legNotes"].stringValue
            (managedObj as! Note).rejectedTakeoffs = jason["postedFlightAdditional"]["rejectedTakeoffs"].stringValue
            
            break
        case .Approach:
            break
        }
            
        
        
        
    }
    
    func updateManagedObject(type:EntityType,entity:NSEntityDescription,jason:JSON) -> Void {
        
    }
    
    func getEntityName(type:EntityType) -> String {
        
        switch type {
        case .Flight:
            return "Flight"
            
        case .Pilot:
            return "Pilot"
            
        case .Fuel:
            return "Fuel"
            
        case .Note:
            return "Note"
            
        case .Approach:
            return "Approach"
        }
        
    }
    func fetchData(type:EntityType,predicate:NSPredicate?,descriptor:NSSortDescriptor?) -> [Any] {
        
        var fetchRequest = getRequest(type: type)
        
        fetchRequest.predicate = predicate
        if let sortDescriptor = descriptor{
            fetchRequest.sortDescriptors = [sortDescriptor]
        }
        
        do {
            let result = try managedContext.fetch(fetchRequest)
            return result
        } catch  {
            print("Failed to fetch")
        }
        return [Any]()
    }
    
    func saveObject(type:EntityType,obj:NSManagedObject) -> Void {
        var predicate:NSPredicate!
        switch type {
        case .Flight:
            let flight = obj as! Flight
            predicate = NSPredicate(format:"postedFlightId == %@",flight.postedFlightId!)
            break

        case .Pilot:
            let flight = obj as! Flight
            predicate = NSPredicate(format:"postedFlightId == %@",flight.postedFlightId!)
            break
        case .Fuel:
            let fuel = obj as! Fuel
            predicate = NSPredicate(format:"postedFlightId == %@",fuel.postedFlightId!)
            break
        case .Note:
            let flight = obj as! Flight
            predicate = NSPredicate(format:"postedFlightId == %@",flight.postedFlightId!)
            break
        case .Approach:
            let flight = obj as! Flight
            predicate = NSPredicate(format:"postedFlightId == %@",flight.postedFlightId!)
            break
        }
        
        
        let dataArray = fetchData(type: .Fuel, predicate: predicate, descriptor: nil)
        if var model = dataArray.first as? NSManagedObject{
            model = obj
        }
        do {
            try managedContext.save()
        } catch let error {
            print("Could not save" + error.localizedDescription)
        }
    }
    
    func getRequest(type:EntityType) -> NSFetchRequest<NSFetchRequestResult> {
        switch type {
        case .Flight:
            return Flight.fetchRequest()
            
        case .Pilot:
            return Pilot.fetchRequest()
            
        case .Fuel:
            return Fuel.fetchRequest()
            
            
        case .Note:
            return Note.fetchRequest()
            
        case .Approach:
            return Approach.fetchRequest()
        }
    }
    
    func deleteEntity(types:[EntityType]) -> Void {
        
        
        do {
            for type in types{
                let request = NSBatchDeleteRequest(fetchRequest: getRequest(type: type))
                let result = try managedContext.execute(request)
                print("entity delete successful for \(getEntityName(type: type)) \(result.description)")
                
               
            }
            
            
            
            do {
                try managedContext.save()
            } catch  {
                print(error)
            }
        } catch  {
            print("Failed to delete")
        }
        
    }
    
}
