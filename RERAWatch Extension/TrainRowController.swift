//
//  TrainRowController.swift
//  RERA
//
//  Created by Benoît Clouet on 27/12/2016.
//  Copyright © 2016 Benoît Clouet. All rights reserved.
//

import WatchKit

class TrainRowController: NSObject {
    @IBOutlet var lblDirection: WKInterfaceLabel!
    @IBOutlet var lblHour: WKInterfaceLabel!
    @IBOutlet var lblRemaining: WKInterfaceLabel!
    
    var train: Station.Train? {
        didSet {
            if let train = train {
                lblDirection.setText(train.destination)
                lblHour.setText(train.message)
                lblRemaining.setText(train.timeRemaining)
            }
        }
    }
}
