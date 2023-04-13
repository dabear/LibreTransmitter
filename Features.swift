//
//  Features.swift
//  LibreTransmitter
//
//  Created on 30/08/2021.
//  Copyright © 2021 LoopKit Authors. All rights reserved.
//

import Foundation

#if canImport(CoreNFC)
import CoreNFC
#endif

public final class Features {

    static public var logSubsystem = "com.loopkit.libre"
    
    static public var glucoseSettingsRequireAuthentication = false
    static public var alarmSettingsViewRequiresAuthentication = false
    
    static public var allowsEditingFactoryCalibrationData = false
    
    // Only to be used with this program, running on a linux amd64 system or rasberry pi
    // https://github.com/tzachi-dar/gatt#this-is-a-program-for-creating-a-simulation-for-libre-2-for-xdrip
    static public var supportsFakeSensor = false

    static var phoneNFCAvailable: Bool {
        #if canImport(CoreNFC)
        if NSClassFromString("NFCNDEFReaderSession") == nil {
            return false

        }

        return NFCNDEFReaderSession.readingAvailable
        #else
        return false
        #endif
    }

}
