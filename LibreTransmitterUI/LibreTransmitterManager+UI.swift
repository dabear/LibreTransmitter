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
import Combine


extension LibreTransmitterManager: CGMManagerUI {


    // TODO Placeholder.
    public var cgmStatusBadge: DeviceStatusBadge? {
        nil
    }


    public static func setupViewController(bluetoothProvider: BluetoothProvider, colorPalette: LoopUIColorPalette) -> SetupUIResult<UIViewController & CGMManagerCreateNotifying & CGMManagerOnboardNotifying & CompletionNotifying, CGMManagerUI> {
            return .userInteractionRequired(LibreTransmitterSetupViewController())
    }

    public func settingsViewController(for displayGlucoseUnitObservable: DisplayGlucoseUnitObservable, bluetoothProvider: BluetoothProvider, colorPalette: LoopUIColorPalette) -> (UIViewController & CGMManagerOnboardNotifying & CompletionNotifying) {

        /*
        let settings = LibreTransmitterSettingsViewController(cgmManager: self, displayGlucoseUnitObservable: displayGlucoseUnitObservable, allowsDeletion: true)
        let nav = CGMManagerSettingsNavigationViewController(rootViewController: settings)
         */



        let doneNotifier = GenericObservableObject()


        let settings = (SettingsOverview.asHostedViewController(cgmManager: self, displayGlucoseUnitObservable: displayGlucoseUnitObservable, allowsDeletion: true, notifyComplete: doneNotifier))
        let nav = CGMManagerSettingsNavigationViewController(rootViewController: settings)

        doneNotifier.listenOnce {
            print("listened once")
            nav.notifyComplete()
        }




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
       self.getSmallImage()
    }
}
