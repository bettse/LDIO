//
//  LegoReader.swift
//  LDIO
//
//  Created by Eric Betts on 9/27/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation
import IOKit.hid

class LegoReader : NSObject {

    let vendorId = 0x0E6F
    let productId = 0x0241
    let reportSize : CFIndex = 0x20
    static let singleton = LegoReader()
    var device : IOHIDDevice? = nil
    
    func input(inResult: IOReturn, inSender: UnsafeMutablePointer<Void>, type: IOHIDReportType, reportId: UInt32, report: UnsafeMutablePointer<UInt8>, reportLength: CFIndex) {
        let report = NSData(bytes: report, length: reportLength)
        print("Incoming: \(report)")
        dispatch_async(dispatch_get_main_queue(), {
            NSNotificationCenter.defaultCenter().postNotificationName("incomingMessage", object: self, userInfo: ["report": report])
        })
    }
    
    func output(report: NSData) {
        let reportId : CFIndex = 0
        let data = report
        if (data.length > reportSize) {
            print("output data too large for USB report", terminator: "\n")
            return
        }
        if let reader = device {
            print("Outgoing: \(data)")
            IOHIDDeviceSetReport(reader, kIOHIDReportTypeOutput, reportId, UnsafePointer<UInt8>(data.bytes), data.length);
        }
    }
   
    func connected(inResult: IOReturn, inSender: UnsafeMutablePointer<Void>, inIOHIDDeviceRef: IOHIDDevice!) {
        // It would be better to look up the report size and create a chunk of memory of that size
        let report = UnsafeMutablePointer<UInt8>.alloc(reportSize)
        device = inIOHIDDeviceRef
        
        let 🙊 : IOHIDReportCallback = { inContext, inResult, inSender, type, reportId, report, reportLength in
            let this : LegoReader = unsafeBitCast(inContext, LegoReader.self)
            this.input(inResult, inSender: inSender, type: type, reportId: reportId, report: report, reportLength: reportLength)
        }
        
        //Hook up inputcallback
        IOHIDDeviceRegisterInputReportCallback(device, report, reportSize, 🙊, unsafeBitCast(self, UnsafeMutablePointer<Void>.self));
        
        //Let the world know
        dispatch_async(dispatch_get_main_queue(), {
            NSNotificationCenter.defaultCenter().postNotificationName("deviceConnected", object: self, userInfo: ["class": NSStringFromClass(self.dynamicType)])
        })
    }

    
    func removed(inResult: IOReturn, inSender: UnsafeMutablePointer<Void>, inIOHIDDeviceRef: IOHIDDevice!) {
        dispatch_async(dispatch_get_main_queue(), {
            NSNotificationCenter.defaultCenter().postNotificationName("deviceDisconnected", object: self, userInfo: ["class": NSStringFromClass(self.dynamicType)])
        })
    }
    
    func initUsb() {
        let deviceMatch = [kIOHIDProductIDKey: productId, kIOHIDVendorIDKey: vendorId ]
        let managerRef = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone)).takeUnretainedValue()
        
        IOHIDManagerSetDeviceMatching(managerRef, deviceMatch)
        IOHIDManagerScheduleWithRunLoop(managerRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        IOHIDManagerOpen(managerRef, 0);
        
        let 🙈 : IOHIDDeviceCallback = { inContext, inResult, inSender, inIOHIDDeviceRef in
            let this : LegoReader = unsafeBitCast(inContext, LegoReader.self)
            this.connected(inResult, inSender: inSender, inIOHIDDeviceRef: inIOHIDDeviceRef)
        }
        
        let 🙉 : IOHIDDeviceCallback = { inContext, inResult, inSender, inIOHIDDeviceRef in
            let this : LegoReader = unsafeBitCast(inContext, LegoReader.self)
            this.removed(inResult, inSender: inSender, inIOHIDDeviceRef: inIOHIDDeviceRef)
        }
        
        IOHIDManagerRegisterDeviceMatchingCallback(managerRef, 🙈, unsafeBitCast(self, UnsafeMutablePointer<Void>.self))
        IOHIDManagerRegisterDeviceRemovalCallback(managerRef, 🙉, unsafeBitCast(self, UnsafeMutablePointer<Void>.self))
        
        
        NSRunLoop.currentRunLoop().run();
    }
}