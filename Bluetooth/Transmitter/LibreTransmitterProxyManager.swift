//
//  MiaoMiaoManager.swift
//  LibreMonitor
//
//  Created by Uwe Petersen on 10.03.18, heravily modified by Bjørn Berg.
//  Copyright © 2018 Uwe Petersen. All rights reserved.
//

import CoreBluetooth
import Foundation
import HealthKit
import os.log
import UIKit

public enum BluetoothmanagerState: String {
    case Unassigned = "Unassigned"
    case Scanning = "Scanning"
    case Disconnected = "Disconnected"
    case DelayedReconnect = "Will soon reconnect"
    case DisconnectingDueToButtonPress = "Disconnecting due to button press"
    case Connecting = "Connecting"
    case Connected = "Connected"
    case Notifying = "Notifying"
    case powerOff = "powerOff"
    case UnknownDevice = "UnknownDevice"
}

public protocol LibreTransmitterDelegate: class {
    // Can happen on any queue
    func libreTransmitterStateChanged(_ state: BluetoothmanagerState)
    func libreTransmitterReceivedMessage(_ messageIdentifier: UInt16, txFlags: UInt8, payloadData: Data)
    // Will always happen on managerQueue
    func libreTransmitterDidUpdate(with sensorData: SensorData, and Device: LibreTransmitterMetadata)

    func noLibreTransmitterSelected()
    func libreManagerDidRestoreState(found peripherals: [CBPeripheral], connected to: CBPeripheral?)
    func UpdateBadge()
}

extension LibreTransmitterDelegate {
    func noLibreTransmitterSelected() {}
    public func libreManagerDidRestoreState(found peripherals: [CBPeripheral], connected to: CBPeripheral?) {}
}

final class LibreTransmitterProxyManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, LibreTransmitterDelegate {
    func UpdateBadge() {
        os_log("libreTransmitterBadge changed", log: Self.bt_log)
        dispatchToDelegate { manager in
            manager.delegate?.UpdateBadge()
        }
    }
    
    func libreManagerDidRestoreState(found peripherals: [CBPeripheral], connected to: CBPeripheral?) {
        dispatchToDelegate { manager in
            manager.delegate?.libreManagerDidRestoreState(found: peripherals, connected: to)
        }
    }

    func noLibreTransmitterSelected() {
        dispatchToDelegate { manager in
            manager.delegate?.noLibreTransmitterSelected()
        }
    }

    func libreTransmitterStateChanged(_ state: BluetoothmanagerState) {
        os_log("libreTransmitterStateChanged delegating", log: Self.bt_log)

        dispatchToDelegate { manager in
           manager.delegate?.libreTransmitterStateChanged(state)
        }
    }

    func libreTransmitterReceivedMessage(_ messageIdentifier: UInt16, txFlags: UInt8, payloadData: Data) {
        os_log("libreTransmitterReceivedMessage delegating", log: Self.bt_log)
        dispatchToDelegate { manager in
            manager.delegate?.libreTransmitterReceivedMessage(messageIdentifier, txFlags: txFlags, payloadData: payloadData)
        }
    }

    func libreTransmitterDidUpdate(with sensorData: SensorData, and Device: LibreTransmitterMetadata) {
        self.metadata = Device
        self.sensorData = sensorData

        os_log("libreTransmitterDidUpdate delegating", log: Self.bt_log)
        dispatchToDelegate { manager in
            manager.delegate?.libreTransmitterDidUpdate(with: sensorData, and: Device)
        }
    }
    

    // MARK: - Properties
    private var wantsToTerminate = false
    //private var lastConnectedIdentifier : String?

    var activePlugin: LibreTransmitterProxy? = nil {
        didSet {
            print("dabear:: activePlugin changed from \(oldValue) to \(activePlugin)")
        }
    }

    var activePluginType: LibreTransmitterProxy.Type? {
        activePlugin?.staticType
    }

    var shortTransmitterName: String? {
        activePluginType?.shortTransmitterName
    }

