//
//  LegoReaderDriver.swift
//  LDIO
//
//  Created by Eric Betts on 9/28/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation
import AppKit


typealias tokenLoad = (Message.LedPlatform, Int, NTAG213) -> Void
typealias tokenLeft = (Message.LedPlatform, Int) -> Void

class LegoReaderDriver : NSObject {
    static let singleton = LegoReaderDriver()
    static let magic : NSData = "(c) LEGO 2014".dataUsingEncoding(NSASCIIStringEncoding)!
    static let emptyResponse = NSData(bytes: [UInt8](count: NTAG213.pageSize * 4, repeatedValue: 0), length: NTAG213.pageSize * 4)

    var reader : LegoReader = LegoReader.singleton
    var readerThread : NSThread?
    
    var loadTokenCallbacks : [tokenLoad] = []
    var leftTokenCallbacks : [tokenLeft] = []

    var partialTokens : [UInt8:NTAG213] = [:]

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
            let token = NTAG213(tagId: update.uid)
            dispatch_async(dispatch_get_main_queue(), {
                for callback in self.loadTokenCallbacks {
                    callback(update.ledPlatform, Int(update.nfcIndex), token)
                }
            })
            partialTokens[update.nfcIndex] = token
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
        var seedValue = value.bigEndian
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
    
    func incomingResponse(response: Response) {
        if let _ = response as? ActivateResponse {
            print(response)
        } else if let response = response as? SeedResponse {
            print(response)
        } else if let response = response as? ChallengeResponse {
            print(response)
        } else if let response = response as? ReadResponse {
            tokenRead(response)
        } else if let response = response as? WriteResponse {
            //Re-read the written page
            reader.outputCommand(ReadCommand(nfcIndex: response.nfcIndex, page: response.pageNumber))
        } else if let response = response as? D4Response {
            print(response)
        } else if let response = response as? E1Response {
            print(response)
        } else if let response = response as? LightOnResponse {
            print(response)
        } else {
            print("Received \(response) for command \(response.command)")
        }
    }
    
    func tokenRead(response: ReadResponse) {
        if let token = partialTokens[response.nfcIndex] {
            if (response.pageNumber == 0 && response.pageData.isEqualToData(LegoReaderDriver.emptyResponse)) {
                print("Halting token read due to empty page 0")
                return
            }
            token.load(response.pageNumber, pageData: response.pageData)
            if (token.complete()) {
                tokenComplete(token, nfcIndex: response.nfcIndex)
                partialTokens.removeValueForKey(response.nfcIndex)
            } else {
                reader.outputCommand(ReadCommand(nfcIndex: response.nfcIndex, page: token.nextPage()))
            }
        } //end if token
    }
    
    func tokenComplete(token: NTAG213, nfcIndex: UInt8) {
        if token.isNdef {
            let message = NdefMessage(data: token.ndefData)
            print("Complete token: \(message.ndefRecords)")
        }

    }
}