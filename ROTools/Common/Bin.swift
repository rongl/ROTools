//
//  Bin.swift
//  ROTools
//
//  Created by RonGL on 15/10/12.
//  Copyright © 2015年 RonGL. All rights reserved.
//

import Foundation
import AppKit

class Bin{
    
    /**
    返回项目Assets.xcassets目录路径
    */
    class func getAssetsPath() -> NSString? {
        do {
            if let workspacePath = self.getWorkspacePath() {
                for item in (try NSFileManager.defaultManager().subpathsOfDirectoryAtPath(workspacePath as String)){
                    if item.hasSuffix("Assets.xcassets") {
                        return NSString(string:workspacePath.stringByAppendingPathComponent(item))
                    }
                }
            }
        } catch {
            // print("见鬼了！")
        }
        return nil
    }
    
    /**
    返回项目根目录路径
    */
    class func getWorkspacePath() -> NSString? {
        var workspace: AnyObject? = nil
        if let c = (NSClassFromString("IDEWorkspaceWindowController") as? AnyObject)?.valueForKey("workspaceWindowControllers") as? NSArray {
            for controller in c {
                
                let window: AnyObject? = controller.valueForKey("window")
                let keyWindow = NSApp.keyWindow
                if let w: AnyObject = window, let kw: AnyObject = keyWindow as? AnyObject {
                    if true == w.isEqual(kw) {
                        workspace = controller.valueForKey("_workspace")
                        break
                    }
                }
            }
            if let workspacePath = workspace?.valueForKey("representingFilePath")?.valueForKey("_pathString") as? NSString {
                return workspacePath.stringByDeletingLastPathComponent
            }
        }
        return nil
    }
    
    /**
    图片按指定Size缩小,保存到对指定的目录下.并根据Json的参数命名
    
    - parameter img:        源图片
    - parameter attributes: Json数据,用于指定图片Size与命名
    - parameter savePath:   目录保存目录
    
    - returns: <#return value description#>
    */
    class func resizeImage(img:NSImage, attributes: NSMutableDictionary, savePath: NSString) -> NSString?{
        if let size = attributes["size"] as? String{
            let sizeUnitArray = size.componentsSeparatedByString("x");
            if sizeUnitArray.count == 2 {
                if let sizeUnitWidth = Double(sizeUnitArray[0]),
                let sizeUnitHeight = Double(sizeUnitArray[1]),
                let scale = attributes["scale"] as? String,
                let scaleUnit = scale.componentsSeparatedByString("x").first?.doubleValue,
                let idiom = attributes["idiom"] as? String{
                    let realSizeWidth = sizeUnitWidth * scaleUnit
                    let realSizeHeight = sizeUnitHeight * scaleUnit
                    
                    var imgName = ""
                    
                    if let _imgName = attributes["filename"] as? String {
                        imgName = _imgName
                    }
                    
                    if imgName == "" {
                        imgName = "Icon-\(idiom)-\(size).png"
                        if scaleUnit != 1.0 {
                            imgName = "Icon-\(idiom)-\(size)@\(scale).png"
                        }
                    }
                    
                    
                    guard let bitMap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(realSizeWidth), pixelsHigh: Int(realSizeHeight), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: NSCalibratedRGBColorSpace, bytesPerRow: 0, bitsPerPixel: 0) else{
                        return nil;
                        
                    }
                    NSGraphicsContext.saveGraphicsState()
                    NSGraphicsContext.setCurrentContext(NSGraphicsContext(bitmapImageRep: bitMap))
                    img.drawInRect(NSRect(x: 0, y: 0, width: realSizeWidth, height: realSizeHeight), fromRect: NSZeroRect, operation: .CompositeCopy, fraction: 1.0)
                    NSGraphicsContext.restoreGraphicsState()
                    
                    if let data = bitMap.representationUsingType(.NSPNGFileType, properties: NSDictionary() as! [String : AnyObject]) {
                        if data.writeToFile(savePath.stringByAppendingPathComponent(imgName) as String, atomically: true) {
                            return imgName
                        }
                    }

                }
            }
        }
        
        return nil
    }
}
