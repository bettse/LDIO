//
//  LegoReaderDriver.swift
//  LDIO
//
//  Created by Eric Betts on 9/28/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation

class LegoReaderDriver : NSObject {
    static let singleton = LegoReaderDriver()
    var readerThread : NSThread?
    
    lazy var reader : LegoReader  = {
        return LegoReader.singleton
        }()

    
    override init() {
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "deviceConnected:", name: "deviceConnected", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "incomingMessage:", name: "incomingMessage", object: nil)

        readerThread = NSThread(target: reader, selector:"initUsb", object: nil)
        if let thread = readerThread {
            thread.start()
        }
    }
    
    func deviceConnected(notification: NSNotification) {
        print("Device connected")
        NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: "activate", userInfo: nil, repeats: false)
    }
    
    func activate() {
        let activate = NSData(fromHex: "55 0f b0 01 28 63 29 20 4c 45 47 4f 20 32 30 31 34 f7")
        reader.output(activate)
    }
    
    
    func incomingMessage(notification: NSNotification) {
        let userInfo = notification.userInfo
        if let report : NSData = userInfo?["report"] as? NSData {
            
            if ( Int(report[1].memory) == 0x19) {
                let reply = NSData(fromHex: "55 06 c0 02 00 ff 6e 18 a2")//Lights up all platforms
                self.reader.output(reply)
            }

            //let message = Message(data: report)
            //print(message)
        }
    }

}