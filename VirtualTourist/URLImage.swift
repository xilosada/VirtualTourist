//
//  URLImage.swift
//  VirtualTourist
//
//  Created by X.I. Losada on 16/11/15.
//  Copyright © 2015 XiLosada. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    
    // Loads image asynchronously
    static func loadFromURL(url: NSURL, callback: (UIImage?,NSError?)->()) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
            let imageData = NSData(contentsOfURL: url)
            if let data = imageData {
                    if let image = UIImage(data: data) {
                        ImageCache.sharedInstance.storeImage(image, withIdentifier: url.lastPathComponent!)
                        dispatch_async(dispatch_get_main_queue(), {
                            callback(image,nil)
                        })
                    } else{
                        callback(nil,NSError(domain: "Virtu", code: 2, userInfo: nil))
                    }
                
            }else{
                callback(nil,NSError(domain: "Virtu", code: 3, userInfo: nil))
            }
        })
    }
    
    static func getFromPhoto(photo: Photo) {
        loadFromURL(NSURL(string: photo.imagePath)!, callback: { image,error in
            if let error = error {
                photo.cancelled = true
                print(error.localizedDescription)
            }else{
                photo.image = image
            }
            CoreDataStackManager.sharedInstance.saveContext()
        })
    }
}
