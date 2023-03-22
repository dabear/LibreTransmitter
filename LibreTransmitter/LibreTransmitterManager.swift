//
//  LibreTransmitterManager.swift
//  Created by Bjørn Inge Berg on 25/02/2019.
//  Copyright © 2019 Bjørn Inge Berg. All rights reserved.
//

import Foundation
import LoopKit
// import LoopKitUI
import UIKit
import UserNotifications
import Combine

import CoreBluetooth
import HealthKit
import os.log

public final class LibreTransmitterManager: CGMManager, LibreTransmitterDelegate {

    public typealias GlucoseArrayWithPrediction = (trends: [LibreGlucose], historical: [LibreGlucose], prediction: [LibreGlucose])
    public lazy var logger = Logger(forType: Self.self)

    public let isOnboarded = true   // No distinction between created and onboarded

    public var hasValidSensorSession: Bool {
        lastConnected != nil
    }

    public var cgmManagerStatus: CGMManagerStatus {
        CGMManagerStatus(hasValidSensorSession: hasValidSensorSession, device: nil)
    }

    public var glucoseDisplay: GlucoseDisplayable?

    public func acknowledgeAlert(alertIdentifier: Alert.AlertIdentifier) {

    }

    public func getSoundBaseURL() -> URL? {
        nil
    }

    public func getSounds() -> [Alert.Sound] {
        []
    }

    public func acknowledgeAlert(alertIdentifier: Alert.AlertIdentifier, completion: @escaping (Error?) -> Void) {
        completion(nil)
    }

    public func libreManagerDidRestoreState(found peripherals: [CBPeripheral], connected to: CBPeripheral?) {
        let devicename = to?.name  ?? "no device"
        let id = to?.identifier.uuidString ?? "null"
        let msg = "Bluetooth State restored (Loop restarted?). Found \(peripherals.count) peripherals, and connected to \(devicename) with identifier \(id)"
        NotificationHelper.sendRestoredStateNotification(msg: msg)
    }

    public var batteryLevel: Double? {
        let batt = self.proxy?.metadata?.battery
        logger.debug("LibreTransmitterManager was asked to return battery: \(batt.debugDescription)")
        // convert from 8% -> 0.8
        if let battery = proxy?.metadata?.battery {
            return Double(battery) / 100
        }

        return nil
    }

    public var cgmManagerDelegate: CGMManagerDelegate? {
        get {
            return delegate.delegate
        }
        set {
            delegate.delegate = newValue
        }
    }

    public var delegateQueue: DispatchQueue! {
        get {
            return delegate.queue
        }
        set {
            delegate.queue = newValue
        }
    }

    public let delegate = WeakSynchronizedDelegate<CGMManagerDelegate>()

    public var managedDataInterval: TimeInterval?

    private func getPersistedSensorDataForDebug() -> String {
        guard let data = UserDefaults.standard.queuedSensorData else {
            return "nil"
        }

        let c = self.calibrationData?.description ?? "no calibrationdata"
        return data.array.map {
            "SensorData(uuid: \"0123\".data(using: .ascii)!, bytes: \($0.bytes))!"
        }
        .joined(separator: ",\n")
        + ",\n Calibrationdata: \(c)"
    }

    public var debugDescription: String {

        return [
            "## LibreTransmitterManager",
            "Testdata: foo",
            "lastConnected: \(String(describing: lastConnected))",
            "Connection state: \(self.proxy?.connectionStateString)",
            "Sensor state: \(proxy?.sensorData?.state.description)",
            "transmitterbattery: \(proxy?.metadata?.batteryString)",
            "SensorData: \(getPersistedSensorDataForDebug())",
            "providesBLEHeartbeat: \(providesBLEHeartbeat)",
            "Metainfo::\n\(AppMetaData.allProperties)",
            ""
        ].joined(separator: "\n")
    }

    // public var miaomiaoService: MiaomiaoService

    public func fetchNewDataIfNeeded(_ completion: @escaping (CGMReadingResult) -> Void) {
        logger.debug("fetchNewDataIfNeeded called but we don't continue")

        completion(.noData)
    }

    internal var lastConnected: Date?

    public internal(set) var alarmStatus = AlarmStatus()

    internal var latestPrediction: LibreGlucose?

