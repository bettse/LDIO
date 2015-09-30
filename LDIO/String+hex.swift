//
//  String+hex.swift
//  LDIO
//
//  Created by Eric Betts on 9/29/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation

public extension String {
    func asData() -> NSData {
        let selfArray = self.componentsSeparatedByString(" ")
        let selfBytes : [UInt8] = selfArray.map({UInt8($0, radix: 0x10)!})
        return NSData(bytes: selfBytes as [UInt8], length: selfBytes.count)
    }
}