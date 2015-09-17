//
//  ROTools.swift
//
//  Created by RonGL on 15/9/17.
//  Copyright © 2015年 RonGL. All rights reserved.
//  QQ: 33112486
//  Mail: rongl.gm@gmail.com
//

import AppKit

var sharedPlugin: ROTools?


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

class ROTools: NSObject {
    var bundle: NSBundle
    lazy var center = NSNotificationCenter.defaultCenter()

    init(bundle: NSBundle) {
        self.bundle = bundle
        super.init()
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.createMenuItems()
        })
        // center.addObserver(self, selector: Selector("createMenuItems"), name: NSApplicationDidFinishLaunchingNotification, object: nil)
    }

    deinit {
        //removeObserver()
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    
    func removeObserver() {
        //center.removeObserver(self)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    /**
    创建并显示到菜单栏上
    */
    func createMenuItems() {
        removeObserver()
        if let xCodeEdititem = NSApp.mainMenu!.itemWithTitle("Edit") {
            
            xCodeEdititem.submenu!.addItem(NSMenuItem.separatorItem())
            
            let menuItemRoot = NSMenuItem();
            menuItemRoot.title = "ROTools"
            xCodeEdititem.submenu!.addItem(menuItemRoot)
            
            let mainMenus = NSMenu();
            menuItemRoot.submenu = mainMenus
            
            let appIconMakerMenuItem = NSMenuItem(title:"AppIcon Maker", action:"appIconMakerAction", keyEquivalent:"")
            appIconMakerMenuItem.target = self
            mainMenus.addItem(appIconMakerMenuItem)
            
            
            let importIconsMenuItem = NSMenuItem(title:"Import Icons", action:"", keyEquivalent:"")
            importIconsMenuItem.target = self
            importIconsMenuItem.enabled = false
            mainMenus.addItem(importIconsMenuItem)
            
            
            let newGroupMenuItem = NSMenuItem(title:"New Group", action:"", keyEquivalent:"")
            newGroupMenuItem.target = self
            newGroupMenuItem.enabled = false
            mainMenus.addItem(newGroupMenuItem)
           
        }
    }

    /**
    点击时响应
    */
    func appIconMakerAction() {
        if let originalImageUrl = getOriginalImageUrl(), let workspacePath = getWorkspacePath(), let iconFolderPath = getIconFolderPath(workspacePath) {
                let originalImage = NSImage(contentsOfURL: originalImageUrl)
            
                let iconJSONPath = iconFolderPath.stringByAppendingPathComponent("Contents.json")
                guard let jsonDict = getJSONDict(iconJSONPath) else {
                    return ;
                }
            
                for singleImage in jsonDict["images"] as! NSArray {
                    if let attributes = singleImage as? NSMutableDictionary,
                        let resultName = resizeImage(originalImage!, attributes: attributes, savePath: iconFolderPath){
                         attributes["filename"] = resultName
                    }
                    
                }
            
                do{
                    try NSJSONSerialization.dataWithJSONObject(jsonDict, options: .PrettyPrinted).writeToFile(iconJSONPath, options: .AtomicWrite)
                } catch {
                    // print("见鬼了！")
                }

            
        }
    }
    
    /**
    图片按指定Size缩小,保存到对指定的目录下.并根据Json的参数命名
    
    - parameter img:        源图片
    - parameter attributes: Json数据,用于指定图片Size与命名
    - parameter savePath:   目录保存目录
    
    - returns: <#return value description#>
    */
    func resizeImage(img:NSImage, attributes: NSMutableDictionary, savePath: NSString) -> NSString?{
        if let size = attributes["size"] as? String,
            let sizeUnit = size.componentsSeparatedByString("x").first?.doubleValue,
            let scale = attributes["scale"] as? String,
            let scaleUnit = scale.componentsSeparatedByString("x").first?.doubleValue,
            let idiom = attributes["idiom"] as? String{
                
                let realSize = sizeUnit * scaleUnit

                var imgName = "Icon-\(idiom)-\(size).png"
                if scaleUnit != 1.0 {
                    imgName = "Icon-\(idiom)-\(size)@\(scale).png"
                }
                
                guard let bitMap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(realSize), pixelsHigh: Int(realSize), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: NSCalibratedRGBColorSpace, bytesPerRow: 0, bitsPerPixel: 0) else{
                    return nil;
                    
                }
                NSGraphicsContext.saveGraphicsState()
                NSGraphicsContext.setCurrentContext(NSGraphicsContext(bitmapImageRep: bitMap))
                img.drawInRect(NSRect(x: 0, y: 0, width: realSize, height: realSize), fromRect: NSZeroRect, operation: .CompositeCopy, fraction: 1.0)
                NSGraphicsContext.restoreGraphicsState()
                
                if let data = bitMap.representationUsingType(.NSPNGFileType, properties: NSDictionary() as! [String : AnyObject]) {
                    if data.writeToFile(savePath.stringByAppendingPathComponent(imgName) as String, atomically: true) {
                        return imgName
                    }
                }
        }
        
        return nil
    }
    
    
    /**
    Json解译
    
    - parameter jsonDictPath: Json路径
    
    - returns: 返回一个字典的可选对象
    */
    func getJSONDict(jsonDictPath: NSString) -> NSDictionary? {
        if let data = NSData(contentsOfFile: jsonDictPath as String) {
            return (try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers)) as? NSDictionary
        }
        return nil
    }
    
    /**
    返回AppIcon的目录路径
    
    - parameter workspacePath: 项目目录路径
    
    - returns: 返回AppIcon的目录路径
    */
    func getIconFolderPath(workspacePath: NSString) -> NSString? {
        do {
            for item in (try NSFileManager.defaultManager().subpathsOfDirectoryAtPath(workspacePath as String)){
                if item.hasSuffix("Assets.xcassets") {
                    return NSString(string:workspacePath.stringByAppendingPathComponent(item).stringByAppendingPathComponent("AppIcon.appiconset"))
                }
            }
        } catch {
           // print("见鬼了！")
        }
        return nil
    }
    
    /**
    返回项目目录路径
    */
    func getWorkspacePath() -> NSString? {
        var workspace: AnyObject? = nil
        if let c = (NSClassFromString("IDEWorkspaceWindowController") as? AnyObject)?.valueForKey("workspaceWindowControllers") as? NSArray {
            for controller in c {
                print(controller);
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
    错误提示,用于测试.
    
    - parameter string: <#string description#>
    */
    func showError(string:String="") {
        let error = NSError(domain: "Something went wrong[\(string)] :(", code:0, userInfo:nil)
        NSAlert(error: error).runModal()
    }
    
    
    
    /**
    弹出图片选择窗,
    
    - returns: 返回一张需设置AppIcon的图片
    */
    func getOriginalImageUrl() -> NSURL? {
        let openPanel = NSOpenPanel()
        openPanel.allowedFileTypes = ["png"]
        openPanel.canChooseFiles = true
        openPanel.canCreateDirectories = false
        openPanel.allowsMultipleSelection = false
        
        let result = openPanel.runModal()
        if (NSFileHandlingPanelOKButton == result) {
            print(openPanel.URL)
            return  openPanel.URL
        }
        return nil
    }
    

    
   
}
