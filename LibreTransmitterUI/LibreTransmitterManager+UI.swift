//
//  LibreTransmitterManager+UI.swift
//  Loop
//
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import SwiftUI
import LoopKit
import LoopKitUI
import HealthKit
import LibreTransmitter

extension LibreTransmitterManager: CGMManagerUI {
    public static func setupViewController(glucoseTintColor: Color, guidanceColors: GuidanceColors) -> (UIViewController & CGMManagerSetupViewController & CompletionNotifying)? {
        LibreTransmitterSetupViewController()
    }

    public func settingsViewController(for glucoseUnit: HKUnit, glucoseTintColor: Color, guidanceColors: GuidanceColors) -> (UIViewController & CompletionNotifying) {
        let settings = LibreTransmitterSettingsViewController(cgmManager: self, glucoseUnit: glucoseUnit, allowsDeletion: true)
        let nav = SettingsNavigationViewController(rootViewController: settings)
        return nav
    }


    
    // TODO Placeholder. This functionality will come with LOOP-1311
    public var cgmStatusHighlight: DeviceStatusHighlight? {
        nil
    }
    
    // TODO Placeholder. This functionality will come with LOOP-1311
    public var cgmLifecycleProgress: DeviceLifecycleProgress? {
        nil
    }
}

extension LibreTransmitterManager: DeviceManagerUI {
    public var smallImage: UIImage? {
        //print("Got request for smallimage::", self.getSmallImage())
        return self.getSmallImage()
    }
}
