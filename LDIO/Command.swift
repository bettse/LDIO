//
//  Command.swift
//  DIMP
//
//  Created by Eric Betts on 6/19/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation
import AppKit

class Command : Message {
    let typeIndex = 0
    let corrolationIdIndex = 1
    let paramsIndex = 2

    static var corrolationGenerator = Range(start: 1, end: UInt8.max - 1).generate()
    static var nextSequence : UInt8 {
        get {
            if let next = corrolationGenerator.next() {
                return next
            }
            //Implicitly else
            corrolationGenerator = Range(start: 1, end: UInt8.max - 1).generate()
            return 0
        }
    }
    
    var type : commandType = .Activate
    var corrolationId : UInt8 = 0
    var params : NSData = NSData()
    
    override init() {
        corrolationId = Command.nextSequence
        super.init()
        Message.archive[corrolationId] = self
    }
    
    //Parseing from NSData
    init(data: NSData) {
        data.getBytes(&type, range: NSMakeRange(typeIndex, sizeof(commandType)))
        data.getBytes(&corrolationId, range: NSMakeRange(corrolationIdIndex, sizeof(UInt8)))
        params = data.subdataWithRange(NSMakeRange(paramsIndex, data.length - paramsIndex))
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(type.desc()))"
    }
    
    func serialize() -> NSData {
        let data = NSMutableData()
        var rawType : UInt8 = type.rawValue
        data.appendBytes(&rawType, length: sizeof(UInt8))
        data.appendBytes(&corrolationId, length: sizeof(UInt8))
        data.appendData(params)
        return data
    }
}

class ActivateCommand : Command {
    override init() {
        super.init()
        type = .Activate
        params = LegoReaderDriver.magic
    }
}

class ReadCommand : Command {
    var nfcIndex : UInt8
    var pageNumber : UInt8

    init(nfcIndex: UInt8, page: UInt8) {
        self.nfcIndex = nfcIndex
        self.pageNumber = page
        super.init()
        type = .Read
        params = NSData(bytes: [nfcIndex, page] as [UInt8], length: 2)
    }
    
    convenience init(nfcIndex: UInt8, page: Int) {
        self.init(nfcIndex: nfcIndex, page: UInt8(page))
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(NFC \(nfcIndex) page 0x\(String(pageNumber, radix: 0x10)))"
    }
}

class WriteCommand : Command {
    var nfcIndex : UInt8
    var pageNumber : UInt8
    var data : NSData
    
    init(nfcIndex: UInt8, page: UInt8, data: NSData) {
        self.nfcIndex = nfcIndex
        self.pageNumber = page
        self.data = data
        super.init()
        type = .Write
        if (data.length != NTAG213.pageSize) {
            print("WriteCommand data is not the correct length")
        }
        let temp = NSMutableData(bytes: [nfcIndex, page] as [UInt8], length: 2)
        temp.appendData(data)
        params = NSData(data: temp)
    }
    
    convenience init(nfcIndex: UInt8, page: Int, data: NSData) {
        self.init(nfcIndex: nfcIndex, page: UInt8(page), data: data)
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(NFC \(nfcIndex) page 0x\(String(pageNumber, radix: 0x10)) => \(data))"
    }
}


class B1Command : Command {
    override init(data: NSData) {
        super.init()
        type = .B1
        if (data.length != 8) {
            print("Incorrect length for Bee1 command")
        }
        params = data
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(params))"
    }
}

class PresenceCommand : Command {
    override init() {
        super.init()
        type = .Presence
        params = NSData()
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(params))"
    }
}

class D4Command : Command {
    override init(data: NSData) {
        super.init()
        type = .D4
        if (data.length != 8) {
            print("Incorrect length for \(type.desc()) command")
        }
        params = data
    }

    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(params))"
    }
}


