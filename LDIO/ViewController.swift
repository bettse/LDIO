//
//  ViewController.swift
//  LDIO
//
//  Created by Eric Betts on 9/27/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    var readerDriver : LegoReaderDriver = LegoReaderDriver.singleton
    @IBOutlet var scrollView: NSScrollView?
    
    var textField: NSTextView {
        get {
            return scrollView!.contentView.documentView as! NSTextView
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        /*
        readerDriver.registerTokenLoaded { (ledPlatform, nfcIndex, token) -> Void in
            let attr = NSAttributedString.init(string: "\(token.uid.hexadecimalString())\n")            
            self.textField.textStorage?.appendAttributedString(attr)
        }
        */

    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

