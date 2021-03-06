//
//  ViewController.swift
//  KeepItOpen
//
//  Created by Loïs Di Qual on 4/30/15.
//  Copyright (c) 2015 Scoop. All rights reserved.
//

import UIKit
import CoreLocation
import class FlatUIKit.FUIButton

let LocationNotificationReceived = "LocationNotificationReceived"

class ViewController: GAITrackedViewController, CLLocationManagerDelegate {

    @IBOutlet private weak var titleLabel:    UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var mapView:       GMSMapView!
    @IBOutlet private weak var actionButton:  FUIButton!
    
    private var locationManager: CLLocationManager!
    
    enum LocationState: String {
        case Inactive           = "inactive"
        case WaitingForLocation = "waitingForLocation"
        case Active             = "active"
    }
    
    enum State: String {
        case Inactive = "inactive"
        case Active   = "active"
        case Warning  = "warning"
    }
    
    enum MapState: String {
        case Reduced  = "reduced"
        case Expanded = "expanded"
    }
    
    private var isMaskInitted: Bool = false
    private var viewDidAppearOnce = false
    
    private var locationState: LocationState = .Inactive {
        didSet {
            CLS_LOG_SWIFT("Location state: \(oldValue.rawValue) => \(locationState.rawValue)")
        }
    }
    private var mapState: MapState = .Reduced {
        didSet {
            CLS_LOG_SWIFT("Map state: \(oldValue.rawValue) => \(mapState.rawValue)")
        }
    }
    
    private var state: State = .Inactive {
        didSet {
            CLS_LOG_SWIFT("State: \(oldValue.rawValue) => \(state.rawValue)")
        }
    }
    
    private var anchorLocation: CLLocation?
    private var regionBeingMonitored: CLRegion?
    private var cardMarker: GMSMarker?
    
    private var shouldShowOnboarding: Bool {
        return OnboardingVC.locationPermissionRequest.permissionState() != .Authorized ||
               OnboardingVC.notificationPermissionRequest.permissionState() != .Authorized
    }
    
    private let RegionRadius: CLLocationDistance = 30
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        actionButton.backgroundColor = UIColor.clearColor()
        actionButton.buttonColor     = Color.yellowColor
        actionButton.cornerRadius    = 5
        actionButton.setTitleColor(Color.brownColor, forState: .Normal)
        actionButton.addTarget(self, action: "actionButtonPressed:", forControlEvents: .TouchUpInside)
        
        mapView.myLocationEnabled = true
        mapView.layer.mask        = CAShapeLayer()
        mapView.layer.borderColor = Color.brownColor.CGColor
        mapView.layer.borderWidth = 4
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        
        if CLLocationManager.authorizationStatus() == .AuthorizedAlways {
            locationManager.startUpdatingLocation()
        }
        
        updateUI(animated: false)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onApplicationDidEnterBackground:", name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onApplicationWillEnterForeground:", name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: LocationNotificationReceived, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        
        if !viewDidAppearOnce && shouldShowOnboarding {
            let identifier   = UIScreen.mainScreen().bounds.height < 600 ? "SmallOnboardingVC" : "OnboardingVC"
            let onboardingVC = storyboard!.instantiateViewControllerWithIdentifier(identifier) as! OnboardingVC
            presentViewController(onboardingVC, animated: true, completion: nil)
        }
        
