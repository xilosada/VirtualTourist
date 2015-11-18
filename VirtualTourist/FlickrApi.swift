//
//  FlickrApi.swift
//  VirtualTourist
//
//  Created by X.I. Losada on 14/11/15.
//  Copyright © 2015 XiLosada. All rights reserved.
//

import Foundation
import UIKit
import CoreData
class FlickrApi {
    
    /// Set the Flickr Api Key
    private static let API_KEY = "ENTER_YOUR_API_KEY_HERE"
    
    static let sharedInstance:FlickrApi! = FlickrApi()
    private let sharedSession: NSURLSession!
    let imageCache: ImageCache = ImageCache.sharedInstance
    var downloading: Bool = false
    
    private let BASE_URL = "https://api.flickr.com/services/rest/"
    private static let METHOD_NAME = "flickr.photos.search"
    private static let EXTRAS = "url_m"
    private static let SAFE_SEARCH = "1"
    private static let DATA_FORMAT = "json"
    private static let NO_JSON_CALLBACK = "1"
    private static let MAX_RESULTS = 60
    
    let BOUNDING_BOX_HALF_WIDTH = 1.0
    let BOUNDING_BOX_HALF_HEIGHT = 1.0


    let LAT_MIN = -90.0
    let LAT_MAX = 90.0
    let LON_MIN = -180.0
    let LON_MAX = 180.0
    
    private let BaseMethodArguments: [String:AnyObject] = [
        "method": METHOD_NAME,
        "per_page": MAX_RESULTS,
        "api_key": API_KEY,
        "safe_search": SAFE_SEARCH,
        "extras": EXTRAS,
        "format": DATA_FORMAT,
        "nojsoncallback": NO_JSON_CALLBACK
    ]
    
    private init(){
        sharedSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
    }
    
    func fetchPhotos(pin: Pin, random: Bool = false, handler:((flag:Bool, error: NSError?)->Void)? = nil) {
        let page = random ? Int(arc4random_uniform(10) + 1) : 1
        print("Downloading photos")
        getPhotos(pin.latitude, longitude: pin.longitude, page: page, completionHandler: {
            results, error in
            if let error = error {
                if let handler = handler{
                    handler(flag: false, error:  error)
                }
                print(error.localizedDescription)
            } else {
                for photo in results!{
                    photo.pin = pin
                }
                print("\(results?.count) photos saved")
                CoreDataStackManager.sharedInstance.saveContext()
                if let handler = handler{
                    handler(flag: true, error: nil)
                }
            }
        })
    }
    
    /// Return an array oh Photos from specific locataion. Default page is 1
    func getPhotos(latitude: Double, longitude: Double, page: Int = 1,completionHandler :(result: [Photo]?, error: NSError?)->Void){
        if downloading {
            return
        }
        downloading = true
        var params = BaseMethodArguments
        params["bbox"] = createBoundingBoxString(latitude,longitude: longitude)
        if page != 1 {
            params["page"] = page
        }
        let request = generateRequest(params)
        executeRequest(request, completionHandler: { data, error in
            self.downloading = false
            if let error = error{
                completionHandler(result: nil, error: error)
            } else {
               self.extractPhotoInfoFromResult(data!, completionHandler: completionHandler)
            }
        })
        
    }
    
    func extractPhotoInfoFromResult(result: NSData, completionHandler rHandler: (result: [Photo]?, error: NSError?)->Void) {
        parseJSONWithCompletionHandler(result, completionHandler: {parsedResult,error in
            if let error = error {
                rHandler(result: nil, error: error)
            }
            else{
                if let photosDictionary = parsedResult!.valueForKey("photos") as? [String:AnyObject] {
                    self.parsePhotoArrayDict(photosDictionary, completionHandler: rHandler)
                } else {
                    rHandler(result: nil, error: NSError(domain: "key not found or invalid value", code: 2, userInfo: nil))
                }
            }
        })
    }
    
    func parsePhotoArrayDict(dictionary: [String: AnyObject], completionHandler rHandler: (result: [Photo]?, error: NSError?)->Void){
        var totalPhotosVal = 0
        if let totalPhotos = dictionary["total"] as? String {
            totalPhotosVal = (totalPhotos as NSString).integerValue
        } else {
            rHandler(result: nil, error: NSError(domain: "key not found or invalid value: total", code: 1, userInfo: nil))
            return
        }
        var photoArray = [Photo]()
    
        if totalPhotosVal > 0 {
    
            if let photoDictionaryArray = dictionary["photo"] as? [[String: AnyObject]] {
                for i in  0 ..< photoDictionaryArray.count {
                    let photo = Photo(dictionary: photoDictionaryArray[i], context: CoreDataStackManager.sharedInstance.managedObjectContext)
                    photoArray.append(photo)
                    UIImage.getFromPhoto(photo)
                }
            }
        }
        rHandler(result: photoArray, error: nil)
    }
    
    func generateRequest(params:[String:AnyObject]) -> NSURLRequest{
        let urlString = BASE_URL + escapedParameters(params)
        let url = NSURL(string: urlString)!
        return NSURLRequest(URL: url)
    }
    
    func executeRequest(request: NSURLRequest, completionHandler: (data: NSData?, error: NSError?)->Void ){
        let task = sharedSession.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                completionHandler(data: nil, error: error)
            } else if !self.checkResponseSuccess(response) {
                completionHandler(data: nil, error: NSError(domain: "Invalid Response", code: 1, userInfo: nil))
            } else {
                completionHandler(data: data, error: nil)
            }
        }
        task.resume()
    }
    
    func parseResponseData(data: NSData,completionHandler handler: (results: AnyObject?, error: NSError?) ->Void){
        let parsedResult = (try! NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments))
        handler(results: parsedResult, error: nil)
    }

    func createBoundingBoxString(latitude: Double, longitude: Double ) -> String {
        
        /* Fix added to ensure box is bounded by minimum and maximums */
        let bottom_left_lon = max(longitude - BOUNDING_BOX_HALF_WIDTH, LON_MIN)
        let bottom_left_lat = max(latitude - BOUNDING_BOX_HALF_HEIGHT, LAT_MIN)
        let top_right_lon = min(longitude + BOUNDING_BOX_HALF_HEIGHT, LON_MAX)
        let top_right_lat = min(latitude + BOUNDING_BOX_HALF_HEIGHT, LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    
    func parseJSONWithCompletionHandler(data: NSData, completionHandler: (parsedResult: AnyObject?, error: NSError?) -> Void) {
        let parsedResult: AnyObject?
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
            completionHandler(parsedResult: parsedResult, error: nil)
        } catch let error as NSError {
            completionHandler(parsedResult: nil, error: error)
        } catch {
            completionHandler(parsedResult: nil, error: NSError(domain: "Unexpected error", code: 1, userInfo: nil))
        }
    }
    
    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    // Return true if the status code is success ( 2XX )
    func checkResponseSuccess(response: NSURLResponse?)->Bool{
        if let statusCode = (response as? NSHTTPURLResponse)?.statusCode {
            if case 200 ..< 300 = statusCode {
                return true
            }
        }
        return false
    }
    
    static func checkApiKeyIsEmpty()->Bool{
        return API_KEY.isEmpty || API_KEY == "ENTER_YOUR_API_KEY_HERE"
    }
    
    
}