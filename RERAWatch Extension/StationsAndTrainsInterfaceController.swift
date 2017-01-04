//
//  StationsAndTrainsController.swift
//  RERA
//
//  Created by Benoît Clouet on 27/12/2016.
//  Copyright © 2016 Benoît Clouet. All rights reserved.
//

import WatchKit
import Foundation
import CoreLocation

class StationsAndTrainsInterfaceController: WKInterfaceController, CLLocationManagerDelegate {
    
    @IBOutlet var stationsAndTrainsTable: WKInterfaceTable!
    var stations = Station.allStations()
    let locationManager = CLLocationManager()
    var trainsIndexSet = IndexSet([])
    
    override func awake(withContext context: Any?) {
        NSLog("awake_indexSet: [\(self.trainsIndexSet.first)..\(self.trainsIndexSet.last)]")
        super.awake(withContext: context)
        locationManager.delegate = self
        // Set desiredAccuracy using a GPS of IP:
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        let authorizationStatus = CLLocationManager.authorizationStatus()
      
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied:
            NSLog(".denied ")

        default:
            NSLog("unexpected ")
        }
    }
    
    override func willActivate() {
        NSLog("willActivate")
        super.willActivate()
        locationManager.requestLocation()
    }
    
    override func didDeactivate() {
        NSLog("didDeactivate")
        super.didDeactivate()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        NSLog("didUpdateLocations")
        currentCoordinates = locations.last!
        locationManager.stopUpdatingLocation()

        DispatchQueue.main.async() {
            self.stations.sort(by: {$0.distance < $1.distance})
            self.stationsAndTrainsTable.setNumberOfRows(self.stations.count, withRowType: "StationRow")
            self.trainsIndexSet = IndexSet([])
            for index in 0..<self.stationsAndTrainsTable.numberOfRows {
                if let controller = self.stationsAndTrainsTable.rowController(at: index) as? StationRowController {
                    controller.station = self.stations[index]
                    controller.index = index
                }
            }
            self.table(self.stationsAndTrainsTable, didSelectRowAt: 0)
        }
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        NSLog("didSelectRowAt \(rowIndex)")
        // Callback called once download is finished
        let updateTrainsTable: ([Station.Train]) -> Void = {
            trains in
            NSLog("updateTrainsTable")
            WKInterfaceDevice.current().play(.click)
            DispatchQueue.main.async() {
                if !trains.isEmpty {
                    NSLog("didselect_indexSet: [\(self.trainsIndexSet.first)..\(self.trainsIndexSet.last)]")
                    // Get index of the station entry inside the sorted station index
                    let selectedIndex = (self.stationsAndTrainsTable.rowController(at: rowIndex) as! StationRowController).index

                    if (!self.trainsIndexSet.isEmpty) {
                        NSLog("Deleting: [\(self.trainsIndexSet.first)..\(self.trainsIndexSet.last)] of \(self.stationsAndTrainsTable.numberOfRows) of rows")
                        self.stationsAndTrainsTable.removeRows(at: self.trainsIndexSet)
                    }
                    // Build the indexset of the rows to be added
                    self.trainsIndexSet = IndexSet(selectedIndex+1..<selectedIndex+trains.count+1)
                    self.stationsAndTrainsTable.insertRows(at: self.trainsIndexSet, withRowType: "TrainRow")
                    var i = 0
                    // Ring if train is about to arrive
                    if trains[0].strMessage.components(separatedBy: ":").count == 1 {
                        WKInterfaceDevice.current().play(.directionUp)
                    }
                    // Cycle through indexset to set the train row
                    for currentItem in self.trainsIndexSet {
                        if let controller = self.stationsAndTrainsTable.rowController(at: currentItem) as? TrainRowController {
                            // Train is relative to the trains array
                            controller.train = trains[i]
                        }
                        i = i + 1
                    }
                    guard let indexToScrollTo = self.trainsIndexSet.first else {
                        return
                    }
                    self.stationsAndTrainsTable.scrollToRow(at: indexToScrollTo)
                }
            }
        } // End of callback
        
        // Get index of the row that was tapped (only station rows can be selected by storyboard design)
        let selectedIndex = (self.stationsAndTrainsTable.rowController(at: rowIndex) as! StationRowController).index
        // Fetch trains table for the selected station
        stations[selectedIndex].fetchTrains(completionHandler: updateTrainsTable)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        NSLog("error : \(error.localizedDescription)")
    }

}
