//
//  LegoReaderDriver.swift
//  LDIO
//
//  Created by Eric Betts on 9/28/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation

typealias tokenLoad = (Message.LedPlatform, Int, Token) -> Void
typealias tokenLeft = (Message.LedPlatform, Int) -> Void

class LegoReaderDriver : NSObject {
    static let singleton = LegoReaderDriver()
    static let magic : NSData = "(c) LEGO 2014".dataUsingEncoding(NSASCIIStringEncoding)!

    var reader : LegoReader = LegoReader.singleton
    var readerThread : NSThread?
    
    var loadTokenCallbacks : [tokenLoad] = []
    var leftTokenCallbacks : [tokenLeft] = []

    var partialTokens : [UInt8:Token] = [:]
    
    var b1Value : UInt64 = 1

    override init() {
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "deviceConnected:", name: "deviceConnected", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "incomingMessage:", name: "incomingMessage", object: nil)

        readerThread = NSThread(target: reader, selector:"initUsb", object: nil)
        if let thread = readerThread {
            thread.start()
        }
    }
    
    func registerTokenLoaded(callback: tokenLoad) {
        loadTokenCallbacks.append(callback)
    }
    func registerTokenLeft(callback: tokenLeft) {
        leftTokenCallbacks.append(callback)
    }
    
    func deviceConnected(notification: NSNotification) {
        print("Device connected, activating")
        reader.outputCommand(ActivateCommand())
    }
    
    func incomingMessage(notification: NSNotification) {
        let userInfo = notification.userInfo
        if let message = userInfo?["message"] as? Message {
            if let update = message as? Update {
                incomingUpdate(update)
            } else if let response = message as? Response {
                incomingResponse(response)
            }
        } else {
            print("incomingMessage event had no message in \(userInfo)")
        }
    }
    
    func incomingUpdate(update: Update) {
        if (update.direction == Update.Direction.Arriving) {
            partialTokens[update.nfcIndex] = Token(tagId: update.uid)
            reader.outputCommand(ReadCommand(nfcIndex: update.nfcIndex, page: 0))
        } else if (update.direction == Update.Direction.Departing) {
            dispatch_async(dispatch_get_main_queue(), {
                for callback in self.leftTokenCallbacks {
                    callback(update.ledPlatform, Int(update.nfcIndex))
                }
            })
        }
    }

    func b1Test() {
        let b1data = NSMutableData(length: sizeof(b1Value.dynamicType))
        b1data?.replaceBytesInRange(NSMakeRange(0, sizeof(b1Value.dynamicType)), withBytes: &b1Value)
        reader.outputCommand(B1Command(data: NSData(data: b1data!)))
        /*
        if (b1Value == 0) {
            b1Value = UInt64.max
        } else {
            b1Value = 0
        }
        */
        b1Value *= 2
    }
    
    func incomingResponse(response: Response) {
        if let _ = response as? ActivateResponse {
            print(response)
            //Start testing b1 command
            //NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: "b1Test", userInfo: nil, repeats: true)
        } else if let response = response as? ReadResponse {
            tokenRead(response)
        } else {
            print("Received \(response) for command \(response.command)", terminator: "\n")
        }
    }
    
    func tokenRead(response: ReadResponse) {
        if let token = partialTokens[response.nfcIndex] {
            token.load(response.pageNumber, pageData: response.pageData)
            if (token.complete()) {
                print("Complete token: \(token)")
                dispatch_async(dispatch_get_main_queue(), {
                    for callback in self.loadTokenCallbacks {
                        callback(Message.LedPlatform.All, Int(response.nfcIndex), token)
                    }
                })
                /*
                var vgtype : UInt32 = 1015
                let data : NSMutableData = NSMutableData(capacity: sizeof(vgtype.dynamicType))!
                data.replaceBytesInRange(NSMakeRange(0, sizeof(vgtype.dynamicType)), withBytes: &vgtype)
                let write = WriteCommand(nfcIndex: response.nfcIndex, page: 0x24, data: NSData(data: data))
                reader.outputCommand(write)
                */
                partialTokens.removeValueForKey(response.nfcIndex)
            } else {
                reader.outputCommand(ReadCommand(nfcIndex: response.nfcIndex, page: token.nextPage()))
            }
        } //end if token
    }
}