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
        readerThread = NSThread(target: reader, selector:"initUsb", object: nil)
        if let thread = readerThread {
            thread.start()
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "deviceConnected:", name: "deviceConnected", object: nil)
    }

    
    func deviceConnected(notification: NSNotification) {
        print("Device connected")
        //55 0f b0 01 28 63 29 20 4c 45 47 4f 20 32 30 31 34 f7 00 00 00 00 00 00 00 00 00 00 00 00 00 00
        let activate = NSData(bytes: [0x55, 0x0f, 0xb0, 0x01, 0x28, 0x63, 0x29, 0x20, 0x4c, 0x45, 0x47, 0x4f, 0x20, 0x32, 0x30, 0x31, 0x34, 0xf7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] as [UInt8], length: 32)
        reader.output(activate)
    }
}