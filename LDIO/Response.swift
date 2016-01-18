//
//  Response.swift
//  DIMP
//
//  Created by Eric Betts on 6/19/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation

let HEX = 0x10

class Response : Message {
    let corrolationIdIndex = 0
    var corrolationId : UInt8 = 0
    let paramsIndex = 1
    var params : NSData = NSData()

    //lol delegate
    var type : commandType {
        get {
            return command.type
        }
    }
    
    var command : Command {
        get {
            return (Message.archive[corrolationId] as! Command)
        }
    }
    
    init(data: NSData) {
        super.init()
        data.getBytes(&corrolationId, range: NSMakeRange(corrolationIdIndex, sizeof(UInt8)))
        
    }
    
    static func parse(data: NSData) -> Response {
        let r : Response = Response(data: data)
        switch r.command.type {
        case .Activate:
            return ActivateResponse(data: data)
        case .Read:
            return ReadResponse(data: data)
        case .Write:
            return WriteResponse(data: data)
        case .Seed:
            return SeedResponse(data: data)
        case .Challenge:
            return ChallengeResponse(data: data)
        case .Presence:
            return PresenceResponse(data: data)
        case .Model:
            return ModelResponse(data: data)
        case .C1:
            return C1Response(data: data)
        case .LightOn:
            return LightOnResponse(data: data)
        case .LightFadeAll:
            return LightFadeAllResponse(data: data)
        case .LightFadeSingle:
            return LightFadeSingleResponse(data: data)
        case .LightFlashAll:
            return LightFlashAllResponse(data: data)
        case .LightFadeRandom:
            return LightFadeRandomResponse(data: data)
        case .C5:
            return C5Response(data: data)
        case .E1:
            return AuthModeResponse(data: data)
        default:
            print("unknown parse with data: \(data)")
            return Response(data: data)
        }
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(type.desc()))"
    }
}

class ActivateResponse : Response {
    override init(data: NSData) {
        super.init(data: data)
        params = data.subdataWithRange(NSMakeRange(paramsIndex, data.length - paramsIndex))
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(Response \(params))"
    }
}


class ReadResponse : Response {
    let pageDataIndex = 2
    var pageData : NSData
    
    //Delegates for easier access
    var pageNumber : UInt8  {
        get {
            if let command = command as? ReadCommand {
                return command.pageNumber
            }
            return 0
        }
    }
    var nfcIndex : UInt8  {
        get {
            if let command = command as? ReadCommand {
                return command.nfcIndex
            }
            return 0
        }
    }
    
    override init(data: NSData) {
        pageData = data.subdataWithRange(NSMakeRange(pageDataIndex, data.length-pageDataIndex))
        super.init(data: data)
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(Platform \(nfcIndex) page \(pageNumber): \(pageData))"
    }
}

class WriteResponse : Response {
    //Delegates for easier access
    var pageNumber : UInt8  {
        get {
            if let command = command as? WriteCommand {
                return command.pageNumber
            }
            return 0
        }
    }
    var nfcIndex : UInt8  {
        get {
            if let command = command as? WriteCommand {
                return command.nfcIndex
            }
            return 0
        }
    }
    
    override init(data: NSData) {
        super.init(data: data)
        params = data.subdataWithRange(NSMakeRange(paramsIndex, data.length - paramsIndex))
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(NFC \(nfcIndex) page \(pageNumber): \(params))"
    }
}

class SeedResponse : Response {
    let tea = TEA(key: LegoReaderDriver.usbTeaKey)
    var x : UInt32 = 0
    var y : UInt32 = 0
    
    override init(data: NSData) {
        super.init(data: data)
        params = data.subdataWithRange(NSMakeRange(paramsIndex, data.length - paramsIndex))
        let values : [UInt32] = tea.decrypt(params)
        x = values[0]
        y = values[1]
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(String(x, radix: 0x10)) \(String(y, radix: 0x10)))"
    }
}

class ChallengeResponse : Response {
    let tea = TEA(key: LegoReaderDriver.usbTeaKey)
    var x : UInt32 = 0
    var y : UInt32 = 0
    
    override init(data: NSData) {
        super.init(data: data)
        params = data.subdataWithRange(NSMakeRange(paramsIndex, data.length - paramsIndex))
        let values : [UInt32] = tea.decrypt(params)
        x = values[0]
        y = values[1]
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(String(x, radix: 0x10)) \(String(y, radix: 0x10)))"
    }
}

class PresenceResponse : Response {
    override init(data: NSData) {
        super.init(data: data)
        params = data.subdataWithRange(NSMakeRange(paramsIndex, data.length - paramsIndex))
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(params))"
    }
}


class ModelResponse : Response {
    let tea = TEA(key: LegoReaderDriver.usbTeaKey)
    var status : UInt8 = 0
    var modelId : UInt8 = 0
    var prng : UInt32 = 0
    
    override init(data: NSData) {
        super.init(data: data)
        params = data.subdataWithRange(NSMakeRange(paramsIndex, data.length - paramsIndex))
        status = params[0]
        let decoded : NSData = tea.decrypt(params.subdataWithRange(NSMakeRange(1, 8)))
        modelId = decoded[0]
        decoded.getBytes(&prng, range: NSMakeRange(1, 3))
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(Status:\(status) model:\(modelId) prng = \(prng))"
    }
}

class LightOnResponse : Response {}
class LightFadeAllResponse : Response {}
class LightFadeSingleResponse : Response {}
class LightFlashAllResponse : Response {}
class LightFadeRandomResponse : Response {}

class AuthModeResponse : Response {
    var nfcIndex : UInt8  {
        get {
            if let command = command as? AuthModeCommand {
                return command.nfcIndex
            }
            return 0
        }
    }
    
    var pack : UInt16 = 0
    
    override init(data: NSData) {
        super.init(data: data)
        params = data.subdataWithRange(NSMakeRange(paramsIndex, data.length - paramsIndex))
        
        //The first byte is 0 for valid nfc index, 0x38 for invalid index
        params.getBytes(&pack, range: NSMakeRange(1, sizeof(UInt16)))
        self.pack = self.pack.byteSwapped
        //optional 4th byte when PWD failed
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(#\(String(self.nfcIndex, radix: HEX)) PACK: \(String(self.pack, radix: HEX)))"
    }
}

class C5Response : Response {
    override init(data: NSData) {
        super.init(data: data)
        params = data.subdataWithRange(NSMakeRange(paramsIndex, data.length - paramsIndex))
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(params))"
    }
}

class C1Response : Response {
    override init(data: NSData) {
        super.init(data: data)
        params = data.subdataWithRange(NSMakeRange(paramsIndex, data.length - paramsIndex))
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(params))"
    }
}
