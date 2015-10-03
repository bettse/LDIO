//
//  Report.swift
//  DIMP
//
//  Created by Eric Betts on 6/19/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation

//All data sent across USB is a 'Report'.  It always starts with a byte like 0xff/0xaa/0xab and ends with a summation checksum
//Sometimes the Reports are from device and need to be parsed, othertimes they're constructed and then need to be serialized



class Report {
    let typeIndex = 0
    let lengthIndex = 1
    let contentIndex = 2
    
    enum MessageType : UInt8 {
        case Unset = 0x00
        case Command = 0x55
        case Update = 0x56
        func desc() -> String {
            return String(self).componentsSeparatedByString(".").last!
        }
    }
    
    var type : MessageType = .Unset
    var length = 0 //TODO: Convert to use getting/setter

    var content : Message? = nil // (command, response, update)

    var checksum : UInt8 {
        get {
            var sum = Int(type.rawValue)
            if let content = content as? Command {
                let b = UnsafeBufferPointer<UInt8>(start: UnsafePointer(content.serialize().bytes), count: length)
                
                for i in 0..<length {
                    sum += Int(b[i])
                }
            }
        
            return UInt8((sum + length) & 0xff)
        }
        set(newChecksum) {
            
        }
    }
    
    //Only used for incoming
    init(input: NSData) {
        input.getBytes(&type, range: NSMakeRange(typeIndex, sizeof(MessageType)))
        input.getBytes(&length, range: NSMakeRange(lengthIndex, sizeof(UInt8)))
        input.getBytes(&checksum, range: NSMakeRange(lengthIndex + length, sizeof(UInt8)))
        
        //print("report with \(type.desc()) \(length) \(checksum)")
        
        if (type == .Update) {
            content = Update(data: input.subdataWithRange(NSMakeRange(contentIndex, length)))
        } else if (type == .Command) {
            //Command value is re-used for response when message is incoming
            //Using parse to get back a Response subclass
            content = Response.parse(input.subdataWithRange(NSMakeRange(contentIndex, length)))
        }

    }
    

    init(cmd: Command) {
        content = cmd
        type = .Command
        length = cmd.serialize().length
    }
    
    var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)::\(content!)"
    }
    
    func serialize() -> NSData {
        //Only applies to Command
        //Assumes checksum, length, type are already set
        if (content is Command) {
            let command = content as! Command
            let data = NSMutableData(length: 0x20)
            var rawType : UInt8 = type.rawValue
            if let data = data {
                data.replaceBytesInRange(NSMakeRange(typeIndex, sizeof(UInt8)), withBytes: &rawType)
                data.replaceBytesInRange(NSMakeRange(lengthIndex, sizeof(UInt8)), withBytes: &length)
                data.replaceBytesInRange(NSMakeRange(contentIndex, length), withBytes: command.serialize().bytes)
                data.replaceBytesInRange(NSMakeRange(contentIndex + length, sizeof(UInt8)), withBytes: &checksum)
                return data
            }
        }

        return NSData()
    }
}