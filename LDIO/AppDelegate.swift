//
//  AppDelegate.swift
//  LDIO
//
//  Created by Eric Betts on 9/27/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var readerThread : NSThread?
    
    lazy var reader : LegoReader  = {
        return LegoReader.singleton
    }()

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        
        readerThread = NSThread(target: reader, selector:"initUsb", object: nil)
        if let thread = readerThread {
            thread.start()
        }
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "deviceConnected:", name: "deviceConnected", object: nil)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    func deviceConnected(notification: NSNotification) {
        print("Device connected")
    }
}

