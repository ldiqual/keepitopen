//
//  Utils.swift
//  KeepItOpen
//
//  Created by Loïs Di Qual on 5/13/15.
//  Copyright (c) 2015 Scoop. All rights reserved.
//

import UIKit
import Crashlytics

extension UITextField {
    func localize() {
        placeholder = NSLocalizedString(placeholder!, comment: "")
    }
}

extension UITextView {
    func localize() {
        text = NSLocalizedString(text!, comment: "")
    }
}

extension UILabel {
    func localize() {
        text = NSLocalizedString(text!, comment: "")
    }
}

extension UIButton {
    func localize() {
        let title = NSLocalizedString(titleForState(.Normal)!, comment: "")
        setTitle(title, forState: .Normal)
    }
}

extension UISegmentedControl {
    func localize() {
        for index in 0...numberOfSegments - 1 {
            setTitle(titleForSegmentAtIndex(index)!.localize(), forSegmentAtIndex: index)
        }
    }
}

extension UIViewController {
    func localizeTitle() {
        navigationItem.title = navigationItem.title!.localize()
    }
    func localizeLeftButton() {
        navigationItem.leftBarButtonItem!.title = navigationItem.leftBarButtonItem!.title!.localize()
    }
    func localizeRightButton() {
        navigationItem.rightBarButtonItem!.title = navigationItem.rightBarButtonItem!.title!.localize()
    }
}

extension String {
    func localize() -> String {
        return NSLocalizedString(self, comment: "")
    }
}

func CLS_LOG_SWIFT( _ format: String = "", _ args:[CVarArgType] = [], file: String = __FILE__, function: String = __FUNCTION__, line: Int = __LINE__) {
    #if DEBUG
        CLSNSLogv("\(file.lastPathComponent.stringByDeletingPathExtension).\(function) line \(line) $ \(format)", getVaList(args))
    #else
        CLSLogv("\(file.lastPathComponent.stringByDeletingPathExtension).\(function) line \(line) $ \(format)", getVaList(args))
    #endif
}
