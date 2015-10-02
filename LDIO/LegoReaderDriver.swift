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
        self.activate()
    }
    
    func activate() {
        let activate = NSData(fromHex: "55 0f b0 01 28 63 29 20 4c 45 47 4f 20 32 30 31 34 f7")
        reader.output(activate)
    }
    
    
    func incomingMessage(notification: NSNotification) {
        let userInfo = notification.userInfo
        if let report : NSData = userInfo?["report"] as? NSData {
            
            if ( Int(report[0].memory) == 0x56) {
                let reply = addChecksum(NSData(fromHex: "55 04 d2 02 00 26"))
                self.reader.output(reply)
            }

            //let message = Message(data: report)
            //print(message)
        }
    }
    
    func addChecksum(data: NSData) -> NSData {
        var sum = 0
        let length = data.length
        let newData = data.mutableCopy()
        
        let b = UnsafeBufferPointer<UInt8>(start: UnsafePointer(data.bytes), count: length)
        for i in 0..<length {
            sum += Int(b[i])
        }
            
        var checksum : UInt8 = UInt8(sum & 0xff)
        newData.appendBytes(&checksum, length: sizeof(checksum.dynamicType))

        return newData as! NSData
    }

}