    static let bt_log = OSLog(subsystem: "com.LibreMonitor", category: "MiaoMiaoManager")
    var metadata: LibreTransmitterMetadata?

    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral?
    //    var slipBuffer = SLIPBuffer()
    var writeCharacteristic: CBCharacteristic?

    var sensorData: SensorData?

    public var identifier: UUID? {
        peripheral?.identifier
    }

    private let managerQueue = DispatchQueue(label: "no.bjorninge.bluetoothManagerQueue", qos: .utility)
    private let delegateQueue = DispatchQueue(label: "no.bjorninge.delegateQueue", qos: .utility)

    fileprivate var serviceUUIDs: [CBUUID]? {
        activePluginType?.serviceUUID.map { $0.value }
    }
    fileprivate var writeCharachteristicUUID: CBUUID? {
        activePluginType?.writeCharacteristic?.value
    }
    fileprivate var notifyCharacteristicUUID: CBUUID? {
        activePluginType?.notifyCharacteristic?.value
    }

    weak var delegate: LibreTransmitterDelegate? {
        didSet {
           dispatchToDelegate { manager in
                // Help delegate initialize by sending current state directly after delegate assignment
                manager.delegate?.libreTransmitterStateChanged(self.state)
           }
        }
    }

    private var state: BluetoothmanagerState = .Unassigned {
        didSet {
            dispatchToDelegate { manager in
                // Help delegate initialize by sending current state directly after delegate assignment
                manager.delegate?.libreTransmitterStateChanged(self.state)
            }
        }
    }
    public var connectionStateString: String {
        self.state.rawValue
    }

    public func dispatchToDelegate( _ closure :@escaping  (_ aself: LibreTransmitterProxyManager) -> Void ) {
        delegateQueue.async { [weak self] in
            if let self = self {
                closure(self)
            }
        }
    }

    //lazy var viaManagerQueue = QueuedPropertyAccess(self, dispatchQueue: managerQueue)

    // MARK: - Methods

    override init() {
        super.init()

        //        slipBuffer.delegate = self
        os_log("miaomiaomanager init called ", log: Self.bt_log)
        managerQueue.sync {
            centralManager = CBCentralManager(delegate: self, queue: managerQueue, options: [CBCentralManagerOptionShowPowerAlertKey: true, CBCentralManagerOptionRestoreIdentifierKey: "LibreMonitorCoreBluetoothRestaurationKeyString"])
        }
    }

    func scanForDevices() {
        dispatchPrecondition(condition: .onQueue(managerQueue))

        os_log("Scan for MiaoMiao while internal state %{public}@, bluetooth state %{public}@", log: Self.bt_log, type: .default, String(describing: state), String(describing: centralManager.state ))

        guard centralManager.state == .poweredOn else {
            return
        }
        os_log("Before scan for MiaoMiao while central manager state %{public}@", log: Self.bt_log, type: .default, String(describing: centralManager.state.rawValue))

        let scanForAllServices = true

        //this will search for all peripherals. Guaranteed to work
        if scanForAllServices {
            os_log("Scanning for all services:", log: Self.bt_log, type: .default)
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        } else {
            // This is what we should have done
            // Here we optimize by scanning only for relevant services
            // However, this doesn't work correctly with both miaomiao and bubble
            let services = LibreTransmitters.all.getServicesForDiscovery()
            os_log("Scanning for specific services: %{public}@", log: Self.bt_log, type: .default, String(describing: services.map { $0.uuidString }))
        }

        state = .Scanning
    }

    private func reset() {
        os_log("manager is resetting the activeplugin ", log: Self.bt_log, type: .default)
        self.activePlugin?.reset()
    }

