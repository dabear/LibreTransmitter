//
//  LibreTransmitterManager+Transmitters.swift
//  LibreTransmitter
//
//  Created by Bjørn Inge Berg on 25/04/2022.
//  Copyright © 2022 Mark Wilson. All rights reserved.
//

import Foundation
import LoopKit

// MARK: - Bluetooth transmitter data
extension LibreTransmitterManager {

    public func noLibreTransmitterSelected() {
        NotificationHelper.sendNoTransmitterSelectedNotification()
    }

    public func libreTransmitterDidUpdate(with sensorData: SensorData, and Device: LibreTransmitterMetadata) {

        self.logger.debug("dabear:: got sensordata: \(String(describing: sensorData)), bytescount: \( sensorData.bytes.count), bytes: \(sensorData.bytes)")
        var sensorData = sensorData
        

        NotificationHelper.sendLowBatteryNotificationIfNeeded(device: Device)
        self.setObservables(sensorData: nil, bleData: nil, metaData: Device)

         if !sensorData.isLikelyLibre1FRAM {
            if let patchInfo = Device.patchInfo, let sensorType = SensorType(patchInfo: patchInfo) {
                let needsDecryption = [SensorType.libre2, .libreUS14day].contains(sensorType)
                if needsDecryption, let uid = Device.uid {
                    sensorData.decrypt(patchInfo: patchInfo, uid: uid)
                }
            } else {
                logger.debug("Sensor type was incorrect, and no decryption of sensor was possible")
                self.cgmManagerDelegate?.cgmManager(self, hasNew: .error(LibreError.encryptedSensor))
                return
            }
        }

        let typeDesc = Device.sensorType().debugDescription

        logger.debug("Transmitter connected to libresensor of type \(typeDesc). Details:  \(Device.description)")

        tryPersistSensorData(with: sensorData)

        NotificationHelper.sendInvalidSensorNotificationIfNeeded(sensorData: sensorData)
        NotificationHelper.sendInvalidChecksumIfDeveloper(sensorData)

        guard sensorData.hasValidCRCs else {
            self.delegateQueue.async {
                self.cgmManagerDelegate?.cgmManager(self, hasNew: .error(LibreError.checksumValidationError))
            }

            logger.debug("did not get sensordata with valid crcs")
            return
        }

        NotificationHelper.sendSensorExpireAlertIfNeeded(sensorData: sensorData)

        guard sensorData.state == .ready || sensorData.state == .starting else {
            logger.debug("dabear:: got sensordata with valid crcs, but sensor is either expired or failed")
            self.delegateQueue.async {
                self.cgmManagerDelegate?.cgmManager(self, hasNew: .error(LibreError.expiredSensor))
            }
            return
        }

        logger.debug("dabear:: got sensordata with valid crcs, sensor was ready")
        // self.lastValidSensorData = sensorData

        self.handleGoodReading(data: sensorData) { [weak self] error, glucoseArrayWithPrediction in
            guard let self else {
                print("dabear:: handleGoodReading could not lock on self, aborting")
                return
            }
            if let error {
                self.logger.error("dabear:: handleGoodReading returned with error: \(error.errorDescription)")
                self.delegateQueue.async {
                    self.cgmManagerDelegate?.cgmManager(self, hasNew: .error(error))
                }
                return
            }

            guard let glucose = glucoseArrayWithPrediction?.glucose else {
                self.logger.debug("dabear:: handleGoodReading returned with no data")
                self.delegateQueue.async {
                    self.cgmManagerDelegate?.cgmManager(self, hasNew: .noData)
                }
                return
            }

            let prediction = glucoseArrayWithPrediction?.prediction

            let newGlucose = self.glucosesToSamplesFilter(glucose, startDate: self.getStartDateForFilter())

            if newGlucose.isEmpty {
                self.countTimesWithoutData &+= 1
            } else {
                self.latestBackfill = glucose.max { $0.startDate < $1.startDate }
                self.logger.debug("dabear:: latestbackfill set to \(self.latestBackfill.debugDescription)")
                self.countTimesWithoutData = 0
            }

            self.latestPrediction = prediction?.first

            // must be inside this handler as setobservables "depend" on latestbackfill
            self.setObservables(sensorData: sensorData, bleData: nil, metaData: nil)

            self.logger.debug("dabear:: handleGoodReading returned with \(newGlucose.count) entries")
            self.delegateQueue.async {
                var result: CGMReadingResult
                // If several readings from a valid and running sensor come out empty,
                // we have (with a large degree of confidence) a sensor that has been
                // ripped off the body
                if self.countTimesWithoutData > 1 {
                    result = .error(LibreError.noValidSensorData)
                } else {
                    result = newGlucose.isEmpty ? .noData : .newData(newGlucose)
                }
                self.cgmManagerDelegate?.cgmManager(self, hasNew: result)
            }
        }

    }
    private func readingToGlucose(_ data: SensorData, calibration: SensorData.CalibrationInfo) -> GlucoseArrayWithPrediction {

        var entries: [LibreGlucose] = []
        var prediction: [LibreGlucose] = []

        let trends = data.trendMeasurements()

        if let temp = createBloodSugarPrediction(trends, calibration: calibration) {
            prediction.append(temp)
        }

        entries = LibreGlucose.fromTrendMeasurements(trends, nativeCalibrationData: calibration, returnAll: UserDefaults.standard.mmBackfillFromTrend)

        if UserDefaults.standard.mmBackfillFromHistory {
            let history = data.historyMeasurements()
            entries += LibreGlucose.fromHistoryMeasurements(history, nativeCalibrationData: calibration)
        }

        return (glucose: entries, prediction: prediction)
    }

