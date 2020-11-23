//
//  Calibration.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 05/03/2019.
//  Copyright © 2019 Bjørn Inge Berg. All rights reserved.
//

import Foundation
import LoopKit

private let LibreCalibrationLabel =  "https://LibreCalibrationLabelNative.doesnot.exist.com"
private let LibreCalibrationUrl = URL(string: LibreCalibrationLabel)!
private let LibreUsername = "LibreUsername"

extension KeychainManager {
    public func setLibreNativeCalibrationData(_ calibrationData: SensorData.CalibrationInfo) throws {
        let credentials: InternetCredentials?
        credentials = InternetCredentials(username: LibreUsername, password: serializeNativeAlgorithmParameters(calibrationData), url: LibreCalibrationUrl)
        NSLog("dabear: Setting calibrationdata to \(String(describing: calibrationData))")
        try replaceInternetCredentials(credentials, forLabel: LibreCalibrationLabel)
    }

    public func getLibreNativeCalibrationData() -> SensorData.CalibrationInfo? {
        do { // Silence all errors and return nil
            let credentials = try getInternetCredentials(label: LibreCalibrationLabel)
            NSLog("dabear:: credentials.password was retrieved: \(credentials.password)")
            return deserializeNativeAlgorithmParameters(text: credentials.password)
        } catch {
            NSLog("dabear:: unable to retrieve calibrationdata:")
            return nil
        }
    }
}

public func calibrateSensor(sensordata: SensorData, callback: @escaping (SensorData.CalibrationInfo) -> Void) {
    NSLog("calibrating sensor locally")
    let params = sensordata.calibrationData
    callback(params)
}

private func serializeNativeAlgorithmParameters(_ params: SensorData.CalibrationInfo) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted

    var aString = ""
    do {
        let jsonData = try encoder.encode(params)

        if let jsonString = String(data: jsonData, encoding: .utf8) {
            aString = jsonString
        }
    } catch {
        print("Could not serialize parameters: \(error.localizedDescription)")
    }
    return aString
}

private func deserializeNativeAlgorithmParameters(text: String) -> SensorData.CalibrationInfo? {
    if let jsonData = text.data(using: .utf8) {
        let decoder = JSONDecoder()

        do {
            return try decoder.decode(SensorData.CalibrationInfo.self, from: jsonData)
        } catch {
            print("Could not create instance: \(error.localizedDescription)")
        }
    } else {
        print("Did not create instance")
    }
    return nil
}
