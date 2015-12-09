//
//  NDEF.swift
//  LDIO
//
//  Created by Eric Betts on 10/3/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation

enum record_type : UInt8 {
    case RECORD_TYPE_WKT_SMART_POSTER          =   0x01
    case RECORD_TYPE_WKT_URI                   =   0x02
    case RECORD_TYPE_WKT_TEXT                  =   0x03
    case RECORD_TYPE_WKT_SIZE                  =   0x04
    case RECORD_TYPE_WKT_TYPE                  =   0x05
    case RECORD_TYPE_WKT_ACTION                =   0x06
    case RECORD_TYPE_WKT_HANDOVER_REQUEST      =   0x07
    case RECORD_TYPE_WKT_HANDOVER_SELECT       =   0x08
    case RECORD_TYPE_WKT_HANDOVER_CARRIER      =   0x09
    case RECORD_TYPE_WKT_ALTERNATIVE_CARRIER   =   0x0a
    case RECORD_TYPE_WKT_COLLISION_RESOLUTION  =   0x0b
    case RECORD_TYPE_WKT_ERROR                 =   0x0c
    case RECORD_TYPE_MIME_TYPE                 =   0x0d
    case RECORD_TYPE_EXT_AAR                   =   0x0e
    case RECORD_TYPE_UNKNOWN                   =   0xfe
    case RECORD_TYPE_ERROR                     =   0xff
}

enum tnf_field_values : UInt8 {
    case Empty  = 0x00
    case NFC_RTD = 0x01
    case RFC_2046 = 0x02
    case RFC_3986 = 0x03
    case NFC_RTD_EXT = 0x04
    case Unknown = 0x05
    case Unchanged = 0x06
    case Reserved = 0x07
}

class NdefRecord : CustomStringConvertible {

    var mb : Bool {
        return (data[0] & 0x80 == 0x80)
    }
    var me : Bool {
        return (data[0] & 0x40 == 0x40)
    }
    var cf : Bool {
        return (data[0] & 0x20 == 0x20)
    }
    var sr : Bool {
        return (data[0] & 0x10 == 0x10)
    }
    var il : Bool {
        return (data[0] & 0x08 == 0x08)
    }
    
    var tnf : tnf_field_values {
        if let tnf = tnf_field_values(rawValue: data[0] & 0x05) {
            return tnf
        } else {
            return .Unknown
        }
    }
    
    var type_len: UInt8 {
        return data[1]
    }
    
    var payload_len : UInt32 {
        if (sr) {
            return UInt32(data[2])
        } else {
            var y: UInt32 = 0
            y += UInt32(data[5]) << 0x18
            y += UInt32(data[4]) << 0x10
            y += UInt32(data[3]) << 0x08
            y += UInt32(data[2]) << 0x00
            return y
        }
    }
    var id_len : UInt8 {
        if (il) {
            if (sr) {
                return data[3]
            } else {
                return data[6]
            }
        } else {
            return 0
        }
    }
    var type : String {
        var start = 3
        if (il) {
            start += 1
        }
        if (!sr) {
            start += 3
        }
        return NSString(data: data.subdataWithRange(NSMakeRange(start, Int(type_len))), encoding: NSASCIIStringEncoding) as! String
    }
    var id : NSData {
        if (il && id_len > 0) {
            var start = 2
            if (!sr) {
                start += 3
            }
            start += Int(type_len)
            return data.subdataWithRange(NSMakeRange(start, Int(id_len)))
        } else {
            return NSData()
        }
    }
    
    var payload : NSData {
        var start = 2
        if (sr) {
            start += 1
        } else {
            start += 4
        }
        if (il) {
            start += 1 + Int(id_len)
        }
        start += Int(type_len)
        let length = Int(payload_len)
        if (start + length > data.length) {
            print("Oh shit")
            return NSData()
        }
        return data.subdataWithRange(NSMakeRange(start, length))
    }
    
    var description: String {
        let myName = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(myName)(mb=\(mb) me=\(me) cf=\(cf) sr=\(sr) il=\(il) tnf=\(tnf) type=\(type) record=\(record))"
    }
    
    var data : NSData
    var record : AnyObject = []
    
    init(data: NSData) {
        self.data = data
        switch (tnf) {
        case .NFC_RTD: //http://members.nfc-forum.org/specs/nfc_forum_assigned_numbers_register
            //print("Well known type: \(type)")
            switch(type) {
            case "T": //NFC Forum Text RTD
                record = NDEF.TextRecord(payload: payload)
            default:
                print("Sorry, can't handle the type \(type) yet")
            }
        default:
            print("Unhandled type \(tnf)")
        }
    }
}

enum TlvType : UInt8 {
    case Null        = 0x00
    case LockControl = 0x01
    case MemControl  = 0x02
    case NDEF        = 0x03
    case Terminator  = 0xFE
};


struct near_ndef_text_payload {
    var encoding : String
    var language_code : String
    var data : String
}

class NDEF {
    static let magicByte : UInt8 = 0xE1
    class TLV : CustomStringConvertible {
        var type : TlvType = .Null
        var length : UInt8
        var value : NSData
        var size : Int {
            return Int(length) + 2
        }
        
        var description: String {
            let myName = String(self.dynamicType).componentsSeparatedByString(".").last!
            return "\(myName)(type=\(type) length=\(length) value=\(value))"
        }
        
        init(data: NSData) {
            if let type = TlvType(rawValue: data[0]) {
                self.type = type
            }
            length = data[1]
            value = data.subdataWithRange(NSMakeRange(2, Int(length)))
        }
    }
    
    class TextRecord : CustomStringConvertible {
        var description: String {
            let myName = String(self.dynamicType).componentsSeparatedByString(".").last!
            return "\(myName)(\(lang): \(content))"
        }
        
        var statusByte : UInt8 {
            return data[0]
        }
        
        var langLen : UInt8 {
            return statusByte & 0x3F //bits 5..0
        }
        
        var encoding : NSStringEncoding {
            if (statusByte & 0x80 == 0x80) {
                return NSUTF16StringEncoding
            } else {
                return NSUTF8StringEncoding
            }
        }
        
        var lang : String {
            let langData = data.subdataWithRange(NSMakeRange(1, Int(langLen)))
            return NSString(data: langData, encoding: NSASCIIStringEncoding) as! String
        }
        
        var content : String {
            let start = Int(langLen) + 1
            let length = data.length - start
            let contentData = data.subdataWithRange(NSMakeRange(start, length))
            return NSString(data: contentData, encoding: encoding) as! String
        }
        
        var data : NSData
        
        init(payload: NSData) {
            data = payload
        }
    }
}

//an NDEF message is a sequence of NDEF record
class NdefMessage : CustomStringConvertible {
    var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(data))"
    }
    
    var data : NSData
    var ndefRecords : [NdefRecord] = []
    
    init(data: NSData) {
        self.data = data
        var remainingData = data
        repeat {
            let tlv = NDEF.TLV(data: remainingData)
            print(tlv)
            if (tlv.type == .NDEF) {
                let record = NdefRecord(data: tlv.value)
                ndefRecords.append(record)
            } else if (tlv.type == .Terminator) {
                break //Stop looking
            }
            remainingData = remainingData.subdataWithRange(NSMakeRange(tlv.size, remainingData.length - tlv.size))
        } while (remainingData.length > 0)
    }
    
}

