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


class SeedCommand : Command {
    override init(data: NSData) {
        super.init()
        type = .Seed
        if (data.length != 8) {
            print("Incorrect length for Bee1 command")
        }
        params = data
    }
    
    convenience init(x: UInt32, y: UInt32) {
        let tea = TEA(key: LegoReaderDriver.usbTeaKey)
        let d = tea.encrypt([x, y])
        self.init(data: d)
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(params))"
    }
}

class ChallengeCommand : Command {
    override init(data: NSData) {
        super.init()
        type = .Challenge
        if (data.length != 8) {
            print("Incorrect length for Bee1 command")
        }
        params = data
    }

    convenience init(x: UInt32, y: UInt32) {
        let tea = TEA(key: LegoReaderDriver.usbTeaKey)
        let d = tea.encrypt([x, y])
        self.init(data: d)
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

class ModelCommand : Command {
    let tea = TEA(key: LegoReaderDriver.usbTeaKey)
    
    override init(data: NSData) {
        super.init()
        type = .Model
        if (data.length != 8) {
            print("Incorrect length for \(type.desc()) command")
        }
        params = data
    }
    
    convenience init(nfcIndex: UInt8) {
        let tea = TEA(key: LegoReaderDriver.usbTeaKey)
        let y : UInt32 = 0 //value that gets returned in response as second 4 bytes
        let x = UInt32(nfcIndex)
        let d : NSData = tea.encrypt([x, y])
        self.init(data: d)
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(params))"
    }
}


class LightOnCommand : Command {
    var red : UInt8 = 0x99
    var green : UInt8 = 0x42
    var blue : UInt8 = 0x0e
    var platform : Message.LedPlatform = Message.LedPlatform.All
    
    init(platform: Message.LedPlatform, color: NSColor) {
        self.platform = platform
        red = color.red
        green = color.green
        blue = color.blue
        super.init()
        self.type = .LightOn
    }
    
    override func serialize() -> NSData {
        params = NSData(bytes: [platform.rawValue, red, green, blue] as [UInt8], length: 4)
        return super.serialize()
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(params))"
    }
}

class Fade {
    //XX YY ZZ RR GG BB
    //YY = speed
    //ZZ = count
    let XX : UInt8 = 0x01
    var speed: UInt8 = 1
    var count: UInt8 = 1
    var red : UInt8 = 0x99
    var green : UInt8 = 0x42
    var blue : UInt8 = 0x0e
    
    init(speed: Int, count: Int, color: NSColor) {
        self.speed = UInt8(speed)
        self.count = UInt8(count)
        red = color.red
        green = color.green
        blue = color.blue
    }
    
    init() {}
    
    func serialize() -> NSData {
        return NSData(bytes: [XX, speed, count, red, green, blue] as [UInt8], length: 6)
    }
}

class LightFadeAllCommand : Command {
    var center : Fade
    var left : Fade
    var right : Fade
    
    init(center: Fade, left: Fade, right: Fade) {
        self.center = center
        self.left = left
        self.right = right
        super.init()
        self.type = .LightFadeAll
    }
    
    override func serialize() -> NSData {
        let temp : NSMutableData = center.serialize().mutableCopy() as! NSMutableData
        temp.appendData(left.serialize())
        temp.appendData(right.serialize())
        params = NSData(data: temp)
        return super.serialize()
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(params))"
    }
}

class Flash {
    var count: UInt8 = 1
    var red : UInt8 = 0x99
    var green : UInt8 = 0x42
    var blue : UInt8 = 0x0e
    
    init(count: Int, color: NSColor) {
        self.count = UInt8(count)
        red = color.red
        green = color.green
        blue = color.blue
    }
    
    init() {}
    
    func serialize() -> NSData {
        return NSData(bytes: [count, red, green, blue] as [UInt8], length: 4)
    }
}

class LightFlashAllCommand : Command {
    var center : Flash
    var left : Flash
    var right : Flash
    
    init(center: Flash, left: Flash, right: Flash) {
        self.center = center
        self.left = left
        self.right = right
        super.init()
        self.type = .LightFlashAll
    }
    
    override func serialize() -> NSData {
        let temp : NSMutableData = center.serialize().mutableCopy() as! NSMutableData
        temp.appendData(left.serialize())
        temp.appendData(right.serialize())
        params = NSData(data: temp)
        return super.serialize()
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(params))"
    }
}

class E1Command : Command {
    var nfcIndex : UInt8
    var pwd : [UInt8] = [UInt8](count: 4, repeatedValue: 0)
    let mode : UInt8 = 2 //1 = normal, 2 = debug
    
    init(nfcIndex: UInt8, pwd: [UInt8]) {
        self.nfcIndex = nfcIndex
        self.pwd = pwd
        super.init()
        self.type = .E1
    }
    
    override func serialize() -> NSData {
        params = NSData(bytes: [nfcIndex, mode, pwd[0], pwd[1], pwd[2], pwd[3]] as [UInt8], length: 6)
        return super.serialize()
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(params))"
    }
}

class LightFadeRandomCommand : Command {
    var ledPlatform : Message.LedPlatform = Message.LedPlatform.All
    var speed : UInt8 = 1
    var count : UInt8 = 1
    
    init(ledPlatform: Message.LedPlatform, speed: UInt8, count: UInt8) {
        self.ledPlatform = ledPlatform
        self.speed = speed
        self.count = count
        super.init()
        self.type = .LightFadeRandom
    }
    
    override func serialize() -> NSData {
        params = NSData(bytes: [ledPlatform.rawValue, speed, count] as [UInt8], length: 3)
        return super.serialize()
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(params))"
    }
}

class C5Command : Command {
    override init() {
        super.init()
        self.type = .C5
    }
    
    override func serialize() -> NSData {
        params = NSData()
        return super.serialize()
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(params))"
    }
}

class C1Command : Command {
    var ledPlatform : Message.LedPlatform = Message.LedPlatform.Center
    
    init(ledPlatform: Message.LedPlatform) {
        super.init()
        self.type = .C1
    }
    
    override func serialize() -> NSData {
        params = NSData(bytes: [ledPlatform.rawValue] as [UInt8], length: 1)
        return super.serialize()
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(params))"
    }
}