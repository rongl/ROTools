//
//  extension.swift
//  ROTools
//
//  Created by RonGL on 15/9/23.
//  Copyright © 2015年 RonGL. All rights reserved.
//

import Foundation
import Cocoa
import AppKit


// 扩展String,使其支持NSString相关属性与方法
extension String {
    func stringByAppendingPathComponent(string:String) -> String{
        return NSString(string: self).stringByAppendingPathComponent(string);
    }
    
    var stringByDeletingLastPathComponent:String{
        get{
            return NSString(string: self).stringByDeletingLastPathComponent;
        }
    }
    
    var doubleValue:Double {
        get{
            return NSString(string: self).doubleValue
        }
    }
}

extension NSTextField {
    convenience init(x:Int, y:Int, width:Int, height:Int, labelText:String){
        self.init(frame: NSRect(x: x, y: y, width: width, height: height))
        self.cell?.stringValue = labelText
        self.cell?.bezeled = false
        self.cell?.editable = false
        self.cell?.selectable = false
        self.cell?.bordered  = false
        self.cell?.alignment = NSTextAlignment.Left
        self.backgroundColor = NSColor.clearColor()
    }
    
    convenience init(x:Int, y:Int, width:Int, labelText:String){
        self.init(x:x, y:y, width:width, height:18, labelText:labelText)
    }
    
    
    convenience init(x:Int, y:Int, width:Int, height:Int, inputText:String?){
        self.init(frame: NSRect(x: x, y: y, width: width, height: height))
        if let text = inputText {
            self.cell?.title = text
        }
        self.cell?.bordered  = false
        self.cell?.alignment = NSTextAlignment.Left
    }
    
    convenience init(x:Int, y:Int, width:Int, inputText:String?){
        self.init(x:x, y:y, width:width, height:18, inputText:inputText)
    }
    
    convenience init(x:Int, y:Int, width:Int, numberInputText:String?){
        self.init(x:x, y:y, width:width, height:18, inputText:numberInputText)
        let numberFormatter = NSNumberFormatter()
        numberFormatter.minimum = 1
        numberFormatter.maximum = 2560
        self.cell?.formatter = numberFormatter
    }
}

extension NSButton{
    convenience init(x:Int, y:Int, width:Int, height:Int, switchTitle:String?, state:Bool=true){
        self.init(frame:NSRect(x: x, y: y, width: width, height: height))
        self.setButtonType(.SwitchButton)
        if let title = switchTitle {
            self.title = title
        }
        self.state = Int(state)
    }
    
    convenience init(x:Int, y:Int, width:Int, switchTitle:String?, state:Bool=true){
        self.init(x:x, y:y, width:width, height:18, switchTitle:switchTitle, state:state)
    }
    
    convenience init(x:Int, y:Int, width:Int, height:Int, buttonTitle:String){
        self.init(frame:NSRect(x: x, y: y, width: width, height: height))
        self.title = buttonTitle
        self.setButtonType(.MomentaryPushInButton)
    }
    
    convenience init(x:Int, y:Int, width:Int, buttonTitle:String){
        self.init(x:x, y:y, width:width, height:18, buttonTitle:buttonTitle)
    }
}





