//
//  GlucoseDisplayable.swift
//  LibreTransmitter
//
//  Created by Bjørn Inge Berg on 11/07/2021.
//  Copyright © 2021 Mark Wilson. All rights reserved.
//

import Foundation


#if canImport(LoopKit)
#if canImport(LoopKitUI)
import LoopKit
import LoopKitUI


public typealias GlucoseDisplayable = LoopKit.GlucoseDisplayable
public typealias GlucoseRangeCategory = LoopKit.GlucoseRangeCategory
public typealias GlucoseTrend = LoopKit.GlucoseTrend

public typealias CGMManager = LoopKit.CGMManager
public typealias CGMManagerStatus = LoopKit.CGMManagerStatus
public typealias Alert = LoopKit.Alert
public typealias CGMManagerDelegate = LoopKit.CGMManagerDelegate
public typealias WeakSynchronizedDelegate = LoopKit.WeakSynchronizedDelegate
public typealias CGMReadingResult = LoopKit.CGMReadingResult
public typealias QuantityFormatter = LoopKit.QuantityFormatter
public typealias NewGlucoseSample = LoopKit.NewGlucoseSample

public typealias DeviceStatusBadge = LoopKit.DeviceStatusBadge
public typealias BluetoothProvider = LoopKit.BluetoothProvider
public typealias DeviceStatusHighlight = LoopKit.DeviceStatusHighlight
public typealias DeviceLifecycleProgress = LoopKit.DeviceLifecycleProgress

public typealias CGMManagerUI  = LoopKitUI.CGMManagerUI
public typealias LoopUIColorPalette = LoopKitUI.LoopUIColorPalette
public typealias CGMManagerOnboardNotifying = LoopKitUI.CGMManagerOnboardNotifying
public typealias CGMManagerSettingsNavigationViewController = LoopKitUI.CGMManagerSettingsNavigationViewController

public typealias SetupUIResult  = LoopKitUI.SetupUIResult
public typealias CompletionNotifying  = LoopKitUI.CompletionNotifying
public typealias DisplayGlucoseUnitObservable  = LoopKitUI.DisplayGlucoseUnitObservable
public typealias DeviceManagerUI  = LoopKitUI.DeviceManagerUI
public typealias CGMManagerCreateNotifying  = LoopKitUI.CGMManagerCreateNotifying

public typealias CGMManagerCreateDelegate = LoopKitUI.CGMManagerCreateDelegate
public typealias CGMManagerOnboardDelegate = LoopKitUI.CGMManagerOnboardDelegate
public typealias CompletionDelegate = LoopKitUI.CompletionDelegate

public typealias GlucoseValue = LoopKit.GlucoseValue



#endif
#endif

//don't relay on loops version of this, so include it here
public extension Sequence where Element: TimelineValue {
    /**
     Returns an array of elements filtered by the specified date range.

     This behavior mimics HKQueryOptionNone, where the value must merely overlap the specified range,
     not strictly exist inside of it.

     - parameter startDate: The earliest date of elements to return
     - parameter endDate:   The latest date of elements to return

     - returns: A new array of elements
     */
    func filterDateRange(_ startDate: Date?, _ endDate: Date?) -> [Iterator.Element] {
        return filter { (value) -> Bool in
            if let startDate = startDate, value.endDate < startDate {
                return false
            }

            if let endDate = endDate, value.startDate > endDate {
                return false
            }

            return true
        }
    }
}

