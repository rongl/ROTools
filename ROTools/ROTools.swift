//
//  ROTools.swift
//
//  Created by RonGL on 15/9/17.
//  Copyright © 2015年 RonGL. All rights reserved.
//  QQ: 33112486
//  Mail: rongl.gm@gmail.com
//  Can't install
//  defaults read /Applications/Xcode.app/Contents/Info DVTPlugInCompatibilityUUID
//  tragets -> info -> DVTPlugInCompatibilityUUIDs
//

import AppKit
var sharedPlugin: ROTools?

struct PBXGroup {
    let name:String
    let isa:String
    let sourceTree:String
    var type:String
    let children:[String:String]
    let typeValue:String
    let replaceText:String
    let fullText:String
}

enum IgnoreFixGroupStructureMode {
    case AllIgnoreSubNode
    case IgnoreNode
    case Not
}

struct IgnoreFixGroupStructure {
    var paths:[String]
    var isBackUp:Bool
}

struct PBXGroupTree {
    let value : PBXGroup
    let key : String
    let path : String
    var nodes : [String:PBXGroupTree]!
}

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
    lazy var ignoreFixGroupStructure:IgnoreFixGroupStructure = {
        var ignore = IgnoreFixGroupStructure(paths: ["*xcassets","Products*","Pods*","Frameworks*"], isBackUp: true)
        if let workspacePath = Bin.getWorkspacePath(),
            let  xcodeprojPath = self.getXcodeprojPath(workspacePath){
                let ignoreFile = xcodeprojPath.stringByAppendingPathComponent("roIgnore.plist")
                if NSFileManager.defaultManager().fileExistsAtPath(ignoreFile) {
                    if let  data  = NSMutableDictionary(contentsOfFile: ignoreFile),
                        let _paths = data.objectForKey("paths"),
                        let _isBackUp = data.objectForKey("isBackUp"){
                        let paths = _paths as! [String]
                        let isBackUp = _isBackUp as! Bool
                        ignore = IgnoreFixGroupStructure(paths: paths, isBackUp: isBackUp)
                    }
                }else{
                    var data = NSMutableDictionary()
                    data.setValue(ignore.paths, forKeyPath: "paths")
                    data.setValue(ignore.isBackUp, forKeyPath: "isBackUp")
                    data.writeToFile(ignoreFile, atomically: false)
                }
                //if let  data  = NSMutableDictionary(contentsOfFile: ignoreFile) {
        }
        return ignore
    }() // = ["test03","*xcassets","Info.plist","Products*"]

    
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
        if let xCodeEdititem = NSApp.mainMenu!.itemWithTitle("Xcode") {
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
            
            let newGroupMenuItem = NSMenuItem(title:"Fix Group Structure", action:"fixGroupStructure", keyEquivalent:"")
            newGroupMenuItem.target = self
            //newGroupMenuItem.enabled = false
            mainMenus.addItem(newGroupMenuItem)
            
           
        }
    }
    
    func fixGroupStructure(){
        //var fileTextArray:[String]? = nil
        if let workspacePath = Bin.getWorkspacePath(),
            let  xcodeprojPath = getXcodeprojPath(workspacePath) {
                var structureTextArray:[String]? = nil
                let structureConfigPath = xcodeprojPath.stringByAppendingPathComponent("project.pbxproj")
                let fileManager = NSFileManager.defaultManager()
                if fileManager.fileExistsAtPath(structureConfigPath) {
                    if let data = NSData(contentsOfFile: structureConfigPath) {
                        let content = NSString(data: data, encoding: NSUTF8StringEncoding)
                        
//                        if let start = content?.rangeOfString("/* Begin PBXBuildFile section */"),
//                            let end = content?.rangeOfString("/* End PBXBuildFile section */"){
//                            let searchStart = start.location + start.length
//                                if let array =  content?.substringWithRange(NSMakeRange(searchStart, end.location-searchStart)).trim.componentsSeparatedByString("\n\t\t") {
//                                    fileTextArray = array
//                                }
//                        }
                        if let start = content?.rangeOfString("/* Begin PBXGroup section */"),
                            let end = content?.rangeOfString("/* End PBXGroup section */"){
                                let searchStart = start.location + start.length
                                if let array =  content?.substringWithRange(NSMakeRange(searchStart, end.location-searchStart)).trim.componentsSeparatedByString("\n\t\t};") {
                                    structureTextArray = array
                                }
                        }
                        
                        
                        if structureTextArray?.count > 0 {
                            //            let fileLists = transformationFileText(fileTextArray!)
                            if let structureLists = transformationStructureText(structureTextArray!),
                                let tree = makeTreeFormLists(structureLists, withTree: nil),
                                let rootTree = tree[""] ,
                                let rootTreeNodes = (rootTree as PBXGroupTree).nodes{
                                    // 如果没有配置文件.生成配置文件
                                    
                                    // 如果需要,则备份文件
                                    if ignoreFixGroupStructure.isBackUp {
                                        data.writeToFile("\(structureConfigPath).bak", atomically: false)
                                    }
                                    
                                    // 移动与修改配置文件
                                    var confString = content as! String
                                    fixGroupStructureAction(rootTreeNodes, rootPath: workspacePath as String, confString: &confString,confPath: structureConfigPath)
                            }
                        }
                        
                        
                    }
                }
                
        }
        
    }
    
