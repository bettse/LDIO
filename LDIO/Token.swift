//
//  Token.swift
//  LDIO
//
//  Created by Eric Betts on 10/6/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation

class Token : NTAG213 {
    static let pwdHashConstant = "(c) Copyright LEGO 2014"
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
    
    var pwd : UInt32 {
        get {
            //Construct uid + magic string + 2xAA padding
            let input = NSMutableData()
            input.appendData(uid)
            input.appendData(Token.pwdHashConstant.dataUsingEncoding(NSASCIIStringEncoding)!)
            input.appendBytes([0xAA, 0xAA] as [UInt8], length: 2)
            
            //Make into array of [UInt32]
            let count = input.length / sizeof(UInt32)
            var array : [UInt32] = [UInt32](count: count, repeatedValue: 0)
            input.getBytes(&array, length:count * sizeof(UInt32))
            
            //Hash
            return magicHash(array).byteSwapped
        }
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(uid.hexadecimalString())::\(secretPages))"
    }
    
    func magicHash(data: [UInt32]) -> UInt32 {
        var result : UInt32 = 0
        
        for b in data {
            let v4 = result.rotate(25)
            let v5 = result.rotate(10)
            result = b &+ v4 &+ v5 &- result
        }
        
        return result
    }
}