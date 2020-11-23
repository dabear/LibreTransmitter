//
//  Measurement.swift
//  LibreMonitor
//
//  Created by Uwe Petersen on 25.08.16.
//  Copyright © 2016 Uwe Petersen. All rights reserved.
//

import Foundation

protocol MeasurementProtocol {
    var rawGlucose: Int { get }
    /// The raw temperature as read from the sensor
    var rawTemperature: Int { get }

    var rawTemperatureAdjustment: Int { get }
}

struct SimplifiedMeasurement: MeasurementProtocol {
    var rawGlucose: Int

    var rawTemperature: Int

    var rawTemperatureAdjustment: Int = 0
}

/// Structure for one glucose measurement including value, date and raw data bytes
struct Measurement: MeasurementProtocol {
    /// The date for this measurement
    let date: Date
    /// The minute counter for this measurement
    let counter: Int
    /// The bytes as read from the sensor. All data is derived from this \"raw data"
    let bytes: [UInt8]
    /// The bytes as String
    let byteString: String
    /// The raw glucose as read from the sensor
    let rawGlucose: Int
    /// The raw temperature as read from the sensor
    let rawTemperature: Int

    let rawTemperatureAdjustment: Int

    ///
    /// - parameter bytes:  raw data bytes as read from the sensor
    /// - parameter slope:  slope to calculate glucose from raw value in (mg/dl)/raw
    /// - parameter offset: glucose offset to be added in mg/dl
    /// - parameter date:   date of the measurement
    ///
    /// - returns: Measurement
    init(bytes: [UInt8], slope: Double = 0.1, offset: Double = 0.0, counter: Int = 0, date: Date) {
        self.bytes = bytes
        self.byteString = bytes.reduce("", { $0 + String(format: "%02X", arguments: [$1]) })
        //self.rawGlucose = (Int(bytes[1] & 0x1F) << 8) + Int(bytes[0]) // switched to 13 bit mask on 2018-03-15
        self.rawGlucose = SensorData.readBits(bytes, 0, 0, 0xe)

        //self.rawTemperature = (Int(bytes[4] & 0x3F) << 8) + Int(bytes[3]) // 14 bit-mask for raw temperature
        //raw temperature in libre FRAM is always stored in multiples of four
        self.rawTemperature = SensorData.readBits(bytes, 0, 0x1a, 0xc) << 2

        let temperatureAdjustment = (SensorData.readBits(bytes, 0, 0x26, 0x9) << 2)
        let negativeAdjustment = SensorData.readBits(bytes, 0, 0x2f, 0x1) != 0
        self.rawTemperatureAdjustment = negativeAdjustment ? -temperatureAdjustment : temperatureAdjustment

        self.date = date
        self.counter = counter

//        self.oopSlope = slope_slope * Double(rawTemperature) + offset_slope
//        self.oopOffset = slope_offset * Double(rawTemperature) + offset_offset
//        self.oopGlucose = oopSlope * Double(rawGlucose) + oopOffset

    }

    var description: String {
        var aString = String(" date:  \(date), rawGlucose: \(rawGlucose), rawTemperature: \(rawTemperature), bytes: \(bytes) \n")

        return aString
    }
}
