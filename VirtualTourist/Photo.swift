//
//  Photo.swift
//  VirtualTourist
//
//  Created by X.I. Losada on 13/11/15.
//  Copyright © 2015 XiLosada. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Photo : NSManagedObject {
    
    struct Keys {
        static let Id = "id"
        static let ImagePath = "url_m"
    }
    
    @NSManaged var id: NSNumber?
    
    /// Url of the photo
    @NSManaged var imagePath: String
    
    /// True if the photo has been downloaded
    @NSManaged var stored: Bool
    
    /// True if the photo download has been cancelled
    @NSManaged var cancelled: Bool
    
    /// The pin related with this photo
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    /**
        Underlying files are automatically deleted when a Photo object is removed from Core Data, 
        using code in the Photo managed object.
     */
    override func willSave() {
        if deleted{
            print("deleting stored image ...")
            ImageCache.sharedInstance.storeImage(nil, withIdentifier: NSURL(string: imagePath)!.lastPathComponent!)
        }
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        var parsedId: NSNumber!
        if let idString = dictionary[Keys.Id] as? String {
            if let integer = Int(idString){
                parsedId = NSNumber(integer:integer)
            }
        }
        id = parsedId
        stored = (image != nil)
        cancelled = false
        imagePath = dictionary[Keys.ImagePath] as! String
    }
    
    var image: UIImage? {
        get {
            return ImageCache.sharedInstance.imageWithIdentifier(NSURL(string: imagePath)!.lastPathComponent)
        }
        set {
            ImageCache.sharedInstance.storeImage(image, withIdentifier: NSURL(string: imagePath)!.lastPathComponent!)
            stored = true
            cancelled = false
        }
    }
}
