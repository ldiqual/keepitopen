//
//  OnboardingVC.swift
//  KeepItOpen
//
//  Created by Loïs Di Qual on 5/13/15.
//  Copyright (c) 2015 Scoop. All rights reserved.
//

import UIKit
import class FlatUIKit.FUIButton
import ISHPermissionKit
import PromiseKit

class OnboardingVC: GAITrackedViewController {
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var detailsTextView: UITextView!
    @IBOutlet private weak var actionButton: FUIButton!
    
    static let locationPermissionRequest = ISHPermissionRequest(forCategory: .LocationAlways)
    static let notificationPermissionRequest = ISHPermissionRequest(forCategory: .NotificationLocal)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        detailsTextView.localize()
        
        actionButton.backgroundColor = UIColor.clearColor()
        actionButton.buttonColor     = Color.blueColor
        actionButton.cornerRadius    = 4.0
        actionButton.addTarget(self, action: "onActionButtonPressed:", forControlEvents: .TouchUpInside)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .Default
    }
    
	private func requestPermissions() {
        Promise<Void> { fulfill, reject in
            OnboardingVC.locationPermissionRequest.requestUserPermissionWithCompletionBlock { request, state, error in
                if error != nil || state != .Authorized {
                    let error = error ?? NSError(domain: "com.loisdiqual.keepitopen", code: 500, userInfo: [NSLocalizedDescriptionKey: "User has denied location tracking"])
                    reject(error)
                    return
                }
                fulfill()
            }
        }.then {
            return Promise<Void> { fulfill, reject in
                OnboardingVC.notificationPermissionRequest.requestUserPermissionWithCompletionBlock { request, state, error in
                    if error != nil || state != .Authorized {
                        let error = error ?? NSError(domain: "com.loisdiqual.keepitopen", code: 500, userInfo: [NSLocalizedDescriptionKey: "User has denied notifications"])
                        reject(error)
                        return
                    }
                    fulfill()
                }
            }
        }.then {
            self.dismissViewControllerAnimated(true, completion: nil)
        }.catch { error in
            CLS_LOG_SWIFT("Couldn't get the appropriate permissions: \(error)")
            let alertController = UIAlertController(title: "permission_prompt_title".localize(), message: "permission_prompt_details".localize(), preferredStyle: .Alert)
            
            // Ignore
            alertController.addAction(UIAlertAction(title: "permission_prompt_ignore".localize(), style: .Cancel) { _ in
                self.dismissViewControllerAnimated(true, completion: nil)
            })
            
            // Go to settings
            alertController.addAction(UIAlertAction(title: "permission_prompt_settings".localize(), style: .Default) { _ in
                UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
            })
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    @objc
    private func onActionButtonPressed(button: UIButton) {
        requestPermissions()
    }
}
