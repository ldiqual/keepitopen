//
//  AppDelegate.swift
//  KeepItOpen
//
//  Created by Loïs Di Qual on 4/30/15.
//  Copyright (c) 2015 Scoop. All rights reserved.
//

import UIKit
import ISHPermissionKit
import Bugsnag

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        Bugsnag.startBugsnagWithApiKey("af4463b4faf22e0527493fa0940ce339")
        GAI.sharedInstance().trackUncaughtExceptions = false
        GAI.sharedInstance().dispatchInterval = 30
        GAI.sharedInstance().trackerWithTrackingId("UA-63132945-1")
        GMSServices.provideAPIKey("AIzaSyBxf_NVKp4cpUVsRgDwkPulNho3nJVOkO0")
        return true
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        NSNotificationCenter.defaultCenter().postNotificationName(LocationNotificationReceived, object: notification)
    }
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        NSNotificationCenter.defaultCenter().postNotificationName(ISHPermissionNotificationApplicationDidRegisterUserNotificationSettings, object: self)
    }
}

