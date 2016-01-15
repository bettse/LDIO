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
    static let minifigHashConstant = NSData(fromHex: "b7 d5 d7 e6 e7 ba 3c a8 d8 75 47 68 cf 23 e9 fe")
    
    var secretPages : NSData {
        get {
            return pageRange(30, pageCount: 10)
        }
    }
    
    var vehicleGadgetId : UInt16 {
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
    var brickDesign : FuncCirkleBrick {
        get {
            let cPage : NSData = page(0x26)
            var value : UInt16 = 0
            cPage.getBytes(&value, range: NSMakeRange(1, sizeof(value.dynamicType)))
            return FuncCirkleBrick(rawValue: value)!
        }
    }
    
    var pwd : NSData {
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
            var pwdBytes = magicHash(array)
            return NSData(bytes: &pwdBytes, length: sizeof(UInt32))
        }
    }
    
    var minifigTea : TEA {
        get {
            //Calculate tea key
            var minifigKey : [UInt32] = [UInt32](count: 4, repeatedValue: 0)
            
            for i in 0..<4 {
                let partialConstant = Token.minifigHashConstant.subdataWithRange(NSMakeRange(0, (i+1)*sizeof(UInt32)))
                let input = NSMutableData()
                input.appendData(uid)
                input.appendData(partialConstant)
                input.appendBytes([0xAA] as [UInt8], length: 1)
                
                //Make into array of [UInt32]
                let count = input.length / sizeof(UInt32)
                var array : [UInt32] = [UInt32](count: count, repeatedValue: 0)
                input.getBytes(&array, length:count * sizeof(UInt32))
                
                minifigKey[i] = magicHash(array)
            }
            return TEA.init(key: minifigKey)
        }
    }
    
    var minifigId: UInt32 {
        get {
            let t = minifigTea
            let pages = pageRange(0x24, pageCount: 2)
            let doubleId : [UInt32] = t.decrypt(pages) // Id is repeated twice

            if let first = doubleId.first {
                return first
            }
            return 0;
        }
        set(newId) {
            let t = minifigTea
            let doubleId : [UInt32] = [UInt32](count: 2, repeatedValue: newId)
            let pages : NSData = t.encrypt(doubleId)
            let newPage0x24 = pages.subdataWithRange(NSMakeRange(0, Token.pageSize))
            let newPage0x25 = pages.subdataWithRange(NSMakeRange(4, Token.pageSize))
            print("\(page(0x24)) to be replaced by \(newPage0x24)")
            print("\(page(0x25)) to be replaced by \(newPage0x25)")
            
            load(0x24, pageData: newPage0x24)
            load(0x25, pageData: newPage0x25)
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