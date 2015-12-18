//
//  TEA.swift
//  LDIO
//
//  Created by Eric Betts on 12/17/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation

class TEA {
    let key : [UInt32] = [0x30f6fe55, 0xc10bbf62, 0x347cb3c9, 0xfb293e97]
    
    func decrypt(value: NSData) -> NSData {
        var _values : [UInt32] = [0, 0]
        //In the process of copying this out, their endiannes gets swapped
        value.getBytes(&_values[0], range: NSMakeRange(0, sizeof(UInt32)))
        value.getBytes(&_values[1], range: NSMakeRange(4, sizeof(UInt32)))
        
        let result = _decrypt(_values, key: key)
        return NSData(bytes: result, length: sizeof(UInt32)*2)
    }
    
    func decrypt(value: NSData) -> [UInt32] {
        var _values : [UInt32] = [0, 0]
        //In the process of copying this out, their endiannes gets swapped
        value.getBytes(&_values[0], range: NSMakeRange(0, sizeof(UInt32)))
        value.getBytes(&_values[1], range: NSMakeRange(4, sizeof(UInt32)))
        
        let result = _decrypt(_values, key: key)
        return result
    }
    
    func _decrypt(value : [UInt32], key: [UInt32]) -> [UInt32] {
        if (value.count != 2 || key.count != 4) {
            print("Bad value or key")
            return []
        }
        let delta : UInt32 = 0x9e3779b9
        
        var v0 : UInt32 = value[0]
        var v1 : UInt32 = value[1]
        var sum : UInt32 = 0xC6EF3720
        
        for _ in 1...32 {
            let a = (v0 << 4) &+ key[2]
            let b = v0 &+ sum
            let c = (v0 >> 5) &+ key[3]
            v1 = v1 &- (a ^ b ^ c)
            
            let d = (v1 << 4) &+ key[0]
            let e = v1 &+ sum
            let f = (v1 >> 5) &+ key[1]
            v0 = v0 &- (d ^ e ^ f)
            
            sum = sum &- delta
        }
        return [v0, v1]
    }

    
    func encrypt(value: NSData) -> NSData {
        var _values : [UInt32] = [0, 0]
        //In the process of copying this out, their endiannes gets swapped
        value.getBytes(&_values[0], range: NSMakeRange(0, sizeof(UInt32)))
        value.getBytes(&_values[1], range: NSMakeRange(sizeof(UInt32), sizeof(UInt32)))
        
        let result = _encrypt(_values, key: key)
        return NSData(bytes: result, length: sizeof(UInt32)*2)
    }

    func encrypt(values: [UInt32]) -> NSData {
        let result = _encrypt(values, key: key)
        return NSData(bytes: result, length: sizeof(UInt32)*2)
    }
    
    func _encrypt(value : [UInt32], key: [UInt32]) -> [UInt32] {
        if (value.count != 2 || key.count != 4) {
            print("Bad value or key")
            return []
        }
        let delta : UInt32 = 0x9e3779b9
        
        var v0 : UInt32 = value[0]
        var v1 : UInt32 = value[1]
        var sum : UInt32 = 0
        
        for _ in 1...32 {
            sum = sum &+ delta
            
            let a = (v1 << 4) &+ key[0]
            let b = v1 &+ sum
            let c = (v1 >> 5) &+ key[1]
            v0 = v0 &+ (a ^ b ^ c)
            
            let d = (v0 << 4) &+ key[2]
            let e = v0 &+ sum
            let f = (v0 >> 5) &+ key[3]
            v1 = v1 &+ (d ^ e ^ f)
        }
        return [v0, v1]
    }
}