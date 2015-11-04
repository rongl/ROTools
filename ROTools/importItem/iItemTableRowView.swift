//
//  iItemTableRowView.swift
//  ROTools
//
//  Created by RonGL on 15/9/23.
//  Copyright © 2015年 RonGL. All rights reserved.
//

import Cocoa

class iItemButton:NSButton {
    var event:(()->Void)!   
    override func mouseDown(theEvent: NSEvent) {
        super.mouseDown(theEvent)
        if event != nil {
            event()
        }
    }
    
    override func performClick(sender: AnyObject?) {
        super.performClick(self)
    }
    
}

public protocol iItemButtonDelegate:NSObjectProtocol{
    func iItemButtonMouseDown()
    
}

class iItemTableRowView: NSTableRowView,NSTextFieldDelegate {
    var eventRemove:((Int)->Void)!
    var eventUpdate:(()->Void)!
    var rowIndex = 0
    var item:iItem!
    var updateEvent : ((iItem) -> Void)?
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
    
    func valueChange(sender:NSObject) {
        if sender is NSButton {
            if let switchButton = (sender as! NSButton).cell {
                item.setConfigForIndex(Int(switchButton.tag/100), switchSizeStateForIndex: switchButton.tag%100)
               // NSLog("\(switchButton.tag) : \(switchButton.title)")
                if let event = updateEvent {
                    event(item)
                }
            }
        }
    }
    
    
    func run(){
        
    }
    
    init(width:Double,height:Double,item:iItem){
        super.init(frame: NSRect(x: 0.0, y: 0.0, width: width, height: height))
        
        self.item = item
        var imgSizeZoom = 1
        let fileNameArray = item.fileName.componentsSeparatedByString("@")
        if fileNameArray.count == 2 {
            if fileNameArray.last == "2x" {
                imgSizeZoom = 2
            }else if fileNameArray.last == "3x" {
                imgSizeZoom = 3
            }
            self.item.setFileName(fileNameArray.first!)
        }
        
        
        let imgView = NSImageView(frame: NSRect(x: 5, y: 5, width: 70, height: 70))
        imgView.image = NSImage(contentsOfURL:item.imageUrl)
        self.addSubview(imgView)

        
        var startY = 5
        self.addSubview(NSTextField(x: 100, y: startY, width: 50, labelText: "Name:"))
        let nameUI = NSTextField(x: 150, y: startY, width: 200, inputText: self.item.fileName)
        nameUI.delegate = self
        self.addSubview(nameUI)
        nameUI.tag = 0
        
        
        
        startY += 25
        var typeGroup = 0;
        for  pngconf in item.configs {
            // 设备类型
            let deviceUI = NSButton(x: 100, y: startY, width: 100, switchTitle: pngconf.type.rawValue)
            deviceUI.enabled = false
            self.addSubview(deviceUI)
            
            var unitWidth = pngconf.unitWidth;
            var unitHeight = pngconf.unitHeight;
            if(unitWidth==0 || unitHeight==0 ){
                unitWidth = Int((imgView.image?.size.width)!) * imgSizeZoom / 3
                unitHeight = Int((imgView.image?.size.height)!) * imgSizeZoom / 3
            }
            // 设备1x的长度
            let widthUI = NSTextField(x: 200, y: startY, width: 40, numberInputText: "\(unitWidth)")
            widthUI.cell?.alignment = .Right
            widthUI.delegate = self
            self.addSubview(widthUI)
            widthUI.tag = (typeGroup + 1)
            
            
            self.addSubview(NSTextField(x: 245, y: startY, width: 20, labelText: "x"))
            
            // 设备1x的高度
            let hieghtUI = NSTextField(x: 260, y: startY, width: 40, numberInputText: "\(unitHeight)")
            hieghtUI.cell?.alignment = .Right
            hieghtUI.cell?.action = "valueChange:"
            hieghtUI.cell?.target =  self
            hieghtUI.delegate = self
            self.addSubview(hieghtUI)
            hieghtUI.tag = (typeGroup + 2)
           
            
            
            self.addSubview(NSTextField(x: 305, y: startY, width: 30, labelText: "pt"))
            
            let sizeWidth = 40
            // 设备使用的图片格式(@1x,@2x,@3x)
            for _size in pngconf.size.enumerate() {
                let startX = _size.element.0 * (sizeWidth + 10) + 305
                let sButton = NSButton(x: startX, y: startY, width: sizeWidth, switchTitle: "@\(_size.element.0)x", state: _size.element.1)
                sButton.cell?.action = "valueChange:"
                sButton.cell?.identifier = "size"
                self.addSubview(sButton)
                sButton.cell?.tag = (typeGroup + _size.element.0)
                sButton.cell?.target =  self
                
            }
            typeGroup += 100
        }
        
    }
    
    // 处理TextInput的修改.
    func control(control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        if let text = fieldEditor.string {
            switch control.tag {
            case 0 :
                item.setFileName(text)
                break
            case (let index) where index % 10 == 1 :
                item.setConfigForIndex(Int(index/10), byWdith: Int(text)!)
                break
            case (let index) where index % 10 == 2 :
                item.setConfigForIndex(Int(index/10), byHeight: Int(text)!)
                break
            default:
                break
            }
            if let event = updateEvent {
                event(item)
            }
            //NSLog("\(control.tag) : \(fieldEditor.string!)")
            return true;
        }
        return false
    }
    

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
