//
//  Stations.swift
//  RERA
//
//  Created by Benoît Clouet on 26/12/2016.
//  Copyright © 2016 Benoît Clouet. All rights reserved.
//

import Foundation
import WatchKit
import CoreLocation

var currentCoordinates = CLLocation.init(latitude: 0.0, longitude: 0.0)
var currentDownloadTask: URLSessionDataTask?

class Station {
    let nomStation: String
    let direction: String
    let strLatitude: String
    var latitude: Double {
        get {
            return Double.init(strLatitude)!
        }
    }
    let strLongitude: String
    var longitude: Double {
        get {
            return Double.init(strLongitude)!
        }
    }
    var distance: Double {
        get {
            let selfLocation = CLLocation.init(latitude: self.latitude, longitude: self.longitude)
            return selfLocation.distance(from: CLLocation.init(latitude: currentCoordinates.coordinate.latitude, longitude: currentCoordinates.coordinate.longitude))
        }
    }
    let strId: String
    var id: Int {
        get {
            return Int.init(strId)!
        }
    }
    let strDestination: String
    var destination: Int {
        get {
            return Int.init(strDestination)!
        }
    }
    
    class func allStations() -> [Station] {
        var stations = [Station]()
        if let path = Bundle.main.path(forResource: "Stations", ofType: "json"), let data = NSData(contentsOfFile: path) {
            do {
                let json = try JSONSerialization.jsonObject(with: data as Data, options: JSONSerialization.ReadingOptions.allowFragments) as! [Dictionary<String, String>]
                for dict in json {
                    let station = Station(dictionary: dict)
                    stations.append(station)
                }
            } catch {
                NSLog("allStations : \(error)")
            }
        }
        return stations
    }
    
    init(nomStation: String, direction: String, latitude: String, longitude: String, id: String, destination: String) {
        self.nomStation = nomStation
        self.direction = direction
        self.strLatitude = latitude
        self.strLongitude = longitude
        self.strId = id
        self.strDestination = destination
    }
    
    convenience init(dictionary: [String: String]) {
        let nomStation = dictionary["nomStation"]!
        let direction = dictionary["direction"]!
        let strLatitude = dictionary["latitude"]!
        let strLongitude = dictionary["longitude"]!
        let strId = dictionary["id"]!
        let strDestination = dictionary["destination"]!
        self.init(nomStation: nomStation, direction: direction, latitude: strLatitude, longitude: strLongitude, id: strId, destination: strDestination)
    }

    func fetchTrains(completionHandler: @escaping (([Station.Train]) -> Void)) {
        var trains = [Train]()
        let requestURL = String("https://api-ratp.pierre-grimaud.fr/v2/rers/a/stations/\(self.id)?destination=\(self.destination)")!
        NSLog("requestURL: \(requestURL)")
        // Stick to the main thread
        DispatchQueue.main.async() {
            // Stop currently running download task
            if (currentDownloadTask != nil) && (currentDownloadTask?.state == .running) {
                NSLog("Task already running, cancelling")
                currentDownloadTask?.cancel()
            }
            // Launch download task (callback)
            currentDownloadTask = URLSession.shared.dataTask(with: URL(string: requestURL)!) {
                data, response, error in
                do {
                    guard error == nil else {
                        NSLog("Error fetching \(error)")
                        return
                    }
                    guard let data = data else {
                        NSLog("Data is empty")
                        return
                    }
                    NSLog("Processing data")
                    let json = try JSONSerialization.jsonObject(with: data as Data, options: JSONSerialization.ReadingOptions.allowFragments) as! Dictionary<String, Any>
                    let responseDic: Dictionary<String, Any> = json["response"] as! Dictionary<String, Any>
                    let schedules: [Dictionary<String, String>] = responseDic["schedules"]! as! [Dictionary<String, String>]
                    for dict in schedules {
                        let train = Train(train: dict)
                        trains.append(train)
                    }
                    NSLog("Trains: \(trains)")
                }
                catch {
                    NSLog("fetchTimeTable \(error)")
                }
                // Run completion handler once the dict has fully been parsed
                completionHandler(trains)
            }
            NSLog("Launching task")
            currentDownloadTask?.resume()
        }
    }

    /*
    func fetchTrains(completionHandler: @escaping (([Station.Train]) -> Void)) {
        var trains = [Train]()
        let path = Bundle.main.path(forResource: "test", ofType: "json")
        let data = NSData(contentsOfFile: path!)
        do {
            let json = try JSONSerialization.jsonObject(with: data as! Data, options: JSONSerialization.ReadingOptions.allowFragments) as! Dictionary<String, Any>
            let responseDic: Dictionary<String, Any> = json["response"] as! Dictionary<String, Any>
            let schedules: [Dictionary<String, String>] = responseDic["schedules"]! as! [Dictionary<String, String>]
            for dict in schedules {
                let train = Train(train: dict)
                trains.append(train)
            }
        }
        catch {
            NSLog("fetchTimeTable \(error)")
        }
        completionHandler(trains)
    }
    */
    
    class Train: CustomStringConvertible {
        var destination: String
        var strMessage:String
        var message: String {
            get {
                switch self.strMessage {
                case let x where x.hasSuffix("approche"):
                    return "Approche"
                case let x where x.hasSuffix("quai"):
                    return "À quai"
                case let x where x.hasSuffix("retardé"):
                    return "Retardé"
                case let x where x.hasSuffix("indisponibles"):
                    return "Terminé"
                default:
                    return self.strMessage
                }
            }
        }
        var timeScheduled: Date {
            get {
                let time = self.strMessage.components(separatedBy: ":")
                if time.count == 1 {
                    return Date()
                }
                let hours = Int.init(time.first!)
                let minutes = Int.init(time.last!)
                let currentdate = Date()
                let calendar = Calendar.current
                let currentDay = calendar.component(.day, from: currentdate)
                let currentMonth = calendar.component(.month, from: currentdate)
                let currentYear = calendar.component(.year, from: currentdate)
                let timeScheduled = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: currentDay, hour: hours, minute: minutes))
                return timeScheduled!
            }
        }
        
        var timeRemaining: String {
            get {
                let remaining = self.timeScheduled.timeIntervalSinceNow
                let ti = NSInteger(remaining)
                let seconds = ti % 60
                let minutes = (ti - seconds) / 60
                let timeRemaining = String(format: "%dmin", minutes)
                //NSLog("Remaining: \(remaining)secs is \(timeRemaining)")
                return timeRemaining
            }
        }
        
        public var description: String {
            return "{Train: \(self.destination), \(self.strMessage), \(self.timeRemaining)}"
        }
        
        init(destination: String, message: String) {
            self.destination = destination
            self.strMessage = message
        }
        
        convenience init(train: Dictionary<String, String>) {
            let destination = train["destination"]!
            let message = train["message"]!
            self.init(destination: destination, message: message)
        }
    }
}

