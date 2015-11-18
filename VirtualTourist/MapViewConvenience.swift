//
//  MapViewConvenience.swift
//  VirtualTourist
//
//  Created by X.I. Losada on 13/11/15.
//  Copyright © 2015 XiLosada. All rights reserved.
//

import Foundation
import MapKit

extension MKMapView {
    
    func showCustomPin(pin: Pin){
        let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
        setRegion(MKCoordinateRegion(center: coordinate, span: span), animated: true)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        addAnnotation(annotation)
    }
    
}