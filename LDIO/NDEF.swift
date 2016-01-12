//
//  NDEF.swift
//  LDIO
//
//  Created by Eric Betts on 10/3/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation

enum TnfField : UInt8 {
    case Empty  = 0x00
    case NFC_RTD = 0x01 //Record Type Definition
    case RFC_2046 = 0x02
    case RFC_3986 = 0x03
    case NFC_RTD_EXT = 0x04
    case Unknown = 0x05
    case Unchanged = 0x06
    case Reserved = 0x07
}

enum NfcWkt : String {
    case DeviceInformation = "Di"
    case SmartPoster = "Sp"
    case Text = "T"
    case URI = "U"
    case GenericControl = "Gc"
    case HandoverRequest = "Hr"
    case HandoverSelect = "Hs"
    case HandoverCarrier = "Hc"
    case Signature = "Sig"
    case Unknown //Not standard
}

enum TlvType : UInt8 {
    case Null        = 0x00
    case LockControl = 0x01
    case MemControl  = 0x02
    case NDEF        = 0x03
    case Terminator  = 0xFE
};

class NDEF {
    static let magicByte : UInt8 = 0xE1
    
    //an NDEF message is a sequence of NDEF record
    class Message : CustomStringConvertible {
        var description: String {
            let me = String(self.dynamicType).componentsSeparatedByString(".").last!
            return "\(me)(\(ndefRecords))"
        }
        
        var data : NSData
        var ndefRecords : [NDEF.Record] = []
        
        init(data: NSData) {
            self.data = data
            var remainingData = data
            repeat {
                let tlv = NDEF.TLV(data: remainingData)
                if (tlv.type == .NDEF) {
                    let record = NDEF.Record(data: tlv.value)
                    ndefRecords.append(record)
                } else if (tlv.type == .Terminator) {
                    break //Stop looking
                }
                remainingData = remainingData.subdataWithRange(NSMakeRange(tlv.size, remainingData.length - tlv.size))
            } while (remainingData.length > 0)
        }
    }
    
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
    
    class Record : CustomStringConvertible {
        
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
        
        var tnf : TnfField {
            if let tnf = TnfField(rawValue: data[0] & 0x05) {
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
        var type : NfcWkt {
            var start = 3
            if (il) {
                start += 1
            }
            if (!sr) {
                start += 3
            }
            let typeData = data.subdataWithRange(NSMakeRange(start, Int(type_len)))
            let typeString = NSString(data: typeData, encoding: NSASCIIStringEncoding) as! String
            if let type = NfcWkt(rawValue: typeString) {
                return type
            }
            return .Unknown
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
            return "\(myName)(mb=\(mb) me=\(me) cf=\(cf) sr=\(sr) il=\(il) tnf=\(tnf) type=\(type) payload=\(record))"
        }
        
        var data : NSData
        var record : RTD.Abstract?
        
        init(data: NSData) {
            self.data = data
            switch (tnf) {
            case .NFC_RTD: //http://members.nfc-forum.org/specs/nfc_forum_assigned_numbers_register
                switch(type) {
                case .Text: //NFC Forum Text RTD
                    record = NDEF.RTD.Text(payload: payload)
                case .URI:
                    record = NDEF.RTD.URI(payload: payload)
                default:
                    print("Sorry, can't handle the type \(type) yet")
                }
            case .Empty:
                break;
            default:
                print("Unhandled type \(tnf)")
            }
        }
    }

    class RTD {
        class Abstract : CustomStringConvertible {
            var description: String {
                let myName = String(self.dynamicType).componentsSeparatedByString(".").last!
                return myName
            }
            
            var data : NSData
            
            init(payload: NSData) {
                data = payload
            }
        }
        class URI : Abstract {
            override var description: String {
                let myName = String(self.dynamicType).componentsSeparatedByString(".").last!
                return "\(myName)(unimplemented)"
            }
        }
        
        class Text : Abstract {
            override var description: String {
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
        }
    }
}