//    func transformationFileText(array:[String]) -> [String:String]? {
//        var lists = [String:String]()
////        "571DC95F1BF5B09F002E0E29 /* AppDelegate.swift in Sources */ = {isa = PBXBuildFile; fileRef = 571DC95E1BF5B09F002E0E29 /* AppDelegate.swift */; };"
//        for text in array {
//            let arr = text.trim.componentsSeparatedByString(" ")
//            lists.updateValue(arr[14], forKey: arr[12])
//        }
//        if lists.count > 0 {
//            return lists
//        }
//        return nil
//    }
    
    func fixGroupStructureAction(_nodes:[String:PBXGroupTree]!, rootPath:String, inout confString:String,confPath:String){
        if let nodes = _nodes {
            for (_,node) in nodes {
                let path = node.path
                let matchStyle = checkIgnoreFixGroupStructure(path)
                if matchStyle == IgnoreFixGroupStructureMode.AllIgnoreSubNode {
                    continue
                }
                var action = false
                var manage:NSFileManager! = nil
                
                if node.value.type == "name" {
                    let originalText = node.value.fullText
                    let replaceText = node.value.replaceText
                    let changeText = replaceText.stringByReplacingOccurrencesOfString("name", withString: "path", options: NSStringCompareOptions.LiteralSearch, range: nil)
                    let newText = originalText.stringByReplacingOccurrencesOfString(replaceText, withString: changeText, options: NSStringCompareOptions.LiteralSearch, range: nil)
                    confString = confString.stringByReplacingOccurrencesOfString(originalText, withString: newText, options: NSStringCompareOptions.LiteralSearch, range: nil)
                    action = true
                    manage = NSFileManager.defaultManager()
                    action = true
                    do {
                        try NSString(string: confString).writeToFile(confPath, atomically: false, encoding:NSUTF8StringEncoding)
                        try manage.createDirectoryAtPath(rootPath.stringByAppendingPathComponent(node.path), withIntermediateDirectories: false, attributes: nil)
                        print(":::::::::: create dir Done!!!")
                    }catch {
                        print(":::::::::: create dir erro!!!")
                    }
                    
                }
                let children  = node.value.children
                if children.count > 0 {
                    if matchStyle != IgnoreFixGroupStructureMode.IgnoreNode {
                        for (key,name) in children {
                            if let subNodes = node.nodes, let _ = subNodes[key] {
                                // 这个是目录.进行下一步操作
                            }else {
                                let filePath = path.stringByAppendingPathComponent(name)
                                let fileMatchStyle = checkIgnoreFixGroupStructure(filePath)
                                if fileMatchStyle == IgnoreFixGroupStructureMode.Not {
                                    if action  {
                                        let toPath = rootPath.stringByAppendingPathComponent(filePath)
                                        var srcDirPath = rootPath.stringByAppendingPathComponent(path).stringByDeletingLastPathComponent
                                        var isMoved = false
                                        do {
                                            //.stringByAppendingPathComponent(name)
                                            var whileAction = true
                                            while(whileAction){
                                                let srcPath = srcDirPath.stringByAppendingPathComponent(name)
                                                if manage.fileExistsAtPath(srcPath){
                                                    try manage.moveItemAtPath(srcPath, toPath: toPath)
                                                    isMoved = true
                                                    whileAction = false
                                                }else if rootPath == srcDirPath {
                                                    whileAction = false
                                                }else{
                                                    srcDirPath =  srcDirPath.stringByDeletingLastPathComponent
                                                }
                                            }
                                            
                                        }catch {
                                            
                                        }
                                        if isMoved {
                                            print(":::::::::: move file Done")
                                        }else{
                                            print(":::::::::: move file Error")
                                        }
                                       
                                    }
                                }
                            }
                        }
                    }
                    fixGroupStructureAction(node.nodes, rootPath: rootPath,confString: &confString, confPath: confPath)
                }
            }
        }
    }
    
    func checkIgnoreFixGroupStructure(path:String) -> IgnoreFixGroupStructureMode{
        if self.ignoreFixGroupStructure.paths.count > 0 {
            for match in self.ignoreFixGroupStructure.paths {
                if match == path {
                    return .IgnoreNode
                }else{
                    let approximateMatch = match.componentsSeparatedByString("*")
                    if approximateMatch.count > 1 {
                        if approximateMatch[0] == "" && path.hasSuffix(approximateMatch.last!) {
                            return .IgnoreNode
                        }else if approximateMatch.last! == "" && path.hasPrefix(approximateMatch[0]) {
                            return .AllIgnoreSubNode
                        }
                    }
                }
            }
        }
        
        return .Not
    }
    
    func makeTreeFormLists( lists:[String:PBXGroup], withTree tree:PBXGroupTree!) -> [String:PBXGroupTree]! {
        if let _tree = tree {
            let children = _tree.value.children
            var subTree = [String:PBXGroupTree]()
            if children.count > 0  {
                let childrenKeys = Array(children.keys)
                for (key,value) in lists {
                    if childrenKeys.contains(key) {
                        let path = tree.path.stringByAppendingPathComponent(value.name)
                        var gTree = PBXGroupTree(value: value, key: key, path: path, nodes: nil)
                        gTree.nodes = makeTreeFormLists(lists, withTree: gTree)
                        subTree.updateValue(gTree, forKey: key)
                    }
                }
            }
            if subTree.count > 0 {
                return subTree
            }
        }else{
            var topTree = [String:PBXGroupTree]()
            var _lists:[String:PBXGroup] = lists
            for (key,value) in lists {
                if value.typeValue == "" && value.name == "" {
                    var _tree = PBXGroupTree(value: value, key: key, path: "", nodes: nil)
                    _lists.removeValueForKey(key)
                    _tree.nodes =  makeTreeFormLists(_lists, withTree: _tree)
                    topTree.updateValue(_tree, forKey: "")
                }
            }
            if topTree.count > 0 {
                return topTree;
            }
        }
        return nil
    }
    
    func transformationStructureText(array:[String]) -> [String:PBXGroup]? {
        var lists = [String:PBXGroup]()
//        571DC9521BF5B09F002E0E29 = {
//            isa = PBXGroup;
//            children = (
//                571DC95D1BF5B09F002E0E29 /* test03 */,
//                571DC95C1BF5B09F002E0E29 /* Products */,
//            );
//            sourceTree = \"<group>\";"
//        }
        for text in array {
            let textTrim = text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet());
            if textTrim == "" {
                continue
            }
            let arr = textTrim.componentsSeparatedByString("\n")
            if arr.count < 3 {
                continue
            }
            let fristLineText = arr[0].trim.replace("*").replace(" ")
            var fristLineTextArray = fristLineText.componentsSeparatedByString("/")
            var _key = ""
            var _name = ""
            if fristLineTextArray.count !=  3 {
                let fristLineTextArray = fristLineText.componentsSeparatedByString("=")
                if fristLineTextArray.count == 2 && fristLineTextArray[1] == "{" {
                    _key = fristLineTextArray[0]
                }else{
                    continue
                }
            }else{
                _key = fristLineTextArray[0]
                _name = fristLineTextArray[1]
            }
            var _isa = ""
            var _sourceTree = ""
            var _children = [String:String]()
            var _type = ""
            var _typeValue = ""
            var _isChildren = false
            var replaceText = ""
            for i in 1..<arr.count {
                let lineText = arr[i].replace("\n").replace("\t")
                if lineText == "children = (" {
                    _isChildren = true
                }else if lineText == ");" {
                    _isChildren = false
                }else if _isChildren {
                    let keyValue = lineText.replace("*").replace(" ").componentsSeparatedByString("/")
                    if keyValue.count < 2 {
                        continue
                    }
                    _children.updateValue(keyValue[1], forKey: keyValue[0])
                }else if lineText.hasPrefix("sourceTree") {
                    _sourceTree = (lineText.componentsSeparatedByString("="))[1].trim.replace(";")
                }else if lineText.hasPrefix("name") {
                    replaceText = lineText
                    _type = "name"
                    _typeValue = (lineText.componentsSeparatedByString("="))[1].trim.replace(";")
                }else if lineText.hasPrefix("path") {
                    _type = "path"
                    _typeValue = (lineText.componentsSeparatedByString("="))[1].trim.replace(";")
                }else if lineText.hasPrefix("isa") {
                    _isa = (lineText.componentsSeparatedByString("="))[1].trim.replace(";")
                }
            }
            lists.updateValue(PBXGroup(name: _name, isa: _isa, sourceTree: _sourceTree, type: _type, children: _children, typeValue: _typeValue,replaceText:replaceText,fullText:text), forKey: _key)
            
        }
        if lists.count > 0 {
            return lists
        }
        return nil
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
    
    func getXcodeprojPath(workspacePath: NSString) -> NSString? {
        do {
            for item in (try NSFileManager.defaultManager().subpathsOfDirectoryAtPath(workspacePath as String)){
                if item.hasSuffix(".xcodeproj") {
                    return NSString(string:workspacePath.stringByAppendingPathComponent(item))
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
