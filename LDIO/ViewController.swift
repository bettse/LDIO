//
//  ViewController.swift
//  LDIO
//
//  Created by Eric Betts on 9/27/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate{
    var readerDriver : LegoReaderDriver = LegoReaderDriver.singleton
    @IBOutlet weak var toypadState : NSTextField!
    @IBOutlet weak var tokenState : NSTextField!
    @IBOutlet weak var minifigTable : NSTableView!
    @IBOutlet weak var saveButton : NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        //TODO: readerDriver.registerOnConnect()
        
        readerDriver.registerTokenLoaded { (ledPlatform, nfcIndex, token) -> Void in
            self.representedObject = token
        }
        readerDriver.registerTokenLeft({ (ledPlatform, nfcIndex) -> Void in
            self.representedObject = nil
        })
        

        self.minifigTable.setDelegate(self)
        self.minifigTable.setDataSource(self)
    }

    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
            if ((representedObject) != nil) {
                self.tokenState.stringValue = "Token Loaded"
            } else {
                self.tokenState.stringValue = "No Token"
            }
        }
    }

    func save() {
        if let token = self.representedObject as? Token {
            token.minifigId = UInt32(self.minifigTable.selectedRow)
            readerDriver.save(token)
        }
    }
    
    //TableView datasource and delegate
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return ThePoster.Minifigs.count
    }

    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = NSTableCellView()
        cell.textField?.stringValue = ThePoster.Minifigs[row]
        return cell
    }
}

