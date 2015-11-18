//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by X.I. Losada on 13/11/15.
//  Copyright © 2015 XiLosada. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance.managedObjectContext
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureMapView()
        do{
            try fetchedResultsController.performFetch()
            loadPins(fetchedResultsController.fetchedObjects as! [Pin])
        } catch {}
        
        fetchedResultsController.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        if (FlickrApi.checkApiKeyIsEmpty()){
            self.showAlert("API KEY IS EMPTY", message: "Please modify FlickrApi.swift")
        }
    }
    
    private func configureMapView(){
        //add a long press recognizer to the mapView
        let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        longPressRecogniser.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPressRecogniser)
        loadMapConfig(MapConfig.getFromNSUserDefaults())
        //set this view controller as the mapView delegate
        mapView.delegate = self
    }
    

    func loadMapConfig(mapConfig: MapConfig){
        let coordinate = CLLocationCoordinate2D(latitude: mapConfig.centerLatitude, longitude: mapConfig.centerLongitude)
        let span = MKCoordinateSpan(latitudeDelta: mapConfig.latitudeDelta, longitudeDelta: mapConfig.longitudeDelta)
        mapView.setRegion(MKCoordinateRegionMake(coordinate,span), animated: true)

    }
    
    func loadPins(pins: [Pin]){
        mapView.removeAnnotations(mapView.annotations)
        for pin in pins {
            let pinAnnotation = MKPointAnnotation()
            pinAnnotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(pin.latitude), longitude: CLLocationDegrees(pin.longitude))
            mapView.addAnnotation(pinAnnotation)
        }
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView){
        do{ try fetchedResultsController.performFetch() } catch {}
        let selectedPin = (fetchedResultsController.fetchedObjects as! [Pin]) .filter({
            let coordinate = view.annotation!.coordinate
            return $0.latitude == coordinate.latitude
                && $0.longitude == coordinate.longitude
        }).first
        performSegueWithIdentifier("openLocationAlbum", sender: selectedPin)
    }
    
    
    func deselectAnnotations(){
        for annotation: MKAnnotation in mapView.selectedAnnotations {
            mapView.deselectAnnotation(annotation, animated: true)
        }
    }
    
    func mapView(mapView: MKMapView,
        regionDidChangeAnimated animated: Bool){
        let region = mapView.region
        let mapConfig = MapConfig(
            latitudeCenter: region.center.latitude,
            longitudeCenter: region.center.longitude,
            latitudeDelta: region.span.latitudeDelta,
            longitudeDelta: region.span.longitudeDelta)
        mapConfig.save()
    }


    /**
     The app contains a map view that allows users to drop pins with a touch and hold gesture. When the pin drops,
     users can drag the pin until their finger is lifted.
     */
     
    // Used to store the last MapAnnotation while a LongPress action is taking place.*/
    private var draggablePin: MKPointAnnotation?
    
    func handleLongPress(gestureRecognizer : UIGestureRecognizer){
        
        let touchPoint = gestureRecognizer.locationInView(mapView)
        let newCoordinates = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        
        // When the long click begins create a new annotation
        if gestureRecognizer.state == UIGestureRecognizerState.Began {
            draggablePin = MKPointAnnotation()
            draggablePin!.coordinate = newCoordinates
            mapView.addAnnotation(draggablePin!)
        }
        
        // When the long click end save the annotation and free draggeablePin
        else if gestureRecognizer.state == UIGestureRecognizerState.Ended {
            let pin = getPinFromAnnotation(draggablePin!)
            ///As soon as a pin is dropped on the map, the photos for that location are pre-fetched from Flickr.
            FlickrApi.sharedInstance.fetchPhotos(pin)
            CoreDataStackManager.sharedInstance.saveContext()
            // free pin object
            draggablePin = nil
        }
        
        // With other gesture (Change) update annotation's coordinate
        else if draggablePin != nil {
            draggablePin!.coordinate = newCoordinates
        }
    }

    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Pin.Keys.Id, ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
    }()
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier == "openLocationAlbum"){
            let photoAlbumVC: PhotoAlbumViewController = segue.destinationViewController as! PhotoAlbumViewController
            let data = sender as! Pin
            photoAlbumVC.pin = data
            //deselect clicked annotation before the segue
            deselectAnnotations()
        }
    }
    
    func getPinFromAnnotation(annotation: MKAnnotation) -> Pin {
        var pinDictionary = [String:AnyObject]()
        pinDictionary[Pin.Keys.Latitude] = annotation.coordinate.latitude
        pinDictionary[Pin.Keys.Longitude] = annotation.coordinate.longitude
        return Pin(dictionary: pinDictionary, context: sharedContext)
    }
}
