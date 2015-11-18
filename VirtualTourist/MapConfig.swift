//
//  MapConfig.swift
//  VirtualTourist
//
//  Created by X.I. Losada on 13/11/15.
//  Copyright © 2015 XiLosada. All rights reserved.
//

import Foundation

/**
    Class to manage the MKMapView configuration parameters
*/
class MapConfig{
    
    struct Keys {
        static let CenterLatitude = "c_lat"
        static let CenterLongitude = "c_long"
        static let LatitudeDelta = "lat_delta"
        static let LongitudeDelta = "long_delta"
    }
    
    /// latitude value of the center point
    var centerLatitude: Double
    /// longitude value of the center point
    var centerLongitude: Double
    /// latitude value of the area
    var latitudeDelta: Double
    /// longitude value of the area
    var longitudeDelta: Double

    init(dictionary: [String : AnyObject]){
        centerLatitude = dictionary[Keys.CenterLatitude] as! Double
        centerLongitude = dictionary[Keys.CenterLongitude] as! Double
        latitudeDelta = dictionary[Keys.LatitudeDelta] as! Double
        longitudeDelta = dictionary[Keys.LongitudeDelta] as! Double
    }
    
    init(latitudeCenter: Double,longitudeCenter: Double, latitudeDelta: Double, longitudeDelta: Double){
        self.centerLatitude = latitudeCenter
        self.centerLongitude = longitudeCenter
        self.latitudeDelta = latitudeDelta
        self.longitudeDelta = longitudeDelta
    }
    
    /// Convenience method to get the Config Value from NSUserDefaults.
    static func getFromNSUserDefaults() -> MapConfig {
        let userDefault = NSUserDefaults.standardUserDefaults()
        // Default value Paris
        userDefault.registerDefaults([
            Keys.CenterLatitude : 48.8567,
            Keys.CenterLongitude : 2.3508,
            Keys.LatitudeDelta : 10,
            Keys.LongitudeDelta : 10
        ])
        return MapConfig(
            latitudeCenter: userDefault.doubleForKey(Keys.CenterLatitude),
            longitudeCenter: userDefault.doubleForKey(Keys.CenterLongitude),
            latitudeDelta: userDefault.doubleForKey(Keys.LatitudeDelta),
            longitudeDelta: userDefault.doubleForKey(Keys.LongitudeDelta))
    }
    
    /// Save the config to NSUserDefaults.
    func save(){
        NSUserDefaults.standardUserDefaults().setDouble(centerLatitude, forKey: Keys.CenterLatitude)
        NSUserDefaults.standardUserDefaults().setDouble(centerLongitude, forKey: Keys.CenterLongitude)
        NSUserDefaults.standardUserDefaults().setDouble(latitudeDelta, forKey: Keys.LatitudeDelta)
        NSUserDefaults.standardUserDefaults().setDouble(longitudeDelta, forKey: Keys.LongitudeDelta)
    }
}