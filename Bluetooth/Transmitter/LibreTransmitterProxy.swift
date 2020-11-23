//
//  LibreTransmitter.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 08/01/2020.
//  Copyright © 2020 Bjørn Inge Berg. All rights reserved.
//

import CoreBluetooth
import Foundation
import UIKit
public protocol LibreTransmitterProxy: class {
    static var shortTransmitterName: String { get }
    static var smallImage: UIImage? { get }
    static var manufacturerer: String { get }
    static func canSupportPeripheral(_ peripheral: CBPeripheral) -> Bool

    static var writeCharacteristic: UUIDContainer? { get set }
    static var notifyCharacteristic: UUIDContainer? { get set }
    static var serviceUUID: [UUIDContainer] { get set }

    var delegate: LibreTransmitterDelegate? { get set }
    init(delegate: LibreTransmitterDelegate, advertisementData: [String: Any]? )
    func requestData(writeCharacteristics: CBCharacteristic, peripheral: CBPeripheral)
    func updateValueForNotifyCharacteristics(_ value: Data, peripheral: CBPeripheral, writeCharacteristic: CBCharacteristic?)

    func reset()

    static func getDeviceDetailsFromAdvertisement(advertisementData: [String: Any]?) -> String?
}

extension LibreTransmitterProxy {
    func canSupportPeripheral(_ peripheral: CBPeripheral) -> Bool {
        Self.canSupportPeripheral(peripheral)
    }
    public var staticType: LibreTransmitterProxy.Type {
        Self.self
    }
}

extension Array where Array.Element == LibreTransmitterProxy.Type {
    func getServicesForDiscovery() -> [CBUUID] {
        self.flatMap {
            return $0.serviceUUID.map { $0.value }
        }.removingDuplicates()
    }
}

public enum LibreTransmitters {
    public static var all: [LibreTransmitterProxy.Type] {
        [MiaoMiaoTransmitter.self, BubbleTransmitter.self]
    }
    public static func isSupported(_ peripheral: CBPeripheral) -> Bool {
        getSupportedPlugins(peripheral)?.isEmpty == false
    }

    public static func getSupportedPlugins(_ peripheral: CBPeripheral) -> [LibreTransmitterProxy.Type]? {
        all.enumerated().compactMap {
            $0.element.canSupportPeripheral(peripheral) ? $0.element : nil
        }
    }
}
