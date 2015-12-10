//
//  Update.swift
//  DIMP
//
//  Created by Eric Betts on 6/19/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation

//Sorry about having something call nfcIndexIndex; it was the blending of the two patterns
class Update : Message {
    
    let ledPlatformIndex = 0
    let sakIndex = 1
    let nfcIndexIndex = 2
    let directionIndex = 3
    let tagUidIndex = 4
    
    enum Direction : UInt8 {
        case Arriving = 0
        case Departing = 1
        func desc() -> String {
            return String(self).componentsSeparatedByString(".").last!
        }
    }

    //http://nfc-tools.org/index.php?title=ISO14443A
    enum Sak : UInt8 {
        case MifareUltralight = 0x00
        case MifareClassic1k = 0x08
        case MifareMini = 0x09
        case MifareClassic4k = 0x18
        case MifareDesFire = 0x20
        case Unknown = 0xFF //Not standard
    }
    
    //Setting defaults so I don't have to deal with '?' style variables yet
    var ledPlatform : LedPlatform = .None
    var nfcIndex : UInt8 = 0
    var sak : Sak = .Unknown
    var direction : Direction = .Arriving
    var uid : NSData
    
    init(data: NSData) {
        if let ledPlatform = LedPlatform(rawValue: data[ledPlatformIndex]) {
            self.ledPlatform = ledPlatform
        }
        if let sak = Sak(rawValue: data[sakIndex]) {
            self.sak = sak
        }
        nfcIndex = data[nfcIndexIndex]
        if let direction = Direction(rawValue: data[directionIndex]) {
            self.direction = direction
        }
        uid = data.subdataWithRange(NSMakeRange(tagUidIndex, NTAG213.uidLength))
    }
    
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(ledPlatform.desc()) SAK:\(sak) \(nfcIndex) \(direction.desc()) \(uid.hexadecimalString()))"
    }
}