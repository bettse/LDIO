//
//  Token.swift
//  LDIO
//
//  Created by Eric Betts on 10/6/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation

class Token : NTAG213 {
    
    var secretPages : NSData {
        get {
            return pageRange(30, pageCount: 10)
        }
    }
    
    var vehicleGadget : UInt16 {
        get {
            let vgPage : NSData = page(36)
            var value : UInt16 = 0
            vgPage.getBytes(&value, range: NSMakeRange(0, sizeof(value.dynamicType)))
            return value
        }
    }
    
    var vehicleGadgetUpgrades : UInt16 {
        get {
            let vguPage : NSData = page(35)
            var value : UInt16 = 0
            vguPage.getBytes(&value, range: NSMakeRange(0, sizeof(value.dynamicType)))
            return value
        }
    }
    
    
    //0 in minifigs, 1 in vehicle...enum?
    var category : UInt16 {
        get {
            let cPage : NSData = page(38)
            var value : UInt16 = 0
            cPage.getBytes(&value, range: NSMakeRange(1, sizeof(value.dynamicType)))
            return value
        }
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(uid.hexadecimalString())::\(secretPages))"
    }
}