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

    public static func setupViewController(bluetoothProvider: BluetoothProvider, displayGlucoseUnitObservable: DisplayGlucoseUnitObservable, colorPalette: LoopUIColorPalette, allowDebugFeatures: Bool) -> SetupUIResult<CGMManagerViewController, CGMManagerUI> {

            return .userInteractionRequired(LibreTransmitterSetupViewController())
    }

    public func settingsViewController(bluetoothProvider: BluetoothProvider, displayGlucoseUnitObservable: DisplayGlucoseUnitObservable, colorPalette: LoopUIColorPalette, allowDebugFeatures: Bool) -> CGMManagerViewController {

        let doneNotifier = GenericObservableObject()
        let wantToTerminateNotifier = GenericObservableObject()

        let settings = SettingsView.asHostedViewController(
            displayGlucoseUnitObservable: displayGlucoseUnitObservable,
            notifyComplete: doneNotifier, notifyDelete: wantToTerminateNotifier,
            transmitterInfoObservable: self.transmitterInfoObservable,
            sensorInfoObervable: self.sensorInfoObservable,
            glucoseInfoObservable: self.glucoseInfoObservable,
            alarmStatus: self.alarmStatus)

        let nav = CGMManagerSettingsNavigationViewController(rootViewController: settings)

        doneNotifier.listenOnce { [weak nav] in
            nav?.notifyComplete()

        }

        wantToTerminateNotifier.listenOnce { [weak self, weak nav] in
            self?.logger.debug("CGM wants to terminate")
            self?.disconnect()

            UserDefaults.standard.preSelectedDevice = nil
            self?.notifyDelegateOfDeletion {
                DispatchQueue.main.async {
                    nav?.notifyComplete()

                }
            }

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
    public static var onboardingImage: UIImage? {
        nil
    }

    public var smallImage: UIImage? {
       self.getSmallImage()
    }
}
