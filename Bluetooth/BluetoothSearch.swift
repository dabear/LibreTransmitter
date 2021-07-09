//
//  BluetoothSearch.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 26/07/2019.
//  Copyright © 2019 Bjørn Inge Berg. All rights reserved.
//

import CoreBluetooth
import Foundation
import LibreTransmitter
import os.log
import UIKit

import Combine

final class BluetoothSearchManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    var centralManager: CBCentralManager!

    fileprivate var logger = Logger.init(subsystem: "no.bjorninge.libre", category: "BluetoothSearchManager")

    //fileprivate let deviceNames = SupportedDevices.allNames
    //fileprivate let serviceUUIDs:[CBUUID]? = [CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")]

    private var discoveredDevices = [CBPeripheral]()

    public let passThrough = PassthroughSubject<CBPeripheral, Never>()
    public let passThroughMetaData = PassthroughSubject<(CBPeripheral, [String: Any]), Never>()

    public func addDiscoveredDevice(_ device: CBPeripheral, with metadata: [String: Any] ) {
        passThrough.send(device)
        passThroughMetaData.send((device, metadata))
    }

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: nil)
        //        slipBuffer.delegate = self
        logger.debug("BluetoothSearchManager init called ")
    }

    func scanForCompatibleDevices() {

        if centralManager.state == .poweredOn && !centralManager.isScanning {
            logger.debug("Before scan for MiaoMiao while central manager state \(String(describing: self.centralManager.state.rawValue))")

            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }

    func disconnectManually() {
        logger.debug("did disconnect manually")
        //        NotificationManager.scheduleDebugNotification(message: "Timer fired in Background", wait: 3)
        //        _ = Timer(timeInterval: 150, repeats: false, block: {timer in NotificationManager.scheduleDebugNotification(message: "Timer fired in Background", wait: 0.5)})

            if centralManager.isScanning {
                centralManager.stopScan()
            }
    }

    // MARK: - CBCentralManagerDelegate

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        logger.debug("Central Manager did update state to \(String(describing: central.state.rawValue))")
        switch central.state {
        case .poweredOff, .resetting, .unauthorized, .unknown, .unsupported:
            logger.debug("Central Manager was either .poweredOff, .resetting, .unauthorized, .unknown, .unsupported: \(String(describing: central.state))")
        case .poweredOn:

                scanForCompatibleDevices() // power was switched on, while app is running -> reconnect.
        @unknown default:
            fatalError("libre bluetooth state unhandled")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let name = peripheral.name?.lowercased() else {
            logger.debug("dabear:: could not find name for device \(peripheral.identifier.uuidString)")
            return
        }

        if LibreTransmitters.isSupported(peripheral) {
            logger.debug("dabear:: did recognize device: \(name): \(peripheral.identifier)")
            self.addDiscoveredDevice(peripheral, with: advertisementData)
        } else {
            if UserDefaults.standard.dangerModeActivated {
                //allow listing any device when danger mode is active

                let name = String(describing: peripheral.name)

                logger.debug("dabear:: did add unknown device due to dangermode being active \(name): \(peripheral.identifier)")
                self.addDiscoveredDevice(peripheral, with: advertisementData)
            } else {
                logger.debug("dabear:: did not add unknown device: \(name): \(peripheral.identifier)")
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        //self.lastConnectedIdentifier = peripheral.identifier.uuidString

    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        logger.error("did fail to connect")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        logger.debug("did didDisconnectPeripheral")
    }

    // MARK: - CBPeripheralDelegate

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        logger.debug("Did discover services")
        if let error = error {
            logger.error("Did discover services error: \(error.localizedDescription)")
        }

        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)

                logger.debug("Did discover service: \(String(describing: service.debugDescription))")
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        logger.debug("Did discover characteristics for service \(String(describing: peripheral.name))")

        if let error = error {
            logger.error("Did discover characteristics for service error: \(error.localizedDescription)")
        }

        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                logger.debug("Did discover characteristic: \(String(describing: characteristic.debugDescription))")

                if (characteristic.properties.intersection(.notify)) == .notify && characteristic.uuid == CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E") {
                    peripheral.setNotifyValue(true, for: characteristic)
                    logger.debug("Set notify value for this characteristic")
                }
                if characteristic.uuid == CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E") {
                    //writeCharacteristic = characteristic
                }
            }
        } else {
            logger.error("Discovered characteristics, but no characteristics listed. There must be some error.")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        logger.debug("Did update notification state for characteristic: \(String(describing: characteristic.debugDescription))")
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        logger.debug("Did update value for characteristic: \(String(describing: characteristic.debugDescription))")
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        logger.debug("Did Write value \(String(characteristic.value.debugDescription)) for characteristic \(String(characteristic.debugDescription))")
    }

    deinit {
        logger.debug("dabear:: BluetoothSearchManager deinit called")
    }
}
