//
//  NSColor+hex.swift
//  LDIO
//
//  Created by Eric Betts on 10/9/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation
import Cocoa

extension NSColor {
    var red: UInt8 {
        return UInt8(round(self.redComponent * 0xFF))
    }
    
    var green: UInt8 {
        return UInt8(round(self.greenComponent * 0xFF))
    }
    
    var blue: UInt8 {
        return UInt8(round(self.blueComponent * 0xFF))
    }
}