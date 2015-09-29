//
//  Message.swift
//  LDIO
//
//  Created by Eric Betts on 9/28/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation
/*
VVLLPPXXDDTTTTTTTTTTTTTTCC
VV = 'V' literal
LL = length
PP = Platform (1 = center, 2 = left, 3 = right)
XX = ??
DD = direction (0 = arriving, 1 = departing)
TTTTTTTTTTTTTT = Tag UID
CC = I haven't done the math, but I hypothesize this is a checksum
*/

class Message : CustomStringConvertible {
    var data : NSData
    
    var type : UInt8 {
        get {
            let offset = 0
            var value : UInt8 = 0
            let size = sizeof(value.dynamicType)
            data.getBytes(&value, range: NSMakeRange(offset, size))
            return value
        }
    }
    
    var length : UInt8 {
        get {
            let offset = 1
            var value : UInt8 = 0
            let size = sizeof(value.dynamicType)
            data.getBytes(&value, range: NSMakeRange(offset, size))
            return value
        }
    }

    //Make into an enum
    var direction : UInt8 {
        get {
            let offset = 5
            var value : UInt8 = 0
            let size = sizeof(value.dynamicType)
            data.getBytes(&value, range: NSMakeRange(offset, size))
            return value
        }
    }
    
    var uid : NSData {
        get {
            let offset = 6
            let length = 7
            let range = NSMakeRange(offset, length)
            return data.subdataWithRange(range)
        }
    }
    
    init(data: NSData) {
        self.data = data
    }
    
    var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(uid \(uid) in direction \(direction))"
    }
    

}
