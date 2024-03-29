//
//  Message.swift
//  DIMP
//
//  Created by Eric Betts on 6/19/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation

//Parent class of Command, Response, and Update


//CustomStringConvertible make the 'description' method possible
class Message : CustomStringConvertible {
    enum commandType : UInt8 {
        case Activate = 0xB0
        case Seed = 0xB1
        case Challenge = 0xB3
        case LightOn = 0xC0
        case C1 = 0xC1
        case LightFadeSingle = 0xC2
        case LightFadeRandom = 0xC4
        case C5 = 0xC5
        case LightFadeAll = 0xC6
        case LightFlashAll = 0xC8
        case Presence = 0xD0
        case Read = 0xD2
        case Write = 0xD3
        case Model = 0xD4
        case E1 = 0xE1
        case E5 = 0xE5
        func desc() -> String {
            return String(self).componentsSeparatedByString(".").last!
        }
    }    
    enum LedPlatform : UInt8 {
        case All = 0
        case Center = 1
        case Left = 2
        case Right = 3
        case None = 0xFF
        func desc() -> String {
            return String(self).componentsSeparatedByString(".").last!
        }
    }
    
    static var archive = [UInt8: Message]()
    
    var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)"
    }

}