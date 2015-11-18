//
//  Pin.swift
//  VirtualTourist
//
//  Created by X.I. Losada on 13/11/15.
//  Copyright © 2015 XiLosada. All rights reserved.
//

import Foundation
import CoreData

class Pin : NSManagedObject{
    
    struct Keys {
        static let Id = "id"
        static let Longitude = "longitude"
        static let Latitude = "latitude"
        static let Photos = "photo"
    }
    
    @NSManaged var id: NSNumber?
    @NSManaged var longitude: Double
    @NSManaged var latitude: Double
    
    /// Photo entities related with this pin
    @NSManaged var photos: [Photo]
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)

    }
    
    init(dictionary: [String:AnyObject], context: NSManagedObjectContext){
        
        let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        id = dictionary[Keys.Id] as? NSNumber
        latitude = dictionary[Keys.Latitude] as! Double
        longitude = dictionary[Keys.Longitude] as! Double
    }
}