    public func handleGoodReading(data: SensorData?, _ callback: @escaping (LibreError?, GlucoseArrayWithPrediction?) -> Void) {
        // only care about the once per minute readings here, historical data will not be considered

        guard let data else {
            callback(.noSensorData, nil)
            return
        }

        
        if let calibrationData {
            logger.debug("dabear:: calibrationdata loaded")

            if calibrationData.isValidForFooterWithReverseCRCs == data.footerCrc.byteSwapped {
                logger.debug("dabear:: calibrationdata correct for this sensor, returning last values")

                callback(nil, readingToGlucose(data, calibration: calibrationData))
                return
            } else {
                logger.debug(
                """
                dabear:: calibrationdata incorrect for this sensor, calibrationdata.isValidForFooterWithReverseCRCs:
                \(calibrationData.isValidForFooterWithReverseCRCs),
                data.footerCrc.byteSwapped: \(data.footerCrc.byteSwapped)
                """)

            }
        } else {
            logger.debug("dabear:: calibrationdata was nil")
        }

        calibrateSensor(sensordata: data) { [weak self] calibrationparams  in
            do {
                try KeychainManagerWrapper.standard.setLibreNativeCalibrationData(calibrationparams)
            } catch {
                NotificationHelper.sendCalibrationNotification(.invalidCalibrationData)
                callback(.invalidCalibrationData, nil)
                return
            }
            // here we assume success, data is not changed,
            // and we trust that the remote endpoint returns correct data for the sensor

            NotificationHelper.sendCalibrationNotification(.success)
            callback(nil, self?.readingToGlucose(data, calibration: calibrationparams))
        }
    }

    // will be called on utility queue
    public func libreTransmitterStateChanged(_ state: BluetoothmanagerState) {
        DispatchQueue.main.async {
            self.transmitterInfoObservable.connectionState = self.proxy?.connectionStateString ?? "n/a"
            self.transmitterInfoObservable.transmitterType = self.proxy?.shortTransmitterName ?? "Unknown"
        }
        switch state {
        case .Connected:
            lastConnected = Date()
        case .powerOff:
            NotificationHelper.sendBluetoothPowerOffNotification()
        default:
            break
        }
        return
    }

    // will be called on utility queue
    public func libreTransmitterReceivedMessage(_ messageIdentifier: UInt16, txFlags: UInt8, payloadData: Data) {
        guard let packet = MiaoMiaoResponseState(rawValue: txFlags) else {
            // Incomplete package?
            // this would only happen if delegate is called manually with an unknown txFlags value
            // this was the case for readouts that were not yet complete
            // but that was commented out in MiaoMiaoManager.swift, see comment there:
            // "dabear-edit: don't notify on incomplete readouts"
            logger.debug("dabear:: incomplete package or unknown response state")
            return
        }

        switch packet {
        case .newSensor:
            logger.debug("dabear:: new libresensor detected")
            NotificationHelper.sendSensorChangeNotificationIfNeeded()
        case .noSensor:
            logger.debug("dabear:: no libresensor detected")
            NotificationHelper.sendSensorNotDetectedNotificationIfNeeded(noSensor: true)
        case .frequencyChangedResponse:
            logger.debug("dabear:: transmitter readout interval has changed!")

        default:
            // we don't care about the rest!
            break
        }

        return
    }

    func tryPersistSensorData(with sensorData: SensorData) {
        guard UserDefaults.standard.shouldPersistSensorData else {
            return
        }

        // yeah, we really really need to persist any changes right away
        var data = UserDefaults.standard.queuedSensorData ?? LimitedQueue<SensorData>()
        data.enqueue(sensorData)
        UserDefaults.standard.queuedSensorData = data
    }
}
