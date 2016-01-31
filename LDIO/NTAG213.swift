//
//  NTAG213.swift
//  LDIO
//
//  Created by Eric Betts on 10/3/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation

class NTAG213 : CustomStringConvertible {
    static let pageCount : Int = 45
    static let pageSize : Int = 4//bytes
    static let tokenSize : Int = pageSize * pageCount
    static let uidLength = 7
    static let userMemoryPage = 0x04
    static let userMemoryLength = 36 //pages
    static let cfg0Page = 0x29
    static let cfg1Page = 0x2A

    var tagId : NSData
    var data : NSMutableData = NSMutableData()
    
    var uid : NSData {
        return tagId
    }
    
    var userMemory : NSData {
        return pageRange(NTAG213.userMemoryPage, pageCount: NTAG213.userMemoryLength)
    }
    
    var capabilityContainer : NSData {
        return page(3)
    }
    
    var hasNdef : Bool {
        var value : UInt8 = 0
        capabilityContainer.getBytes(&value, range: NSMakeRange(0, 1))
        return value == NDEF.magicByte
    }
    
    var ndefVer : UInt8 {
        var value : UInt8 = 0
        capabilityContainer.getBytes(&value, range: NSMakeRange(1, 1))
        return value
    }
    
    var ndefLength : Int {
        var length : UInt8 = 0
        capabilityContainer.getBytes(&length, range: NSMakeRange(2, 1))
        return Int(length) * 8 //8.5.4 table 4
    }
    
    var ndefData : NSData {
        return userMemory.subdataWithRange(NSMakeRange(0, ndefLength))
    }
    
    var ndefMessage : NDEF.Message {
       return NDEF.Message(data: ndefData)
    }
        
    var dynamicLockBytes : NSData {
        get {
            return page(0x28)
        }
    }

    var Config0 : NSData {
        get {
            return page(0x29)
        }
    }
    
    var Config1 : NSData {
        get {
            return page(0x2A)
        }
    }
    
    var filename : String {
        get {
            return "\(tagId).bin"
        }
    }
    
    init(tagId: NSData) {
        self.tagId = tagId
    }
    
    var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(uid)::\(userMemory)"
    }
    
    func nextPage() -> Int {
        return data.length / NTAG213.pageSize
    }
    
    func complete() -> Bool{
        return (nextPage() >= NTAG213.pageCount)
    }
    
    func page(pageNumber: Int) -> NSData {
        return data.subdataWithRange(NSMakeRange(pageNumber * NTAG213.pageSize, NTAG213.pageSize))
    }
    
    func pageRange(pageNumber: Int, pageCount: Int) -> NSData {
        return data.subdataWithRange(NSMakeRange(pageNumber * NTAG213.pageSize, pageCount * NTAG213.pageSize))
    }

    func load(pageNumber: Int, pageData: NSData) {
        if (pageNumber == nextPage()) {
            data.appendData(pageData)
        } else {
            let pageRange = NSMakeRange(pageNumber * NTAG213.pageSize, NTAG213.pageSize)
            if data.length >= pageRange.location + pageRange.length { //prevent writing to non-existant data
                data.replaceBytesInRange(pageRange, withBytes: pageData.bytes)
            } else {
                print("Tried writing \(pageRange.length) bytes to offset \(pageRange.location), but only have \(data.length) bytes of data")
            }
        }
        if (data.length > NTAG213.tokenSize) {
            data = data.subdataWithRange(NSMakeRange(0, NTAG213.tokenSize)).mutableCopy() as! NSMutableData //Remove excess bytes
        }
    }
    
    func load(pageNumber: UInt8, pageData: NSData) {
        load(Int(pageNumber), pageData: pageData)
    }
}