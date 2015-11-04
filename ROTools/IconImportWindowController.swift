//
//  IconImportWindowController.swift
//  ROTools
//
//  Created by RonGL on 15/9/18.
//  Copyright © 2015年 RonGL. All rights reserved.
//

import Cocoa
import AppKit

class IconImportWindowController: NSWindowController,NSComboBoxDataSource,NSComboBoxDelegate,NSTableViewDataSource,NSTableViewDelegate {

    @IBOutlet weak var mainView: NSView!
    @IBOutlet var typeListComboBox: NSComboBox!
    @IBOutlet weak var imageListTable: NSTableView!
    @IBOutlet weak var imageListTableHeader: NSTableHeaderView!

    
    var assetsPath:NSString!
    var importType:NSArray!
    var imagesFile = [NSURL]()
    var imagesList = [iItem]()
    var iConfigs = [iItemConfig]()
    
    
    override func windowDidLoad() {
        super.windowDidLoad()
        typeListComboBox.dataSource = self
        typeListComboBox.setDelegate(self)
        typeListComboBox.selectItemAtIndex(0)
        imageListTable.setDataSource(self)
        imageListTable.setDelegate(self)
        imageListTable.setNeedsDisplay()
        imageListTable.headerView = NSTableHeaderView(frame: NSZeroRect)
    }
    
    func clearData(){
        imagesFile = [];
        imagesList  = [];
        imageListTable.reloadData()
    }
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return imagesList.count
    }
    
    func tableView(tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let rowView = iItemTableRowView(width: Double.init(imageListTable.bounds.size.width), height: 80, item: imagesList[row])
//        rowView.rowIndex = row
//        rowView.eventRemove = {
//            [unowned self] (rowIndex:Int) -> Void in
//            self.imagesFile.removeAtIndex(rowIndex)
//            self.imagesList.removeAtIndex(rowIndex)
//            self.imageListTable.removeRowsAtIndexes(NSIndexSet(index: rowIndex), withAnimation: NSTableViewAnimationOptions.EffectGap)
//        }
        rowView.updateEvent = {
            (item:iItem) -> Void in
            self.imagesList[row] = item
        }
        return rowView
    }
    
    func tableView(tableView: NSTableView, didAddRowView rowView: NSTableRowView, forRow row: Int) {
        if row % 2 == 0 {
            rowView.backgroundColor = NSColor.init(SRGBRed: 0.95, green: 0.95, blue: 0.95, alpha: 1)
        }else{
            rowView.backgroundColor = NSColor.init(SRGBRed: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        }
        rowView.selectionHighlightStyle = .None
        
    }
    
    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return CGFloat.init(80)
    }
    
    
    func numberOfItemsInComboBox(aComboBox: NSComboBox) -> Int {
        return importType.count
    }

    func comboBox(aComboBox: NSComboBox, objectValueForItemAtIndex index: Int) -> AnyObject {
        if let title = (importType[index] as! NSDictionary).valueForKey("title") {
            return title
        }
        return  ""
    }
    
    func comboBoxSelectionDidChange(notification: NSNotification) {
        if let unitDict = (importType[typeListComboBox.indexOfSelectedItem] as! NSDictionary).valueForKey("unit"),
        let universalUnit = (unitDict as! NSDictionary).valueForKey("universal"),
        let iType = iItemType(rawValue: "universal"),
        let width = universalUnit.valueForKey("width")?.integerValue,
        let height = universalUnit.valueForKey("height")?.integerValue
        {
            iConfigs = [iItemConfig(type: iType, unitWidth: width, unitHeight: height)]
        }
        
    }
    
    
    
    @IBAction func actionFiles(sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.allowedFileTypes = ["png"]
        openPanel.canChooseFiles = true
        openPanel.canCreateDirectories = false
        openPanel.allowsMultipleSelection = true
        
        let result = openPanel.runModal()
        if (NSFileHandlingPanelOKButton == result) {
            for url in openPanel.URLs {
                if !imagesFile.contains(url) {
                    imagesFile.append(url)
                    imagesList.append(iItem(url: url, configs: iConfigs))
                }
            }
            imageListTable.reloadData()
          
        }
    }
    
    
    
    @IBAction func actionClearLists(sender: NSButton) {
        clearData()
    }
    
    @IBAction func actionImport(sender: NSButton) {
       // print(self.assetsPath)
        let fileManager = NSFileManager.defaultManager()
       
        for image in imagesList {
            
            let dirFullPath = self.assetsPath.stringByAppendingPathComponent("\(image.fileName).imageset")
            let jsonPath = dirFullPath.stringByAppendingPathComponent("Contents.json")
            if fileManager.fileExistsAtPath(dirFullPath) && fileManager.isDeletableFileAtPath(dirFullPath) {
                do {
                    try fileManager.removeItemAtURL(NSURL(string: dirFullPath)!)
                } catch {
                    
                }
            }
            
            if !fileManager.fileExistsAtPath(dirFullPath) {
                do {
                    try fileManager.createDirectoryAtPath(dirFullPath, withIntermediateDirectories: true, attributes: nil)
                    let imageScoure = NSImage(contentsOfURL:image.imageUrl)
                    let imgArray = NSMutableArray()
                    for config in image.configs {
                        if config.size.count <= 1 {
                            continue
                        }
                    
                        for i in (1...3) {
                            if let isUse = config.size[i] {
                                if isUse {
                                    let imageFileName = "\(i)x.png"
                                    let dict = ["idiom" : config.type.rawValue ,"filename" : imageFileName, "scale" : "\(i)x"]
                                    let muDict = NSMutableDictionary(dictionary: dict)
                                    muDict["size"] = "\(config.unitWidth)x\(config.unitHeight)"
                                    if(config.unitWidth==0 || config.unitHeight==0 ){
                                        let unitWidth = Int(imageScoure!.size.width) * i / 3
                                        let unitHeight = Int(imageScoure!.size.height) * i / 3
                                        muDict["size"] = "\(unitWidth)x\(unitHeight)"
                                    }
                                    
                                    imgArray.addObject(dict)
                                    Bin.resizeImage(imageScoure!, attributes: muDict, savePath: dirFullPath)
                                }
                            }
                        }
                    
                    }
                    if imgArray.count > 0 {
                        let jsonContent = ["images": imgArray, "info":["version" : 1, "author" : "xcode"] ]
                        do{
                            try NSJSONSerialization.dataWithJSONObject(jsonContent, options: .PrettyPrinted).writeToFile(jsonPath, options: .AtomicWrite)
                            
                        } catch {
                        
                        }
                    }
                } catch {
                    
                }
            }
        }
        }
}


















