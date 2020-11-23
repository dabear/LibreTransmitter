//
//  LibreTransmitterPlugin.swift
//  LibreTransmitterPlugin
//
//  Created by Nathaniel Hamming on 2019-12-19.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import Foundation
import LoopKitUI
import LibreTransmitter
import LibreTransmitterUI
import os.log

class LibreTransmitterPlugin: NSObject, LoopUIPlugin {
    
    private let log = OSLog(category: "LibreTransmitterPlugin")
    
    public var pumpManagerType: PumpManagerUI.Type? {
        return nil
    }
    
    public var cgmManagerType: CGMManagerUI.Type? {
        return LibreTransmitterManager.self
    }
    
    override init() {
        super.init()
        log.default("LibreTransmitterPlugin Instantiated")
    }
}
