//
//  StationRowController.swift
//  RERA
//
//  Created by Benoît Clouet on 27/12/2016.
//  Copyright © 2016 Benoît Clouet. All rights reserved.
//

import WatchKit

class StationRowController: NSObject {
    @IBOutlet var lblStation: WKInterfaceLabel!
    @IBOutlet var lblDirection: WKInterfaceLabel!
    var index = 0
    var station: Station? {
        didSet {
            if let station = station {
                lblStation.setText(station.nomStation)
                lblDirection.setText(station.direction)
            }
        }
    }
}