    internal var latestBackfill: LibreGlucose? {
        willSet(newValue) {
            guard let newValue else {
                return
            }

            var trend: GlucoseTrend?
            let oldValue = latestBackfill

            defer {
                logger.debug("sending glucose notification")
                NotificationHelper.sendGlucoseNotitifcationIfNeeded(glucose: newValue,
                                                                    oldValue: oldValue,
                                                                    trend: trend,
                                                                    battery: proxy?.metadata?.batteryString ?? "n/a")

                // once we have a new glucose value, we can update the isalarming property
                if let activeAlarms = UserDefaults.standard.glucoseSchedules?.getActiveAlarms(newValue.glucoseDouble) {
                    DispatchQueue.main.async {
                        self.alarmStatus.isAlarming = ([.high, .low].contains(activeAlarms))
                        self.alarmStatus.glucoseScheduleAlarmResult = activeAlarms
                    }
                } else {
                    DispatchQueue.main.async {
                    self.alarmStatus.isAlarming = false
                    self.alarmStatus.glucoseScheduleAlarmResult = .none
                    }
                }

            }

            logger.debug("latestBackfill set, newvalue is \(newValue.description)")

            if let oldValue {
                // the idea here is to use the diff between the old and the new glucose to calculate slope and direction, rather than using trend from the glucose value.
                // this is because the old and new glucose values represent earlier readouts, while the trend buffer contains somewhat more jumpy (noisy) values.
                let timediff = LibreGlucose.timeDifference(oldGlucose: oldValue, newGlucose: newValue)
                logger.debug("timediff is \(timediff)")
                let oldIsRecentEnough = timediff <= TimeInterval.minutes(15)

                trend = oldIsRecentEnough ? newValue.GetGlucoseTrend(last: oldValue) : nil

                self.glucoseDisplay = ConcreteGlucoseDisplayable(isStateValid: newValue.isStateValid, trendType: trend, isLocal: true)
            } else {
                // could consider setting this to ConcreteSensorDisplayable with trendtype GlucoseTrend.flat, but that would be kinda lying
                self.glucoseDisplay = nil
            }
        }

    }

    public var managerIdentifier = "LibreTransmitterManager"

    public required convenience init?(rawState: CGMManager.RawStateValue) {

        self.init()
        logger.debug("LibreTransmitterManager  has run init from rawstate")
        
    }

    public var rawState: CGMManager.RawStateValue {
        [:]
    }

    public let localizedTitle = LocalizedString("Libre Bluetooth", comment: "Title for the CGMManager option")

    public let appURL: URL? = nil // URL(string: "spikeapp://")

    public let providesBLEHeartbeat = true
    public var shouldSyncToRemoteService: Bool {
        UserDefaults.standard.mmSyncToNs
    }

    public init() {
        lastConnected = nil

        logger.debug("LibreTransmitterManager will be created now")
        NotificationHelper.requestNotificationPermissionsIfNeeded()
        
        proxy?.delegate = self
    }
    
    public func resetManager() {
        proxy?.activePlugin?.reset()
        disconnect()
        transmitterInfoObservable = TransmitterInfo()
        sensorInfoObservable = SensorInfo()
        glucoseInfoObservable = GlucoseInfo()
        
    }

    public func disconnect() {
        logger.debug("LibreTransmitterManager disconnect called")

        proxy?.disconnectManually()
        proxy?.delegate = nil
        proxy = nil
        lastConnected = nil
        lastDirectUpdate = nil
    }
    
    public func reEstablishProxy() {
        logger.debug("LibreTransmitterManager re-establish called")

        proxy = LibreTransmitterProxyManager()
        proxy?.delegate = self
    }
    

    deinit {
        logger.debug("LibreTransmitterManager deinit called")
        // cleanup any references to events to this class
        disconnect()
    }

    // lazy because we don't want to scan immediately
    public lazy var proxy: LibreTransmitterProxyManager? = LibreTransmitterProxyManager()

    /*
     These properties are mostly useful for swiftui
     */
    public var transmitterInfoObservable = TransmitterInfo()
    public var sensorInfoObservable = SensorInfo()
    public var glucoseInfoObservable = GlucoseInfo()

    var longDateFormatter: DateFormatter = ({
        let df = DateFormatter()
        df.dateStyle = .long
        df.timeStyle = .long
        df.doesRelativeDateFormatting = true
        return df
    })()

    var dateFormatter: DateFormatter = ({
        let df = DateFormatter()
        df.dateStyle = .long
        df.timeStyle = .full
        df.locale = Locale.current
        return df
    })()

    // when was the libre2 direct ble update last received?
    var lastDirectUpdate: Date?

    internal var countTimesWithoutData: Int = 0

}

// MARK: - Convenience functions
extension LibreTransmitterManager {

    internal func createBloodSugarPrediction(_ measurements: [Measurement], calibration: SensorData.CalibrationInfo) -> LibreGlucose? {
        let allGlucoses = measurements.sorted { $0.date > $1.date }

        // Increase to up to 15 to move closer to real blood sugar
        // The cost is slightly more noise on consecutive readings
        let glucosePredictionMinutes: Double = 10

        guard allGlucoses.count > 15 else {
            logger.info("not creating blood sugar prediction: less data elements than needed (\(allGlucoses.count))")
            return nil
        }

        if let predicted = allGlucoses.predictBloodSugar(glucosePredictionMinutes) {
            let currentBg = predicted.roundedGlucoseValueFromRaw2(calibrationInfo: calibration)
            let bgDate = predicted.date.addingTimeInterval(60 * -glucosePredictionMinutes)
            return LibreGlucose(unsmoothedGlucose: currentBg, glucoseDouble: currentBg, timestamp: bgDate)
            logger.debug("Predicted glucose (not used) was: \(currentBg)")
        } else {
            return nil
            logger.debug("Tried to predict glucose value but failed!")
        }

    }

