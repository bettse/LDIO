//
//  UInt32+rotate.swift
//  LDIO
//
//  Created by Eric Betts on 1/11/16.
//  Copyright © 2016 Eric Betts. All rights reserved.
//

import Foundation

public extension UInt32 {
    func rotate(by: Int) -> UInt32 {
        if (by == 32) {
            return self
        }
        let s = UInt32(by)
        return (
            (
                (self) >> s) | ((self) << (32 - s)
            )
        )
    }

}