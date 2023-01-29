//
//  Userdefaults+Alarmsettings.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 20/04/2019.
//  Copyright © 2019 Bjørn Inge Berg. All rights reserved.
//

import Foundation
import HealthKit

extension UserDefaults {
    private enum Key: String {
        case glucoseSchedules = "no.bjorninge.glucoseschedules"

        case mmAlwaysDisplayGlucose = "no.bjorninge.mmAlwaysDisplayGlucose"
        case mmNotifyEveryXTimes = "no.bjorninge.mmNotifyEveryXTimes"
        case mmGlucoseAlarmsVibrate = "no.bjorninge.mmGlucoseAlarmsVibrate"
        case mmAlertLowBatteryWarning = "no.bjorninge.mmLowBatteryWarning"
        case mmAlertInvalidSensorDetected = "no.bjorninge.mmInvalidSensorDetected"
        // case mmAlertalarmNotifications
        case mmAlertNewSensorDetected = "no.bjorninge.mmNewSensorDetected"
        case mmAlertNoSensorDetected = "no.bjorninge.mmNoSensorDetected"
        case mmGlucoseUnit = "no.bjorninge.mmGlucoseUnit"
        case mmAlertSensorSoonExpire = "no.bjorninge.mmAlertSensorSoonExpire"
        case mmSnoozedUntil = "no.bjorninge.mmSnoozedUntil"
        case mmDangerMode = "no.bjorninge.mmDangerModeActivated"
        case mmShowPhoneBattery = "no.bjorninge.mmShowPhoneBattery"
        case mmShowTransmitterBattery = "no.bjorninge.mmShowTransmitterBattery"
        case mmCriticalAlarmsVolume = "no.bjorninge.mmCriticalAlarmsVolume"
    }
   
    public func optionalBool(forKey defaultName: String) -> Bool? {
        if let value = value(forKey: defaultName) {
            return value as? Bool
        }
        return nil
    }

    var mmShowPhoneBattery: Bool {
        get {
            optionalBool(forKey: Key.mmShowPhoneBattery.rawValue) ?? false
        }
        set {
            set(newValue, forKey: Key.mmShowPhoneBattery.rawValue)
        }
    }

    var mmAlwaysDisplayGlucose: Bool {
        get {
            optionalBool(forKey: Key.mmAlwaysDisplayGlucose.rawValue) ?? true
        }
        set {
            set(newValue, forKey: Key.mmAlwaysDisplayGlucose.rawValue)
        }
    }
    var mmNotifyEveryXTimes: Int {
        get {
            integer(forKey: Key.mmNotifyEveryXTimes.rawValue)
        }
        set {
            set(newValue, forKey: Key.mmNotifyEveryXTimes.rawValue)
        }
    }

    var mmAlertLowBatteryWarning: Bool {
        get {
            optionalBool(forKey: Key.mmAlertLowBatteryWarning.rawValue) ?? true
        }
        set {
            set(newValue, forKey: Key.mmAlertLowBatteryWarning.rawValue)
        }
    }
    var mmAlertInvalidSensorDetected: Bool {
        get {
            optionalBool(forKey: Key.mmAlertInvalidSensorDetected.rawValue) ?? true
        }
        set {
            set(newValue, forKey: Key.mmAlertInvalidSensorDetected.rawValue)
        }
    }

    var mmAlertNewSensorDetected: Bool {
        get {
            optionalBool(forKey: Key.mmAlertNewSensorDetected.rawValue) ?? true
        }
        set {
            set(newValue, forKey: Key.mmAlertNewSensorDetected.rawValue)
        }
    }

    var mmAlertNoSensorDetected: Bool {
        get {
            optionalBool(forKey: Key.mmAlertNoSensorDetected.rawValue) ?? true
        }
        set {
            set(newValue, forKey: Key.mmAlertNoSensorDetected.rawValue)
        }
    }

    var mmAlertWillSoonExpire: Bool {
        get {
            optionalBool(forKey: Key.mmAlertSensorSoonExpire.rawValue) ?? true
        }
        set {
            set(newValue, forKey: Key.mmAlertSensorSoonExpire.rawValue)
        }
    }

    var mmGlucoseAlarmsVibrate: Bool {
        get {
            optionalBool(forKey: Key.mmGlucoseAlarmsVibrate.rawValue) ?? true
        }
        set {
            set(newValue, forKey: Key.mmGlucoseAlarmsVibrate.rawValue)
        }
    }

    var mmShowTransmitterBattery: Bool {
        get {
            optionalBool(forKey: Key.mmShowTransmitterBattery.rawValue) ?? true
        }
        set {
            set(newValue, forKey: Key.mmShowTransmitterBattery.rawValue)
        }
    }

    var allNotificationToggles: [Bool] {
        [mmAlwaysDisplayGlucose, mmAlertLowBatteryWarning,
         mmAlertInvalidSensorDetected, mmAlertNewSensorDetected,
         mmAlertNoSensorDetected, mmAlertWillSoonExpire,
         mmGlucoseAlarmsVibrate, mmShowPhoneBattery, mmShowTransmitterBattery]
    }

    var dangerModeActivated: Bool {
        get {
            optionalBool(forKey: Key.mmDangerMode.rawValue) ?? false
        }
        set {
            set(newValue, forKey: Key.mmDangerMode.rawValue)
        }
    }

    // intentionally only supports mgdl and mmol
    var mmGlucoseUnit: HKUnit? {
        get {
            if let textUnit = string(forKey: Key.mmGlucoseUnit.rawValue) {
                if textUnit == "mmol" {
                    return HKUnit.millimolesPerLiter
                } else if textUnit == "mgdl" {
                    return HKUnit.milligramsPerDeciliter
                }
            }

            return nil
        }
        set {
            if newValue == HKUnit.milligramsPerDeciliter {
                set("mgdl", forKey: Key.mmGlucoseUnit.rawValue)
            } else if newValue == HKUnit.millimolesPerLiter {
                set("mmol", forKey: Key.mmGlucoseUnit.rawValue)
            }
        }
    }

    var enabledSchedules: [GlucoseSchedule]? {
        glucoseSchedules?.schedules.compactMap({ schedule -> GlucoseSchedule? in
            if schedule.enabled ?? false {
                return schedule
            }
            return nil
        })
    }
    var snoozedUntil: Date? {
        get {
            object(forKey: Key.mmSnoozedUntil.rawValue) as? Date
        }
        set {
            set(newValue, forKey: Key.mmSnoozedUntil.rawValue)
        }
    }
    var glucoseSchedules: GlucoseScheduleList? {
        get {
            if let savedGlucoseSchedules = object(forKey: Key.glucoseSchedules.rawValue) as? Data {
                let decoder = JSONDecoder()
                if let loadedGlucoseSchedules = try? decoder.decode(GlucoseScheduleList.self, from: savedGlucoseSchedules) {
                    return loadedGlucoseSchedules
                }
            }

            return GlucoseScheduleList()
        }
        set {
            let encoder = JSONEncoder()
            if let val = newValue, let encoded = try? encoder.encode(val) {
                set(encoded, forKey: Key.glucoseSchedules.rawValue)
            }
        }
    }
    
    var mmCriticalAlarmsVolume: Double {
        get {
            double(forKey: Key.mmCriticalAlarmsVolume.rawValue)
        }
        set {
            set(newValue, forKey: Key.mmCriticalAlarmsVolume.rawValue)
        }
    }
}