    private func connect(force forceConnect: Bool = false, advertisementData: [String: Any]?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        os_log("Connect while state %{public}@", log: Self.bt_log, type: .default, String(describing: state.rawValue))
        if centralManager.isScanning {
            centralManager.stopScan()
        }
        if state == .DisconnectingDueToButtonPress && !forceConnect {
            os_log("Connect aborted, user has actively disconnected and a reconnect was not forced ", log: Self.bt_log, type: .default)
            return
        }

        if let peripheral = self.peripheral {
            peripheral.delegate = self

            if activePlugin?.canSupportPeripheral(peripheral) == true {
                //when reaching this part,
                //we are sure the peripheral is reconnecting and therefore needs reset
                os_log("Connecting to known device with known plugin", log: Self.bt_log, type: .default)

                self.reset()

                centralManager.connect(peripheral, options: nil)
                state = .Connecting
            } else if let plugin = LibreTransmitters.getSupportedPlugins(peripheral)?.first {
                self.activePlugin = plugin.init(delegate: self, advertisementData: advertisementData)

                os_log("Connecting to new device with known plugin", log: Self.bt_log, type: .default)
                //only connect to devices we can support (i.e. devices that has a suitable plugin)
                centralManager.connect(peripheral, options: nil)
                state = .Connecting
            } else {
                state = .UnknownDevice
            }
        }
    }

    func disconnectManually() {
        dispatchPrecondition(condition: .notOnQueue(managerQueue))
        os_log("Disconnect manually while state %{public}@", log: Self.bt_log, type: .default, String(describing: self.state.rawValue))

        managerQueue.sync {
            switch self.state {
            case .Connected, .Connecting, .Notifying, .Scanning:
                self.state = .DisconnectingDueToButtonPress  // to avoid reconnect in didDisconnetPeripheral

                self.wantsToTerminate = true
            default:
                break
            }

            if centralManager.isScanning {
                os_log("stopping scan", log: Self.bt_log, type: .default)
                centralManager.stopScan()
            }
            if let peripheral = peripheral {
                centralManager.cancelPeripheralConnection(peripheral)
            }
        }
    }

    // MARK: - CBCentralManagerDelegate

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        os_log("Central Manager did update state to %{public}@", log: Self.bt_log, type: .default, String(describing: central.state.rawValue))

