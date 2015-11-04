//
//  iItem.swift
//  ROTools
//
//  Created by RonGL on 15/9/23.
//  Copyright © 2015年 RonGL. All rights reserved.
//

import Foundation

struct iItem{
    var imageUrl:NSURL
    var fileName:String!
    var configs:[iItemConfig]!
    init(url:NSURL, configs:[iItemConfig]){
        self.imageUrl = url
        self.configs = configs
        fileName = url.URLByDeletingPathExtension?.lastPathComponent
    }
    mutating func setFileName(name:String) {
        self.fileName = name
    }
    
    mutating func setConfig(config:iItemConfig,forIndex index:Int) {
        if self.configs.count > index {
            self.configs[index] = config
        }
    }
    
    mutating func setConfigForIndex(index:Int,byHeight height:Int) {
        if self.configs.count > index {
            self.configs[index].setUnitHieht(height)
        }
    }
    
    mutating func setConfigForIndex(index:Int,byWdith width:Int) {
        if self.configs.count > index {
            self.configs[index].setUnitWidth(width)
        }
    }
    
    mutating func setConfigForIndex(index:Int,switchSizeStateForIndex sIndex:Int) {
        if self.configs.count > index {
            self.configs[index].setSwitchSizeStateForKey(sIndex)
        }
        
    }
}




struct iItemConfig{
    var type:iItemType
    var url:NSURL?
    var unitWidth = 0
    var unitHeight = 0
    var size = [1:true,2:true,3:true]
    
    init(type:iItemType,unitWidth:Int,unitHeight:Int,size:[Int:Bool],url:NSURL?){
        self.type = type
        self.unitWidth = unitWidth
        self.unitHeight = unitHeight
        self.size = size
        self.url = url
    }
    
    init(type:iItemType,unitWidth:Int,unitHeight:Int){
        self.init(type:type,unitWidth:unitWidth,unitHeight:unitHeight,size:[1:true,2:true,3:true],url:nil)
    }
    
    init(type:iItemType,unit:Int){
        self.init(type:type,unitWidth:unit,unitHeight:unit)
    }
    
    mutating func setUrl(url:NSURL) {
        self.url = url
    }
    
    mutating func setUnitWidth(width:Int) {
        self.unitWidth = width
    }
    
    mutating func setUnitHieht(height:Int) {
        self.unitHeight = height
    }
    
    mutating func setSwitchSizeStateForKey(key:Int) {
        if let val = self.size[key] {
            self.size.updateValue(!val, forKey: key)
        }
    }
    
}



enum iItemType:String {
    case Universal = "universal"
    case IPhone = "iphone"
    case Ipad = "ipad"
    case Watch = "watch"
    case Mac = "mac"
}