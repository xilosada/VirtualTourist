//
//  ViewControllerConvenience.swift
//  VirtualTourist
//
//  Created by X.I. Losada on 18/11/15.
//  Copyright © 2015 XiLosada. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    
    // MARK Convenience: show alerts and activity indicators
    
    func showError(message:String){
        showAlert("Error", message: message)
    }
    
    func showAlert(title:String,message:String, handler: ((UIAlertAction) -> Void)? =  nil){
        dispatch_async(dispatch_get_main_queue(),{
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: handler))
            self.presentViewController(alert, animated: true, completion: nil)
        })
    }
    
    func showActivityIndicator()->UIActivityIndicatorView{
        let activityView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        activityView.center = self.view.center
        activityView.startAnimating()
        view.addSubview(activityView)
        return activityView
    }
    
    func releaseActivityIndicator(activityIndicatorView:UIActivityIndicatorView){
        dispatch_async(dispatch_get_main_queue(),{
            activityIndicatorView.stopAnimating()
            activityIndicatorView.removeFromSuperview()
        })
    }
}