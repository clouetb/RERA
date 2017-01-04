//
//  ViewController.swift
//  RERA
//
//  Created by Benoît Clouet on 26/12/2016.
//  Copyright © 2016 Benoît Clouet. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {
    /// Location manager used to start and stop updating location.
    let manager = CLLocationManager()
    
    /// Indicates whether the location manager is updating location.
    var isUpdatingLocation = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        manager.requestAlwaysAuthorization()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

