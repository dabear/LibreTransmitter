//
//  NewGlucoseSample.swift
//  LibreTransmitter
//
//  Created by Bjørn Inge Berg on 12/07/2021.
//  Copyright © 2021 Mark Wilson. All rights reserved.
//

import Foundation
#if !canImport(LoopKit) && !canImport(LoopKitUI)
import HealthKit
public struct NewGlucoseSample: Equatable {
    public let date: Date
    public let quantity: HKQuantity
    public let isDisplayOnly: Bool
    public let wasUserEntered: Bool
    public let syncIdentifier: String
    public var syncVersion: Int
    public var device: HKDevice?

    /// - Parameters:
    ///   - date: The date the sample was collected
    ///   - quantity: The glucose sample quantity
    ///   - isDisplayOnly: Whether the reading was shifted for visual consistency after calibration
    ///   - wasUserEntered: Whether the reading was entered by the user (manual) or not (device)
    ///   - syncIdentifier: A unique identifier representing the sample, used for de-duplication
    ///   - syncVersion: A version number for determining resolution in de-duplication
    ///   - device: The description of the device the collected the sample
    public init(date: Date, quantity: HKQuantity, isDisplayOnly: Bool, wasUserEntered: Bool, syncIdentifier: String, syncVersion: Int = 1, device: HKDevice? = nil) {
        self.date = date
        self.quantity = quantity
        self.isDisplayOnly = isDisplayOnly
        self.wasUserEntered = wasUserEntered
        self.syncIdentifier = syncIdentifier
        self.syncVersion = syncVersion
        self.device = device
    }
}

fileprivate var  MetadataKeyGlucoseIsDisplayOnly = "com.loudnate.GlucoseKit.HKMetadataKey.GlucoseIsDisplayOnly"

extension NewGlucoseSample {
    
    public var quantitySample: HKQuantitySample {
        var metadata: [String: Any] = [
            HKMetadataKeySyncIdentifier: syncIdentifier,
            HKMetadataKeySyncVersion: syncVersion,
        ]

        if isDisplayOnly {
            metadata[MetadataKeyGlucoseIsDisplayOnly] = true
        }
        if wasUserEntered {
            metadata[HKMetadataKeyWasUserEntered] = true
        }

        return HKQuantitySample(
            type: HKQuantityType.quantityType(forIdentifier: .bloodGlucose)!,
            quantity: quantity,
            start: date,
            end: date,
            device: device,
            metadata: metadata
        )
    }
}

public protocol TimelineValue {
    var startDate: Date { get }
    var endDate: Date { get }
}


public extension TimelineValue {
    var endDate: Date {
        return startDate
    }
}


public protocol SampleValue: TimelineValue {
    var quantity: HKQuantity { get }
}


public protocol GlucoseValue: SampleValue {
}

public struct SimpleGlucoseValue: Equatable, GlucoseValue {
    public let startDate: Date
    public let endDate: Date
    public let quantity: HKQuantity

    public init(startDate: Date, endDate: Date? = nil, quantity: HKQuantity) {
        self.startDate = startDate
        self.endDate = endDate ?? startDate
        self.quantity = quantity
    }

    public init(_ glucoseValue: GlucoseValue) {
        self.startDate = glucoseValue.startDate
        self.endDate = glucoseValue.endDate
        self.quantity = glucoseValue.quantity
    }
}

extension SimpleGlucoseValue: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.startDate = try container.decode(Date.self, forKey: .startDate)
        self.endDate = try container.decode(Date.self, forKey: .endDate)
        self.quantity = HKQuantity(unit: HKUnit(from: try container.decode(String.self, forKey: .quantityUnit)),
                                   doubleValue: try container.decode(Double.self, forKey: .quantity))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(quantity.doubleValue(for: .milligramsPerDeciliter), forKey: .quantity)
        try container.encode(HKUnit.milligramsPerDeciliter.unitString, forKey: .quantityUnit)
    }

    private enum CodingKeys: String, CodingKey {
        case startDate
        case endDate
        case quantity
        case quantityUnit
    }
}

#endif
