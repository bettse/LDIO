//
//  LegoReaderDriver.swift
//  LDIO
//
//  Created by Eric Betts on 9/28/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation
import AppKit


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
    
    var seedValue : UInt64 = 0
    var challengeValue : UInt64 = 0
    var d4Value : UInt64 = 0
    
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
        print(update)
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

    func seedTest() {
        let seedData = NSMutableData(length: sizeof(seedValue.dynamicType))
        seedData?.replaceBytesInRange(NSMakeRange(0, sizeof(seedValue.dynamicType)), withBytes: &seedValue)
        reader.outputCommand(SeedCommand(data: NSData(data: seedData!)))
    }
    
    func challengeTest() {
        let challengeData = NSMutableData(length: sizeof(challengeValue.dynamicType))
        challengeData?.replaceBytesInRange(NSMakeRange(0, sizeof(challengeValue.dynamicType)), withBytes: &challengeValue)
        reader.outputCommand(ChallengeCommand(data: NSData(data: challengeData!)))
    }

    func d4Test() {
        let d4data = NSMutableData(length: sizeof(d4Value.dynamicType))
        d4data?.replaceBytesInRange(NSMakeRange(0, sizeof(d4Value.dynamicType)), withBytes: &d4Value)
        reader.outputCommand(D4Command(data: NSData(data: d4data!)))
        d4Value++
    }

    
    func incomingResponse(response: Response) {
        if let _ = response as? ActivateResponse {
            print(response)
            let center = Fade(speed: 1, count: 1, color: NSColor.redColor())
            let left = Fade(speed: 1, count: 1, color: NSColor.greenColor())
            let right = Fade(speed: 1, count: 1, color: NSColor.blueColor())
            reader.outputCommand(LightFadeAllCommand(center: center, left: left, right: right))
        } else if let response = response as? ReadResponse {
            tokenRead(response)
        } else if let response = response as? SeedResponse {
            print(response)
        } else if let response = response as? ChallengeResponse {
            print(response)
        } else if let _ = response as? D4Response {

        } else {
            print("Received \(response) for command \(response.command)", terminator: "\n")
        }
    }
    
    func tokenRead(response: ReadResponse) {
        if let token = partialTokens[response.nfcIndex] {
            //print("\(response.pageNumber): \(response.pageData)")
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