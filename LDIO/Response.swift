//
//  Response.swift
//  DIMP
//
//  Created by Eric Betts on 6/19/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation

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
        case .D4:
            return D4Response(data: data)
        case .LightOn:
            return LightOnResponse(data: data)
        case .LightFadeAll:
            return LightFadeAllResponse(data: data)
        case .LightFadeSingle:
            return LightFadeSingleResponse(data: data)
        case .LightFlashAll:
            return LightFlashAllResponse(data: data)
        case .C4:
            return C4Response(data: data)
        case .E1:
            return E1Response(data: data)
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
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(NFC \(nfcIndex) page \(pageNumber))"
    }
}

class SeedResponse : Response {
    override init(data: NSData) {
        super.init(data: data)
        params = data.subdataWithRange(NSMakeRange(paramsIndex, data.length - paramsIndex))
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(params))"
    }
}

class ChallengeResponse : Response {
    override init(data: NSData) {
        super.init(data: data)
        params = data.subdataWithRange(NSMakeRange(paramsIndex, data.length - paramsIndex))
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(params))"
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


class D4Response : Response {
    override init(data: NSData) {
        super.init(data: data)
        params = data.subdataWithRange(NSMakeRange(paramsIndex, data.length - paramsIndex))
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(params))"
    }
}

class LightOnResponse : Response {}
class LightFadeAllResponse : Response {}
class LightFadeSingleResponse : Response {}
class LightFlashAllResponse : Response {}
class C4Response : Response {}

class E1Response : Response {
    override init(data: NSData) {
        super.init(data: data)
        params = data.subdataWithRange(NSMakeRange(paramsIndex, data.length - paramsIndex))
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(params))"
    }
}
