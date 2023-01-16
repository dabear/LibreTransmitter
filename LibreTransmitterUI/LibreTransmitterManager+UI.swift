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

struct LibreLifecycleProgress: DeviceLifecycleProgress {
    var percentComplete: Double

    var progressState: LoopKit.DeviceLifecycleProgressState
}

extension LibreTransmitterManager: CGMManagerUI {

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
        nav.navigationItem.largeTitleDisplayMode = .always
        nav.navigationBar.prefersLargeTitles = true

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

    public var cgmStatusHighlight: DeviceStatusHighlight? {
        nil
    }

    public var cgmLifecycleProgress: DeviceLifecycleProgress? {
        let isConnected = [.Connected,.Notifying].contains(self.proxy?.state)
        
        guard isConnected else {
            return nil
        }
        let minutesLeft = Double(self.sensorInfoObservable.sensorMinutesLeft)
        
        let progress = self.sensorInfoObservable.calculateProgress()
        // This matches the manufacturere's app where it displays a notification when sensor has less than 3 days left
        if TimeInterval(minutes: minutesLeft) < TimeInterval(hours: 24*3) {
            if TimeInterval(minutes: minutesLeft) < TimeInterval(hours: 24) {
                return LibreLifecycleProgress(percentComplete: progress, progressState: .warning)
            }
            return LibreLifecycleProgress(percentComplete: progress, progressState: .normalCGM)
        }
        
        return nil
        
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