    func setObservables(sensorData: SensorData?, bleData: Libre2.LibreBLEResponse?, metaData: LibreTransmitterMetadata?) {
        logger.debug("setObservables called")
        DispatchQueue.main.async {

            if let metaData=metaData {
                self.logger.debug("will set transmitterInfoObservable")
                self.transmitterInfoObservable.battery = metaData.batteryString
                self.transmitterInfoObservable.hardware = metaData.hardware ?? ""
                self.transmitterInfoObservable.firmware = metaData.firmware ?? ""
                self.transmitterInfoObservable.sensorType = metaData.sensorType()?.description ?? "Unknown"
                self.transmitterInfoObservable.transmitterMacAddress = metaData.macAddress ?? ""

            }
            let now = Date.now

            self.transmitterInfoObservable.connectionState = self.proxy?.connectionStateString ?? "n/a"
            self.transmitterInfoObservable.transmitterType = self.proxy?.shortTransmitterName ?? "Unknown"

            if let sensorData {
                self.logger.debug("will set sensorInfoObservable")
                self.sensorInfoObservable.sensorAge = sensorData.humanReadableSensorAge
                self.sensorInfoObservable.sensorAgeLeft = sensorData.humanReadableTimeLeft
                self.sensorInfoObservable.sensorMinutesLeft = sensorData.minutesLeft
                self.sensorInfoObservable.activatedAt = now - TimeInterval(minutes: Double(sensorData.minutesSinceStart))
                self.sensorInfoObservable.expiresAt = now + TimeInterval(minutes: Double(sensorData.minutesLeft))
                
                
                self.sensorInfoObservable.sensorMinutesSinceStart = sensorData.minutesSinceStart
                self.sensorInfoObservable.sensorMaxMinutesWearTime = sensorData.maxMinutesWearTime

                self.sensorInfoObservable.sensorState = sensorData.state.description
                self.sensorInfoObservable.sensorSerial = sensorData.serialNumber

                self.glucoseInfoObservable.checksum = String(sensorData.footerCrc.byteSwapped)

                if let sensorEndTime = sensorData.sensorEndTime {
                    self.sensorInfoObservable.sensorEndTime = self.dateFormatter.string(from: sensorEndTime )

                } else {
                    self.sensorInfoObservable.sensorEndTime = "Unknown or ended"

                }

            } else if let bleData, let sensor = UserDefaults.standard.preSelectedSensor {
                let aday = 86_400.0 // in seconds
                var humanReadableSensorAge: String {
                    let days = TimeInterval(bleData.age * 60) / aday
                    return String(format: "%.2f", days) + " day(s)"
                }

                var maxMinutesWearTime: Int {
                    sensor.maxAge
                }
                
                var minutesSinceStart: Int {
                    bleData.age
                }

                var minutesLeft: Int {
                    maxMinutesWearTime - bleData.age
                }

                var humanReadableTimeLeft: String {
                    let days = TimeInterval(minutesLeft * 60) / aday
                    return String(format: "%.2f", days) + " day(s)"
                }

                // once the sensor has ended we don't know the exact date anymore
                var sensorEndTime: Date? {
                    if minutesLeft <= 0 {
                        return nil
                    }

                    // we can assume that the libre2 direct bluetooth packet is received immediately
                    // after the sensor has been done a new measurement, so using Date() should be fine here
                    return Date().addingTimeInterval(TimeInterval(minutes: Double(minutesLeft)))
                }
                
                self.sensorInfoObservable.sensorMinutesLeft = minutesLeft
                self.sensorInfoObservable.sensorMinutesSinceStart = minutesLeft
                
                self.sensorInfoObservable.activatedAt = now - TimeInterval(minutes: Double(minutesSinceStart))
                
                if minutesLeft > 0 {
                    self.sensorInfoObservable.expiresAt = now + TimeInterval(minutes: Double(minutesLeft))
                }
                
                
                
                self.sensorInfoObservable.sensorMaxMinutesWearTime = maxMinutesWearTime
                

                self.sensorInfoObservable.sensorAge = humanReadableSensorAge
                self.sensorInfoObservable.sensorAgeLeft = humanReadableTimeLeft
                self.sensorInfoObservable.sensorState = "Operational"
                self.sensorInfoObservable.sensorState = "Operational"
                let family = SensorFamily.libre2
                self.sensorInfoObservable.sensorSerial = SensorSerialNumber(withUID: sensor.uuid, sensorFamily: family)?.serialNumber ?? "-"

                if let mapping = UserDefaults.standard.calibrationMapping,
                   let calibration = self.calibrationData ,
                   mapping.uuid == sensor.uuid && calibration.isValidForFooterWithReverseCRCs ==  mapping.reverseFooterCRC {
                    self.glucoseInfoObservable.checksum = "\(mapping.reverseFooterCRC)"
                }

                if let sensorEndTime {
                    self.sensorInfoObservable.sensorEndTime = self.dateFormatter.string(from: sensorEndTime )

                } else {
                    self.sensorInfoObservable.sensorEndTime = "Unknown or ended"

                }

            }

            let formatter = QuantityFormatter()
            let preferredUnit = UserDefaults.standard.mmGlucoseUnit ?? .millimolesPerLiter

            if let d = self.latestBackfill {
                self.logger.debug("will set glucoseInfoObservable")

                formatter.setPreferredNumberFormatter(for: .millimolesPerLiter)
                self.glucoseInfoObservable.glucoseMMOL = formatter.string(from: d.quantity, for: .millimolesPerLiter) ?? "-"

                formatter.setPreferredNumberFormatter(for: .milligramsPerDeciliter)
                self.glucoseInfoObservable.glucoseMGDL = formatter.string(from: d.quantity, for: .milligramsPerDeciliter) ?? "-"

                // backward compat
                if preferredUnit == .millimolesPerLiter {
                    self.glucoseInfoObservable.glucose = self.glucoseInfoObservable.glucoseMMOL
                } else if preferredUnit == .milligramsPerDeciliter {
                    self.glucoseInfoObservable.glucose = self.glucoseInfoObservable.glucoseMGDL
                }

                self.glucoseInfoObservable.date = self.longDateFormatter.string(from: d.timestamp)
            }

            if let d = self.latestPrediction {
                formatter.setPreferredNumberFormatter(for: .millimolesPerLiter)
                self.glucoseInfoObservable.predictionMMOL = formatter.string(from: d.quantity, for: .millimolesPerLiter) ?? "-"

                formatter.setPreferredNumberFormatter(for: .milligramsPerDeciliter)
                self.glucoseInfoObservable.predictionMGDL = formatter.string(from: d.quantity, for: .milligramsPerDeciliter) ?? "-"
                self.glucoseInfoObservable.predictionDate = self.longDateFormatter.string(from: d.timestamp)

            } else {
                self.glucoseInfoObservable.predictionMMOL = ""
                self.glucoseInfoObservable.predictionMGDL = ""
                self.glucoseInfoObservable.predictionDate = ""

            }

        }

    }