        switch central.state {
        case .poweredOff:
            state = .powerOff
        case .resetting, .unauthorized, .unknown, .unsupported:
            os_log("Central Manager was either .poweredOff, .resetting, .unauthorized, .unknown, .unsupported: %{public}@", log: Self.bt_log, type: .default, String(describing: central.state))
            state = .Unassigned

            if central.state == .resetting, let peripheral = self.peripheral {
                os_log("Central Manager resetting, will cancel peripheral connection", log: Self.bt_log, type: .default)
                central.cancelPeripheralConnection(peripheral)
                self.peripheral = nil
            }

            if central.isScanning {
                central.stopScan()
            }
        case .poweredOn:

            if state == .DisconnectingDueToButtonPress {
                os_log("Central Manager was powered on but sensorstate was DisconnectingDueToButtonPress:  %{public}@", log: Self.bt_log, type: .default, String(describing: central.state))
                return
            }

            os_log("Central Manager was powered on", log: Self.bt_log, type: .default)

            //not sure if needed, but can be helpful when state is restored
            if let peripheral = peripheral, delegate != nil {
                // do not scan if already connected
                switch peripheral.state {
                case .disconnected, .disconnecting:
                    os_log("Central Manager was powered on, peripheral state is disconnecting", log: Self.bt_log, type: .default)
                    self.connect(advertisementData: nil)
                case .connected, .connecting:
                    os_log("Central Manager was powered on, peripheral state is connected/connecting, renewing plugin", log: Self.bt_log, type: .default)

                    // This is necessary
                    // Normally the connect() method would have set the correct plugin,
                    // however when we hit this path, it is likely a state restoration
                    if self.activePlugin == nil || self.activePlugin?.canSupportPeripheral(peripheral) == false {
                        let plugin = LibreTransmitters.getSupportedPlugins(peripheral)?.first
                        self.activePlugin = plugin?.init(delegate: self, advertisementData: nil)

                        os_log("Central Manager was powered on, peripheral state is connected/connecting, stopping scan", log: Self.bt_log, type: .default)
                        if central.isScanning && peripheral.state == .connected {
                            central.stopScan()
                        }
                        if peripheral.delegate == nil {
                            os_log("Central Manager was powered on, peripheral delegate was nil", log: Self.bt_log, type: .default)
                        }
                    }

                    if let serviceUUIDs = serviceUUIDs, !serviceUUIDs.isEmpty {
                        peripheral.discoverServices(serviceUUIDs) // good practice to just discover the services, needed
                    } else {
                         os_log("Central Manager was powered on, could not discover services", log: Self.bt_log, type: .default)
                    }

                default:
                        print("already connected")
                }
            } else {
                 os_log("Central Manager was powered on, scanningformiaomiao: state: %{public}@", log: Self.bt_log, type: .default, String(describing: state))
                 scanForDevices() // power was switched on, while app is running -> reconnect.

            }
        @unknown default:
            fatalError("libre bluetooth state unhandled")
        }
    }

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        os_log("Central Manager will restore state to %{public}@", log: Self.bt_log, type: .default, String(describing: dict.debugDescription))

        guard self.peripheral == nil else {
            os_log("Central Manager tried to restore state while already connected", log: Self.bt_log, type: .default)
            return
        }

        guard let preselected = UserDefaults.standard.preSelectedDevice else {
            os_log("Central Manager tried to restore state but no device was preselected", log: Self.bt_log, type: .default)
            return
        }

        guard let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] else {
            os_log("Central Manager tried to restore state but no peripheral found", log: Self.bt_log, type: .default)
            return
        }

        defer {
            self.libreManagerDidRestoreState(found: peripherals, connected: self.peripheral)
        }

        let restorablePeripheral = peripherals.first(where: { $0.identifier.uuidString == preselected })

        guard let peripheral = restorablePeripheral else {
            return
        }

        self.peripheral = peripheral
        peripheral.delegate = self

        switch peripheral.state {
        case .disconnected, .disconnecting:
            os_log("Central Manager tried to restore state from disconnected peripheral", log: Self.bt_log, type: .default)
            state = .Disconnected
            self.connect(advertisementData: nil)
        case .connecting:
            os_log("Central Manager tried to restore state from connecting peripheral", log: Self.bt_log, type: .default)
            state = .Connecting
        case .connected:
            os_log("Central Manager tried to restore state from connected peripheral, letting centralManagerDidUpdateState() do the rest of the job", log: Self.bt_log, type: .default)
            //the idea here is to let centralManagerDidUpdateState() do the heavy lifting
            // after all, we did assign the periheral.delegate to self earlier

            //that means the following is not necessary:
            //state = .Connected
            //peripheral.discoverServices(serviceUUIDs) // good practice to just discover the services, needed
        @unknown default:
            fatalError("Failed due to unkown default, Uwe!")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        dispatchPrecondition(condition: .onQueue(managerQueue))

        os_log("Did discover peripheral while state %{public}@ with name: %{public}@, wantstoterminate?:  %d", log: Self.bt_log, type: .default, String(describing: state.rawValue), String(describing: peripheral.name), self.wantsToTerminate)

        if let preselected = UserDefaults.standard.preSelectedDevice {
            if peripheral.identifier.uuidString == preselected {
                os_log("Did connect to preselected %{public}@ with identifier %{public}@,", log: Self.bt_log, type: .default, String(describing: peripheral.name), String(describing: peripheral.identifier.uuidString))
                self.peripheral = peripheral

                self.connect(force: true, advertisementData: advertisementData)
            } else {
                os_log("Did not connect to %{public}@ with identifier %{public}@, because another device with identifier %{public}@ was selected", log: Self.bt_log, type: .default, String(describing: peripheral.name), String(describing: peripheral.identifier.uuidString), preselected)
            }

            return
        } else {
            self.noLibreTransmitterSelected()
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        dispatchPrecondition(condition: .onQueue(managerQueue))

        os_log("Did connect peripheral while state %{public}@ with name: %{public}@", log: Self.bt_log, type: .default, String(describing: state.rawValue), String(describing: peripheral.name))
        if central.isScanning {
            central.stopScan()
        }
        state = .Connected
        //self.lastConnectedIdentifier = peripheral.identifier.uuidString
        // Discover all Services. This might be helpful if writing is needed some time
        peripheral.discoverServices(serviceUUIDs)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))

        os_log("Did fail to connect peripheral while state: %{public}@", log: Self.bt_log, type: .default, String(describing: state.rawValue))
        if let error = error {
            os_log("Did fail to connect peripheral error: %{public}@", log: Self.bt_log, type: .error, "\(error.localizedDescription)")
        }
        state = .Disconnected

        self.delayedReconnect()
    }

    private func delayedReconnect(_ seconds: Double = 7) {
        state = .DelayedReconnect

        os_log("Will reconnect peripheral in  %{public}@ seconds", log: Self.bt_log, type: .default, String(describing: seconds))
        self.reset()
        // attempt to avoid IOS killing app because of cpu usage.
        // postpone connecting for x seconds
        DispatchQueue.global(qos: .utility).async { [weak self] in
            Thread.sleep(forTimeInterval: seconds)
            self?.managerQueue.sync {
                self?.connect(advertisementData: nil)
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))

        os_log("Did disconnect peripheral while state: %{public}@", log: Self.bt_log, type: .default, String(describing: state.rawValue))
        if let error = error {
            os_log("Did disconnect peripheral error: %{public}@", log: Self.bt_log, type: .error, "\(error.localizedDescription)")
        }

        switch state {
        case .DisconnectingDueToButtonPress:
            state = .Disconnected
            self.wantsToTerminate = true

        default:
            state = .Disconnected
            self.delayedReconnect()
            //    scanForMiaoMiao()
        }
    }

    // MARK: - CBPeripheralDelegate

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        os_log("Did discover services. is plugin nil? %{public}@", log: Self.bt_log, type: .default, (activePlugin == nil ? "nil" : "not nil") )
        if let error = error {
            os_log("Did discover services error: %{public}@", log: Self.bt_log, type: .error, "\(error.localizedDescription)")
        }

        if let services = peripheral.services {
            for service in services {
                let toDiscover = [writeCharachteristicUUID, notifyCharacteristicUUID].compactMap { $0 }

                os_log("Will discover : %{public}@ Characteristics for service  %{public}@", log: Self.bt_log, type: .default, String(describing: toDiscover.count), String(describing: service.debugDescription))

                if !toDiscover.isEmpty {
                    peripheral.discoverCharacteristics(toDiscover, for: service)

                    os_log("Did discover service: %{public}@", log: Self.bt_log, type: .default, String(describing: service.debugDescription))
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))

        os_log("Did discover characteristics for service %{public}@", log: Self.bt_log, type: .default, String(describing: peripheral.name))

        if let error = error {
            os_log("Did discover characteristics for service error: %{public}@", log: Self.bt_log, type: .error, "\(error.localizedDescription)")
        }

        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                os_log("Did discover characteristic: %{public}@", log: Self.bt_log, type: .default, String(describing: characteristic.debugDescription))
                //                print("Characteristic: ")
                //                debugPrint(characteristic.debugDescription)
                //                print("... with properties: ")
                //                debugPrint(characteristic.properties)
                //                print("Broadcast:                           ", [characteristic.properties.contains(.broadcast)])
                //                print("Read:                                ", [characteristic.properties.contains(.read)])
                //                print("WriteWithoutResponse:                ", [characteristic.properties.contains(.writeWithoutResponse)])
                //                print("Write:                               ", [characteristic.properties.contains(.write)])
                //                print("Notify:                              ", [characteristic.properties.contains(.notify)])
                //                print("Indicate:                            ", [characteristic.properties.contains(.indicate)])
                //                print("AuthenticatedSignedWrites:           ", [characteristic.properties.contains(.authenticatedSignedWrites )])
                //                print("ExtendedProperties:                  ", [characteristic.properties.contains(.extendedProperties)])
                //                print("NotifyEncryptionRequired:            ", [characteristic.properties.contains(.notifyEncryptionRequired)])
                //                print("BroaIndicateEncryptionRequireddcast: ", [characteristic.properties.contains(.indicateEncryptionRequired)])
                //                print("Serivce for Characteristic:          ", [characteristic.service.debugDescription])
                //
                //                if characteristic.service.uuid == CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E") {
                //                    print("\n B I N G O \n")
                //                }

                // Choose the notifiying characteristic and Register to be notified whenever the MiaoMiao transmits
                if characteristic.properties.intersection(.notify) == .notify && characteristic.uuid == notifyCharacteristicUUID {
                    peripheral.setNotifyValue(true, for: characteristic)
                    os_log("Set notify value for this characteristic", log: Self.bt_log, type: .default)
                }
                if characteristic.uuid == writeCharachteristicUUID {
                    writeCharacteristic = characteristic
                }
            }
        } else {
            os_log("Discovered characteristics, but no characteristics listed. There must be some error.", log: Self.bt_log, type: .default)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        os_log("Did update notification state for characteristic: %{public}@", log: Self.bt_log, type: .default, String(describing: characteristic.debugDescription))

        if let error = error {
            os_log("Peripheral did update notification state for characteristic: %{public}@ with error", log: Self.bt_log, type: .error, "\(error.localizedDescription)")
        } else {
            self.reset()
            requestData()
        }
        state = .Notifying
    }

    private var lastNotifyUpdate: Date?
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))

        let now = Date()

        // We can expect thedevices to complete well within 5 seconds for all the telegrams combined in a session
        // it is therefore reasonable to expect the time between one telegram
        // to the other in the same session to be well within 6 seconds
        // this path will be hit when a telegram for some reason is dropped
        // in a session. Or that the user disconnecting and reconnecting during a transmission
        // By resetting here we ensure that the rxbuffer doesn't leak over into the next session
        // Leaking over into the next session, is however not a problem for consitency as we always check the CRC's anyway
        if let lastNotifyUpdate = self.lastNotifyUpdate, now > lastNotifyUpdate.addingTimeInterval(6) {
            NSLog("dabear:: there hasn't been any traffic to  the \(self.activePluginType?.shortTransmitterName) plugin for more than 10 seconds, so we reset now")
            self.reset()
        }

        os_log("Did update value for characteristic: %{public}@", log: Self.bt_log, type: .default, String(describing: characteristic.debugDescription))

        self.lastNotifyUpdate = now

        if let error = error {
            os_log("Characteristic update error: %{public}@", log: Self.bt_log, type: .error, "\(error.localizedDescription)")
        } else {
            if characteristic.uuid == notifyCharacteristicUUID, let value = characteristic.value {
                if self.activePlugin == nil {
                    os_log("Characteristic update error: activeplugin was nil", log: Self.bt_log, type: .error)
                }
                self.activePlugin?.updateValueForNotifyCharacteristics(value, peripheral: peripheral, writeCharacteristic: writeCharacteristic)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        os_log("Did Write value %{public}@ for characteristic %{public}@", log: Self.bt_log, type: .default, String(characteristic.value.debugDescription), String(characteristic.debugDescription))
    }

    func requestData() {
       guard let peripheral = peripheral,
            let writeCharacteristic = writeCharacteristic else {
                return
        }
        self.activePlugin?.requestData(writeCharacteristics: writeCharacteristic, peripheral: peripheral)
    }

    deinit {
        self.activePlugin = nil
        self.delegate = nil
        os_log("dabear:: miaomiaomanager deinit called")
    }
}

extension LibreTransmitterProxyManager {
    public var manufacturer: String {
        activePluginType?.manufacturerer ?? "n/a"
    }

    var device: HKDevice? {
        HKDevice(
            name: "MiaomiaoClient",
            manufacturer: manufacturer,
            model: nil, //latestSpikeCollector,
            hardwareVersion: self.metadata?.hardware ,
            firmwareVersion: self.metadata?.firmware,
            softwareVersion: nil,
            localIdentifier: identifier?.uuidString,
            udiDeviceIdentifier: nil
        )
    }
}
