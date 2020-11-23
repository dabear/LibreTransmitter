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
    static let bt_log = OSLog(subsystem: "com.LibreMonitor", category: "BluetoothSearchManager")

    var centralManager: CBCentralManager!

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
        os_log("BluetoothSearchManager init called ", log: Self.bt_log)
    }

    func scanForCompatibleDevices() {
        //        print(centralManager.debugDescription)
        if centralManager.state == .poweredOn && !centralManager.isScanning {
            os_log("Before scan for MiaoMiao while central manager state %{public}@", log: Self.bt_log, type: .default, String(describing: centralManager.state.rawValue))

            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }

    func disconnectManually() {
            print("did disconnect manually")
        //        NotificationManager.scheduleDebugNotification(message: "Timer fired in Background", wait: 3)
        //        _ = Timer(timeInterval: 150, repeats: false, block: {timer in NotificationManager.scheduleDebugNotification(message: "Timer fired in Background", wait: 0.5)})

            if centralManager.isScanning {
                centralManager.stopScan()
            }
    }

    // MARK: - CBCentralManagerDelegate

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        os_log("Central Manager did update state to %{public}@", log: Self.bt_log, type: .default, String(describing: central.state.rawValue))

        switch central.state {
        case .poweredOff, .resetting, .unauthorized, .unknown, .unsupported:
            os_log("Central Manager was either .poweredOff, .resetting, .unauthorized, .unknown, .unsupported: %{public}@", log: Self.bt_log, type: .default, String(describing: central.state))
        case .poweredOn:
                //os_log("Central Manager was powered on, scanningformiaomiao: state: %{public}@", log: MiaoMiaoBluetoothManager.bt_log, type: .default, String(describing: state))

                scanForCompatibleDevices() // power was switched on, while app is running -> reconnect.
        @unknown default:
            fatalError("libre bluetooth state unhandled")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let name = peripheral.name?.lowercased() else {
            print("dabear:: could not find name for device \(peripheral.identifier.uuidString)")
            return
        }

        if LibreTransmitters.isSupported(peripheral) {
            print("dabear:: did recognize device: \(name): \(peripheral.identifier)")
            self.addDiscoveredDevice(peripheral, with: advertisementData)
        } else {
            if UserDefaults.standard.dangerModeActivated {
                //allow listing any device when danger mode is active

                print("dabear:: did add unknown device due to dangermode being active \(peripheral.name): \(peripheral.identifier)")
                self.addDiscoveredDevice(peripheral, with: advertisementData)
            } else {
                print("dabear:: did not add unknown device: \(peripheral.name): \(peripheral.identifier)")
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        //self.lastConnectedIdentifier = peripheral.identifier.uuidString

    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("did fail to connect")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
       print("did didDisconnectPeripheral")
    }

    // MARK: - CBPeripheralDelegate

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        os_log("Did discover services", log: Self.bt_log, type: .default)
        if let error = error {
            os_log("Did discover services error: %{public}@", log: Self.bt_log, type: .error, "\(error.localizedDescription)")
        }

        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)

                os_log("Did discover service: %{public}@", log: Self.bt_log, type: .default, String(describing: service.debugDescription))
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        os_log("Did discover characteristics for service %{public}@", log: Self.bt_log, type: .default, String(describing: peripheral.name))

        if let error = error {
            os_log("Did discover characteristics for service error: %{public}@", log: Self.bt_log, type: .error, "\(error.localizedDescription)")
        }

        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                os_log("Did discover characteristic: %{public}@", log: Self.bt_log, type: .default, String(describing: characteristic.debugDescription))

                if (characteristic.properties.intersection(.notify)) == .notify && characteristic.uuid == CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E") {
                    peripheral.setNotifyValue(true, for: characteristic)
                    os_log("Set notify value for this characteristic", log: Self.bt_log, type: .default)
                }
                if characteristic.uuid == CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E") {
                    //writeCharacteristic = characteristic
                }
            }
        } else {
            os_log("Discovered characteristics, but no characteristics listed. There must be some error.", log: Self.bt_log, type: .default)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        os_log("Did update notification state for characteristic: %{public}@", log: Self.bt_log, type: .default, String(describing: characteristic.debugDescription))
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        os_log("Did update value for characteristic: %{public}@", log: Self.bt_log, type: .default, String(describing: characteristic.debugDescription))
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        os_log("Did Write value %{public}@ for characteristic %{public}@", log: Self.bt_log, type: .default, String(characteristic.value.debugDescription), String(characteristic.debugDescription))
    }

    deinit {
        os_log("dabear:: BluetoothSearchManager deinit called")
    }
}
