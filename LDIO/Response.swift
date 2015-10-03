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
        default:
            print("par with data: \(data)")
            return Response(data: data)
        }
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(type.desc()))"
    }
}

class ActivateResponse : Response {
    var params : NSData
    let paramsIndex = 1
    
    override init(data: NSData) {
        params = data.subdataWithRange(NSMakeRange(paramsIndex, data.length - paramsIndex))
        super.init(data: data)
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

