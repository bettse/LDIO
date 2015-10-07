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

struct near_ndef_record_header {
    var mb : UInt8
    var me: UInt8
    var cf: UInt8
    var sr: UInt8
    var il: UInt8
    var tnf: UInt8
    var il_length: UInt8
    var il_field: UInt8
    var payload_len : UInt32
    var offset : UInt32
    var type_len: UInt8
    var rec_type : record_type
    var type_name : String
    var header_len : UInt32
}

struct near_ndef_text_payload {
    var encoding : String
    var language_code : String
    var data : String
};

class NDEF {
    
    var data : NSData
    
    init(data: NSData) {
        self.data = data
    }
    
    
}