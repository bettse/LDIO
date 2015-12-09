//
//  String+hex.swift
//  LDIO
//
//  Created by Eric Betts on 9/29/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation

public extension NSData {
    convenience init(fromHex: String) {
        
        let hexArray = fromHex.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).componentsSeparatedByString(" ")
        let hexBytes : [UInt8] = hexArray.map({UInt8($0, radix: 0x10)!})
        self.init(bytes: hexBytes as [UInt8], length: hexBytes.count)
        
    }
    
    subscript(origin: Int) -> UInt8 {
        get {
            var result: UInt8 = 0;
            if (origin < self.length) {
                self.getBytes(&result, range: NSMakeRange(origin, 1))
            }
            return result
        }
    }
    
    func hexadecimalString() -> String {
        let s = "\(self)".componentsSeparatedByString(" ").joinWithSeparator("").stringByTrimmingCharactersInSet(NSCharacterSet.init(charactersInString: "< >"))
        return s
    }
}