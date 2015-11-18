//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by X.I. Losada on 13/11/15.
//  Copyright © 2015 XiLosada. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    
    let imageCache = ImageCache.sharedInstance
    let imagePlaceHolder = UIImage(named: "ImagePlaceholder")

    var pin: Pin!
    
    private var blockOperation: NSBlockOperation!
    private var shouldReloadCollection: Bool!

    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance.managedObjectContext
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCollectionView()
        mapView.showCustomPin(pin)
        
        fetchAll()
    }
    
    func configureCollectionView(){
        // Do any additional setup after loading the view, typically from a nib.
        collectionView!.dataSource = self
        collectionView!.delegate = self
        collectionView!.backgroundColor = UIColor.whiteColor()
    }

    override func viewWillAppear(animated: Bool) {
        if fetchedResultsController.fetchedObjects!.isEmpty{
            FlickrApi.sharedInstance.fetchPhotos(pin, handler:{ flag, error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    self.collectionView.reloadData()
                }
            })
        }
    }
    
    // Try to reload cancelled images
    override func viewDidAppear(animated: Bool) {
        if !fetchedResultsController.fetchedObjects!.isEmpty {
            reloadCancelled()
        }
    }
    
    func reloadCancelled() {
        fetchedResultsController.fetchedObjects!
            .map({ return $0 as! Photo})
            .filter({ return $0.cancelled })
            .forEach({ photo in
                UIImage.getFromPhoto(photo)
            })
    }
    
    
    //MARK : UICollectionViewDelegate methods
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCollectionViewCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        let imagePath = photo.imagePath
        decorateCollectonCell(cell, imagePath: imagePath)
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didEndDisplayingCell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath){
        (didEndDisplayingCell as! PhotoCollectionViewCell).photoView.image = imagePlaceHolder
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath:NSIndexPath)
    {
        if photoDownloadFinished() {
            let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
            deletePhoto(photo)
        }
    }
    
    func deletePhoto(photo:Photo) {
        sharedContext.deleteObject(photo)
        CoreDataStackManager.sharedInstance.saveContext()
    }
    
    // MARK: NSFetchedResultsController
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin);
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
    }()
    
    func fetchAll(){
        do {
            try fetchedResultsController.performFetch()
        } catch {}
        fetchedResultsController.delegate = self
    }
    
    
    // MARK: Fetch Controller Delegate Methods
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        shouldReloadCollection = false
        /// Based on https://github.com/AshFurrow/UICollectionView-NSFetchedResultsController/issues/13
        blockOperation = NSBlockOperation()
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        // Checks if we should reload the collection view to fix a bug @ http://openradar.appspot.com/12954582
        if photoDownloadFinished() {
            refreshButton.enabled = true
        } else {
            refreshButton.enabled = false
        }
        if self.shouldReloadCollection! {
            self.collectionView.reloadData()
        } else{
            self.collectionView.performBatchUpdates(
                {
                    self.blockOperation.start()
                }, completion: nil)
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject,
        atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
            
        let collectionView = self.collectionView
        switch type {
            
            case .Insert:
                if self.collectionView.numberOfSections() > 0 {
                    blockOperation.addExecutionBlock({
                        collectionView.insertItemsAtIndexPaths([newIndexPath!])
                    })
                    return
                }
                self.shouldReloadCollection = true
            
            case .Delete:
                if self.collectionView.numberOfItemsInSection(indexPath!.section) > 0 {
                    blockOperation.addExecutionBlock({
                        collectionView.deleteItemsAtIndexPaths([indexPath!])
                    })
                    return
                }
                self.shouldReloadCollection = true
            
            case .Update:
                blockOperation.addExecutionBlock({
                    collectionView.reloadItemsAtIndexPaths([indexPath!])
                })
            
            case .Move:
                blockOperation.addExecutionBlock({
                    collectionView!.moveItemAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
                })
        }
    }
    
    @IBAction func refreshButtonPressed(sender: AnyObject) {
        if photoDownloadFinished() {
            fetchedResultsController.fetchedObjects!.forEach({
                let photo = $0 as! Photo
                deletePhoto(photo)
            })
            fetchPhotos(pin)
        }
    }
    
    
    // Return true if the are not pending photo downloads
    func photoDownloadFinished() -> Bool {
        let unstoredCount = fetchedResultsController.fetchedObjects!.filter({
            let photo = $0 as! Photo
            return !photo.stored
        }).count
        if unstoredCount == 0{
            return true
        }
        return false
    }
    
    // Fetch random photos from Flickr based on pin's location
    func fetchPhotos(pin: Pin){
        
        self.fetchedResultsController.delegate = nil
        self.refreshButton.enabled = false
        let activityIndicator = showActivityIndicator()
        
        FlickrApi.sharedInstance.fetchPhotos(pin, random: true, handler: { flag, error in
            self.releaseActivityIndicator(activityIndicator)
            if flag {
                self.collectionView.reloadData()
                self.fetchAll()
            } else{
                self.refreshButton.enabled = true
                self.showError(error!.localizedDescription)
            }
        })
    }
    
    func decorateCollectonCell(cell: PhotoCollectionViewCell, imagePath: String){
        let url = NSURL(string: imagePath)!
        
        dispatch_async(dispatch_get_main_queue(), {
            if let image = self.imageCache.imageWithIdentifier(url.lastPathComponent){
                cell.photoView.image = image
            }
        })
    }
    
}