        viewDidAppearOnce = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onLocalNotificationReceived:", name: LocationNotificationReceived, object: nil)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    private var reducedPath: CGPath {
        return maskPath(false)
    }
    
    private var expandedPath: CGPath {
        return maskPath(true)
    }
    
    private func maskPath(expanded: Bool) -> CGPath {
        let mapViewFrame = mapView.frame
        let hypotenuse   = sqrt(pow(mapViewFrame.width, 2) + pow(mapViewFrame.height, 2))
        let circleRadius = expanded ? hypotenuse / 2 : min(mapViewFrame.height / 2 - 8, mapViewFrame.width * 1 / 3)
        let center       = CGPointMake(mapViewFrame.width / 2, mapViewFrame.height / 2)
        let path         = UIBezierPath(arcCenter: center, radius: circleRadius, startAngle: 0, endAngle: 2.0 * CGFloat(M_PI), clockwise: true).CGPath
        return path
    }
    
    override func viewDidLayoutSubviews() {
        if !isMaskInitted {
            (mapView.layer.mask as! CAShapeLayer).path = state == .Inactive ? reducedPath : expandedPath
            isMaskInitted = true
        }
    }
    
    private func updateUI(animated: Bool = true) {
        CLS_LOG_SWIFT("Updating UI for state \(state.rawValue)")
        
        if state == .Inactive {
            mapView.clear()
            cardMarker = nil
            mapView.userInteractionEnabled = false
            self.view.backgroundColor = Color.blueColor
            actionButton.setTitle("drop_card".localize(), forState: .Normal)
            subtitleLabel.text = "subtitle_inactive".localize()
        }
        else if state == .Active {
            mapView.userInteractionEnabled = true
            self.view.backgroundColor = Color.blueColor
            actionButton.setTitle("pickup_card".localize(), forState: .Normal)
            subtitleLabel.text = "subtitle_active".localize()
        }
        else if state == .Warning {
            mapView.userInteractionEnabled = true
            self.view.backgroundColor = Color.redColor
            actionButton.setTitle("pickup_card".localize(), forState: .Normal)
            subtitleLabel.text = "subtitle_warning".localize()
        }
        
        if animated {
            let animation = CABasicAnimation(keyPath: "path")
            animation.fillMode = kCAFillModeForwards
            animation.removedOnCompletion = false
            animation.fromValue = state == .Inactive ? expandedPath : reducedPath
            animation.toValue   = state == .Inactive ? reducedPath : expandedPath
            animation.duration  = 0.2
            (mapView.layer.mask as! CAShapeLayer).addAnimation(animation, forKey: "path")
        }
    }
    
    // MARK: - Events
    
    @objc
    private func actionButtonPressed(button: UIButton) {
        CLS_LOG_SWIFT("Action button pressed while state was \(state.rawValue)")
        
        if state == .Active {
            stopMonitoringRegion()
            state = .Inactive
            updateUI()
            return
        }
        
        if state == .Warning {
            state = .Inactive
            updateUI()
            return
        }
            
        locationManager.requestAlwaysAuthorization()
        
        let notificationSettings = UIUserNotificationSettings(forTypes: UIUserNotificationType.Sound | UIUserNotificationType.Alert, categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)

        if let location = locationManager.location {
            onAnchorLocationDetermined(location)
        }
        else {
            locationManager.startUpdatingLocation()
            state = .Active
            locationState = .WaitingForLocation
        }
        
        updateUI()
    }
    
    @objc
    private func onLocalNotificationReceived(notification: NSNotification) {
        let localNotification = notification.object as! UILocalNotification
        CLS_LOG_SWIFT("Got local notification: \(localNotification)")
    }
    
    @objc
    private func onApplicationDidEnterBackground(notification: NSNotification) {
        if state == .Inactive {
            CLS_LOG_SWIFT("Stopping location updates")
            locationManager.stopUpdatingLocation()
        }
    }
    
    @objc
    private func onApplicationWillEnterForeground(notification: NSNotification) {
        if presentedViewController == nil && state != .Active {
            CLS_LOG_SWIFT("Starting location updates")
            locationManager.startUpdatingLocation()
        }
    }
    
    // MARK: - Location
    
    private func onAnchorLocationDetermined(location: CLLocation) {
        CLS_LOG_SWIFT("Anchor location: \(location)")
    	anchorLocation = location
    	regionBeingMonitored = CLCircularRegion(center: anchorLocation!.coordinate, radius: RegionRadius, identifier: "myCardRegion")
    	locationManager.stopUpdatingLocation()
    	locationManager.startMonitoringForRegion(regionBeingMonitored)
        
        locationState = .Inactive
    	state = .Active
        
        cardMarker = GMSMarker(position: location.coordinate)
        cardMarker!.appearAnimation = kGMSMarkerAnimationPop
        cardMarker!.title = "My Card"
        cardMarker!.map = mapView
        mapView.selectedMarker = cardMarker
    }
    
    private func onLocationDeterminedInWarningState(location: CLLocation) {
        let padding: CGFloat = 30.0
        let bounds = GMSCoordinateBounds(coordinate: location.coordinate, coordinate: cardMarker!.position)
        let cameraPosition = mapView.cameraForBounds(bounds, insets: UIEdgeInsetsMake(padding, padding, padding, padding))
        mapView.animateToCameraPosition(cameraPosition)
        locationState = .Active
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        let location = locations[0] as! CLLocation
        if locationState == .WaitingForLocation {
            if state == .Active {
                onAnchorLocationDetermined(location)
            }
            else if state == .Warning {
                onLocationDeterminedInWarningState(location)
            }
        }
        if state == .Inactive {
            mapView.camera = GMSCameraPosition.cameraWithTarget(location.coordinate, zoom: 15)
        }
    }
    
    // MARK: - Region Monitoring
    
    private func stopMonitoringRegion() {
        CLS_LOG_SWIFT("Stopping region monitoring")
        
        if let regionBeingMonitored = regionBeingMonitored {
            locationManager.stopMonitoringForRegion(regionBeingMonitored)
        }
        regionBeingMonitored = nil
        
        if CLLocationManager.authorizationStatus() == .AuthorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(manager: CLLocationManager!, didExitRegion region: CLRegion!) {
        
        if regionBeingMonitored == nil {
            CLS_LOG_SWIFT("Ignoring region exit: \(region)")
            return
        }
        
        CLS_LOG_SWIFT("Went out of region \(region)")
        
        locationState = .WaitingForLocation
        state = .Warning
        updateUI()
        locationManager.startUpdatingLocation()
        
        let notification = UILocalNotification()
        notification.alertTitle = "Don't forget your card!"
        notification.alertBody  = "Hey you! Don't forget your credit card!"
        notification.soundName  = UILocalNotificationDefaultSoundName
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
        
        stopMonitoringRegion()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}

