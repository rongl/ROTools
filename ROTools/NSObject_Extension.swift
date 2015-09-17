//
//  NSObject_Extension.swift
//
//  Created by RonGL on 15/9/17.
//  Copyright © 2015年 RonGL. All rights reserved.
//

import Foundation

extension NSObject {
    class func pluginDidLoad(bundle: NSBundle) {
        let appName = NSBundle.mainBundle().infoDictionary?["CFBundleName"] as? NSString
        if appName == "Xcode" {
        	if sharedPlugin == nil {
        		sharedPlugin = ROTools(bundle: bundle)
        	}
        }
    }
}