    func getStartDateForFilter() -> Date? {
        // We prefer to use local cached glucose value for the date to filter
        // todo: fix this for ble packets
        var startDate = self.latestBackfill?.startDate

        //
        // but that might not be available when loop is restarted for example
        //
        if startDate == nil {
            startDate = self.delegate.call{ $0?.startDateToFilterNewData(for: self) }
        }

        // add one second to startdate to make this an exclusive (non overlapping) match
        return startDate?.addingTimeInterval(1)
    }

    func glucosesToSamplesFilter(_ array: [LibreGlucose], startDate: Date?, calculateTrends: Bool = true) -> [NewGlucoseSample] {
        let glucoses = array.filter { $0.isStateValid }
        
        let newest = glucoses.first
        let oldest = glucoses.last
        
        var trend: GlucoseTrend? = nil
        
        if calculateTrends, let newest, let oldest, oldest != newest {
            trend = newest.GetGlucoseTrend(last: oldest)
            logger.debug("creating trendarrow from glucoses: newest: \(String(describing:newest)) oldest: \(String(describing: oldest)) ")
        } else {
            logger.debug("Not creating trendarrow for remote uploada")
            trend = .none
        }
        logger.debug("tried creating trendarrow using \(glucoses.count) elements for trend calc")
        
        return
        glucoses
        .filterDateRange(startDate, nil)
        .compactMap {
            return NewGlucoseSample(
                date: $0.startDate,
                quantity: $0.quantity,
                condition: nil,
                trend: trend,
                trendRate: nil,
                isDisplayOnly: false,
                wasUserEntered: false,
                syncIdentifier: $0.syncId,
                device: self.proxy?.device)
        }

    }

    public var calibrationData: SensorData.CalibrationInfo? {
        KeychainManager.standard.getLibreNativeCalibrationData()
    }
    
    public func getSmallImage() -> UIImage {
        proxy?.activePluginType?.smallImage ?? UIImage(named: "libresensor", in: Bundle.current, compatibleWith: nil)!
    }
}
