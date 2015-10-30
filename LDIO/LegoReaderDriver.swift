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

    func seedTest(value: UInt64) {
        var seedValue = value
        let seedData = NSMutableData(length: sizeof(seedValue.dynamicType))
        seedData?.replaceBytesInRange(NSMakeRange(0, sizeof(seedValue.dynamicType)), withBytes: &seedValue)
        let cmd = SeedCommand(data: NSData(data: seedData!))
        print(cmd)
        reader.outputCommand(cmd)
    }
    
    func challengeTest() {
        let challengeData = NSMutableData(length: sizeof(challengeValue.dynamicType))
        challengeData?.replaceBytesInRange(NSMakeRange(0, sizeof(challengeValue.dynamicType)), withBytes: &challengeValue)
        let cmd = ChallengeCommand(data: NSData(data: challengeData!))
        print(cmd)
        reader.outputCommand(cmd)
    }

    func d4Test() {
        var date = NSDate().timeIntervalSince1970
        //let d4data = NSData(fromHex: "e6 66 65 19 e5 bc 04 cb")
        //let d4data = NSData(fromHex: "bb c9 3a 1b bc df e1 4d")
        let d4data = NSMutableData(length: sizeof(d4Value.dynamicType))
        //d4data?.replaceBytesInRange(NSMakeRange(0, sizeof(d4Value.dynamicType)), withBytes: &d4Value)
        d4data?.replaceBytesInRange(NSMakeRange(0, sizeof(date.dynamicType)), withBytes: &date)
        let cmd = D4Command(data: NSData(data: d4data!))
        print(cmd)
        reader.outputCommand(cmd)
    }

    
    func incomingResponse(response: Response) {
        if let _ = response as? ActivateResponse {
            print(response)
        } else if let response = response as? SeedResponse {
            print(response)
            /*
            let center = Fade(speed: 1, count: 1, color: NSColor.redColor())
            let left = Fade(speed: 1, count: 1, color: NSColor.greenColor())
            let right = Fade(speed: 1, count: 1, color: NSColor.blueColor())
            reader.outputCommand(LightFadeAllCommand(center: center, left: left, right: right))
            */
        } else if let response = response as? ChallengeResponse {
            print(response)
        } else if let response = response as? ReadResponse {
            tokenRead(response)
        } else if let response = response as? WriteResponse {
            //Re-read the written page
            reader.outputCommand(ReadCommand(nfcIndex: response.nfcIndex, page: response.pageNumber))
        } else if let response = response as? D4Response {
            print(response)
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

                let writeVg = false
                if (writeVg) {
                    var vgtype : UInt32 = 1081
                    let data : NSMutableData = NSMutableData(capacity: NTAG213.pageSize)!
                    data.replaceBytesInRange(NSMakeRange(0, sizeof(vgtype.dynamicType)), withBytes: &vgtype)
                    let write = WriteCommand(nfcIndex: response.nfcIndex, page: 0x24, data: NSData(data: data))
                    reader.outputCommand(write)
                }
                
                let writeType = false
                if (writeType) {
                    var t : UInt16 = UInt16(1).bigEndian
                    let tdata : NSMutableData = NSMutableData(length: NTAG213.pageSize)!
                    tdata.replaceBytesInRange(NSMakeRange(0, sizeof(t.dynamicType)), withBytes: &t)
                    let write = WriteCommand(nfcIndex: response.nfcIndex, page: 0x26, data: NSData(data: tdata))
                    reader.outputCommand(write)
                }
                partialTokens.removeValueForKey(response.nfcIndex)
            } else {
                reader.outputCommand(ReadCommand(nfcIndex: response.nfcIndex, page: token.nextPage()))
            }
        } //end if token
    }
}