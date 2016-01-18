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
    static let usbTeaKey : [UInt32] = [0x30f6fe55, 0xc10bbf62, 0x347cb3c9, 0xfb293e97]

    var reader : LegoReader = LegoReader.singleton
    var readerThread : NSThread?
    
    var loadTokenCallbacks : [tokenLoad] = []
    var leftTokenCallbacks : [tokenLeft] = []

    var partialTokens : [UInt8:NTAG213] = [:]
    let tea : TEA = TEA(key: LegoReaderDriver.usbTeaKey)
    let mb = ModifiedBurtle(seed: 0)
    
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
            let token = Token(tagId: update.uid)
            dispatch_async(dispatch_get_main_queue(), {
                for callback in self.loadTokenCallbacks {
                    callback(update.ledPlatform, Int(update.nfcIndex), token)
                }
            })
            partialTokens[update.nfcIndex] = token
            //Try to read assuming LD PWD
            reader.outputCommand(ReadCommand(nfcIndex: update.nfcIndex, page: 0))
        } else if (update.direction == Update.Direction.Departing) {
            dispatch_async(dispatch_get_main_queue(), {
                for callback in self.leftTokenCallbacks {
                    callback(update.ledPlatform, Int(update.nfcIndex))
                }
            })
        }
    }
    
    func incomingResponse(response: Response) {
        if let _ = response as? ActivateResponse {
            print(response)
        } else if let response = response as? SeedResponse {
            print(response)
        } else if let response = response as? ChallengeResponse {
            print(response)
        } else if let response = response as? ReadResponse {
            if (response.pageNumber == 0 && response.pageData.isEqualToData(LegoReaderDriver.emptyResponse)) {
                //Try using NTAG213 default PWD
                print("Page \(response.pageNumber) failed, attempting using 0xFFFFFFFF PWD")
                reader.outputCommand(AuthModeCommand(nfcIndex: response.nfcIndex, mode: AuthModeCommand.AuthMode.dev, pwd: 0xFFFFFFFF))
            } else {
                tokenRead(response)
            }
        } else if let response = response as? WriteResponse {
            print(response)
        } else if let response = response as? ModelResponse {
            print(response)
        } else if let response = response as? AuthModeResponse {
            print(response)
            if (response.params.length == 3) { //success
                reader.outputCommand(ReadCommand(nfcIndex: response.nfcIndex, page: 0))
            } else {
                print("E1 failed and returned \(response.params)")
                reader.outputCommand(AuthModeCommand(nfcIndex: response.nfcIndex, mode: AuthModeCommand.AuthMode.normal, pwd: 0))
            }
        } else if let response = response as? LightOnResponse {
            print(response)
        } else {
            print("Received \(response) for command \(response.command)")
        }
    }
    
    func tokenRead(response: ReadResponse) {
        if let token = partialTokens[response.nfcIndex] {
            token.load(response.pageNumber, pageData: response.pageData)
            if (token.complete()) {
                tokenComplete(token as! Token, nfcIndex: response.nfcIndex)
                partialTokens.removeValueForKey(response.nfcIndex)
            } else {
                reader.outputCommand(ReadCommand(nfcIndex: response.nfcIndex, page: token.nextPage()))
            }
        } //end if token
    }
    
    func tokenComplete(token: Token, nfcIndex: UInt8) {
        print("Token complete: PWD = \(token.pwd)")
        /*
        if (ldToken.category == 0) {
            print("Minifig: \(ldToken.minifigId)")
            if (ldToken.minifigId > 0xFF) {
                ldToken.minifigId = 39 //40 = superman
                reader.outputCommand(WriteCommand(nfcIndex: nfcIndex, page: 0x24, data: ldToken.page(0x24)))
                reader.outputCommand(WriteCommand(nfcIndex: nfcIndex, page: 0x25, data: ldToken.page(0x25)))
            }
        }
        */
    }
}
