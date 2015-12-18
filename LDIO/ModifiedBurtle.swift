//
//  ModifiedBurtle.swift
//  LDIO
//
//  Created by Eric Betts on 12/17/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation

class ModifiedBurtle {
    var a : UInt32 = 0xf1ea5eed
    var b : UInt32 = 0
    var c : UInt32 = 0
    var d : UInt32 = 0
    let startingIterations = 42
    
    init(seed: UInt32) {
        b = seed
        c = seed
        d = seed
        for _ in 1...startingIterations {
            self.value()
        }
    }
    
    convenience init(seed: Int) {
        let s : UInt32 = UInt32(seed)
        self.init(seed: s)
    }
    
    func rot(x: UInt32, k: UInt32) -> UInt32 {
        return UInt32(
            ( x << k ) | ( x >> (32 - k) )
        )
    }
    
    func value() -> UInt32 {
        //&+ / &- are swift's overflow operators.  By default, overflows are an error
        let e : UInt32 = a &- rot(b, k: 21)
        a = b ^ rot(c, k: 19)
        b = c &+ rot(d, k: 6)
        c = d &+ e
        d = e &+ a
        return d
    }
}