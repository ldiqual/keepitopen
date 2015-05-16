//
//  OnboardingVC.swift
//  KeepItOpen
//
//  Created by Loïs Di Qual on 5/13/15.
//  Copyright (c) 2015 Scoop. All rights reserved.
//

import Foundation
import FlatUIKit

class OnboardingVC: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var actionButton: FUIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        actionButton.backgroundColor = UIColor.clearColor()
        actionButton.buttonColor     = Color.blueColor
        actionButton.cornerRadius    = 4.0
        actionButton.addTarget(self, action: "onActionButtonPressed:", forControlEvents: .TouchUpInside)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .Default
    }
    
    @objc
    private func onActionButtonPressed(button: UIButton) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
