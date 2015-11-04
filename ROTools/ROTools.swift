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



class ROTools: NSObject {
    var bundle: NSBundle
    var iconImportwindow : IconImportWindowController!
    lazy var center = NSNotificationCenter.defaultCenter()
    lazy var importType:NSArray?  = {
        if let importTypePath = self.bundle.pathForResource("importType", ofType: "plist") {
            return NSArray(contentsOfFile:importTypePath)
        }
        return nil
    }()

    
    init(bundle: NSBundle) {
        self.bundle = bundle
        super.init()
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.createMenuItems()
        })
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
            
            
            let importIconsMenuItem = NSMenuItem(title:"Import Icons", action:"importIconsAction", keyEquivalent:"")
            importIconsMenuItem.target = self
            //importIconsMenuItem.enabled = false
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
        if let originalImageUrl = getOriginalImageUrl(), let workspacePath = Bin.getWorkspacePath(), let iconFolderPath = getIconFolderPath(workspacePath) {
                let originalImage = NSImage(contentsOfURL: originalImageUrl)
            
                let iconJSONPath = iconFolderPath.stringByAppendingPathComponent("Contents.json")
                guard let jsonDict = getJSONDict(iconJSONPath) else {
                    return ;
                }
            
                for singleImage in jsonDict["images"] as! NSArray {
                    if let attributes = singleImage as? NSMutableDictionary,
                        let resultName = Bin.resizeImage(originalImage!, attributes: attributes, savePath: iconFolderPath){
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
    
    func importIconsAction(){
        if self.iconImportwindow == nil {
            self.iconImportwindow = IconImportWindowController(windowNibName: "IconImportWindowController")
        }
        if self.importType != nil,
            let assetsPath = Bin.getAssetsPath() {
            self.iconImportwindow.assetsPath = assetsPath
            self.iconImportwindow.importType  = self.importType!
            self.iconImportwindow.showWindow(self.iconImportwindow)
        }
        
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
    错误提示,用于测试.
    
    - parameter string: string description
    */
    func showError(string:String?) {
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
            return  openPanel.URL
        }
        return nil
    }
    

    
   
}
