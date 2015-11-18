//
//  FlickrApiTests.swift
//  VirtualTourist
//
//  Created by X.I. Losada on 14/11/15.
//  Copyright © 2015 XiLosada. All rights reserved.
//

import XCTest
import VirtualTourist

class FlickrApiTests: XCTestCase {
    
    var flickrApi: FlickrApi!
    let latitude = 2.158990
    let longitude = 41.388790
    
    let mockJson: NSData = "{\"photos\":{\"page\":1,\"pages\":180321,\"perpage\":2,\"total\":\"360641\",\"photo\":[{\"id\":\"22388898714\",\"owner\":\"24944211@N00\",\"secret\":\"850b6d3964\",\"server\":\"573\",\"farm\":1,\"title\":\"2445\",\"ispublic\":1,\"isfriend\":0,\"isfamily\":0,\"url_m\":\"https://farm1.staticflickr.com/573/22388898714_850b6d3964.jpg\",\"height_m\":\"300\",\"width_m\":\"500\"},{\"id\":\"23042605352\",\"owner\":\"28438417@N08\",\"secret\":\"34e6dc5123\",\"server\":\"5668\",\"farm\":6,\"title\":\"Glaciers\",\"ispublic\":1,\"isfriend\":0,\"isfamily\":0,\"url_m\":\"https://farm6.staticflickr.com/5668/23042605352_34e6dc5123.jpg\",\"height_m\":\"333\",\"width_m\":\"500\"}]},\"stat\":\"ok\"}".dataUsingEncoding(NSUTF8StringEncoding)!
    
    override func setUp() {
        super.setUp()
        flickrApi = FlickrApi.sharedInstance
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testIsASingleton() {
        XCTAssertNotNil(flickrApi)
        XCTAssert(flickrApi === FlickrApi.sharedInstance)
    }
    
    func testParseJson() {
        
        flickrApi.extractPhotoInfoFromResult(mockJson, completionHandler:{ parsedResult, error in
            if let error = error {
                XCTFail(error.localizedDescription)
            }else {
                XCTAssertNotNil(parsedResult!)
                XCTAssertTrue(parsedResult?.count == 2)
            }
        })
    }
    
    func testConnectionToFlikr(){
        flickrApi.getPhotos(latitude, longitude: longitude, completionHandler: { result, error in
            if let error = error{
                XCTFail(error.localizedDescription)
            }else {
                XCTAssertTrue(true)
            }
        })
    }
    
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
