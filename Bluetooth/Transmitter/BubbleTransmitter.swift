//
//  BubbleTransmitter.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 08/01/2020.
//  Copyright © 2020 Bjørn Inge Berg. All rights reserved.
//

import CoreBluetooth
import Foundation
import UIKit

public enum BubbleResponseType: UInt8 {
    case dataPacket = 130
    case bubbleInfo = 128 // = wakeUp + device info
    case noSensor = 191
    case serialNumber = 192
    case patchInfo = 193 //0xC1
     /// bubble firmware 2.6 support decrypt libre2 344 to libre1 344
     /// if firmware >= 2.6, write [0x08, 0x01, 0x00, 0x00, 0x00, 0x2B]
     /// bubble will decrypt the libre2 data and return it
    //we don't really support decrypteddatapacket as we like to decrypt our selves!
    //case decryptedDataPacket = 136 // 0x88
}

extension BubbleResponseType {
    var description: String {
        switch self {
        case .bubbleInfo:
            return "bubbleinfo"
        case .dataPacket:
            return "datapacket"
        case .noSensor:
            return "nosensor"
        case .serialNumber:
            return "serialnumber"
        default:
            return "unknown"
        }
    }
}

// The Bubble uses the same serviceUUID,
// writeCharachteristic and notifyCharachteristic
// as the MiaoMiao, but different byte sequences
class BubbleTransmitter: MiaoMiaoTransmitter {
    override class var shortTransmitterName: String {
        "bubble"
    }
    override class var manufacturerer: String {
        "bubbledevteam"
    }

    override class var smallImage: UIImage? {
        return UIImage(named: "bubble", in: Bundle.current, compatibleWith: nil)
    }

    override static func canSupportPeripheral(_ peripheral: CBPeripheral) -> Bool {
        peripheral.name?.lowercased().starts(with: "bubble") ?? false
    }

    override func reset() {
        rxBuffer.resetAllBytes()
    }

    private var hardware: String? = ""
    private var firmware: String? = ""
    private var mac: String? = ""

    private var patchInfo: String?
    private var uid: [UInt8]?

    private var battery: Int?

    override class func getDeviceDetailsFromAdvertisement(advertisementData: [String: Any]?) -> String? {
        let (amac, afirmware, ahardware) = Self.getDeviceDetailsFromAdvertisementInternal(advertisementData: advertisementData)

        if let amac = amac, let ahardware = ahardware, let afirmware = afirmware {
            return "\(amac)\n HW:\(ahardware), FW: \(afirmware)"
        }

        return nil
    }

    private static func getDeviceDetailsFromAdvertisementInternal(advertisementData: [String: Any]?) -> (String?, String?, String?) {
        print("dabear: deviceFromAdvertisementData is ")
        debugPrint(advertisementData)

        guard let data = advertisementData?["kCBAdvDataManufacturerData"] as? Data else {
            return (nil, nil, nil)
        }
        var mac = ""
        for i in 0 ..< 6 {
            mac += data.subdata(in: (7 - i)..<(8 - i)).hexEncodedString().uppercased()
            if i != 5 {
                mac += ":"
            }
        }

        guard  data.count >= 12 else {
            return (nil, nil, nil)
        }

        let fSub1 = Data(repeating: data[8], count: 1)
        let fSub2 = Data(repeating: data[9], count: 1)
        let firmware = Float("\(fSub1.hexEncodedString()).\(fSub2.hexEncodedString())")?.description

        let hSub1 = Data(repeating: data[10], count: 1)
        let hSub2 = Data(repeating: data[11], count: 1)

        let hardware = Float("\(hSub1.hexEncodedString()).\(hSub2.hexEncodedString())")?.description
        return (mac, firmware, hardware)
    }

    required init(delegate: LibreTransmitterDelegate, advertisementData: [String: Any]?) {
        //advertisementData is unknown for the miaomiao

        super.init(delegate: delegate, advertisementData: advertisementData)
        //self.delegate = delegate
        //deviceFromAdvertisementData(advertisementData: advertisementData)
        (self.mac, self.firmware, self.hardware) = Self.getDeviceDetailsFromAdvertisementInternal(advertisementData: advertisementData)
    }

    override func requestData(writeCharacteristics: CBCharacteristic, peripheral: CBPeripheral) {
        print("dabear:: bubbleRequestData")
        reset()
        //timer?.invalidate()
        print("-----set: ", writeCharacteristics)
        peripheral.writeValue(Data([0x00, 0x00, 0x05]), for: writeCharacteristics, type: .withResponse)
    }
    override func updateValueForNotifyCharacteristics(_ value: Data, peripheral: CBPeripheral, writeCharacteristic: CBCharacteristic?) {
        print("dabear:: bubbleDidUpdateValueForNotifyCharacteristics, firstbyte is: \(value.first)")
        guard let firstByte = value.first, let bubbleResponseState = BubbleResponseType(rawValue: firstByte) else {
           return
        }
        print("dabear:: bubble responsestate is of type \(bubbleResponseState.description)")
        print("dabear:: bubble value is: \(value.toDebugString())")
        switch bubbleResponseState {
        case .bubbleInfo:
            //let hardware = value[value.count-2].description + "." + value[value.count-1].description
            //let firmware = value[2].description + "." + value[3].description
           //let patchInfo = Data(Double(firmware)! < 1.35 ? value[3...8] : value[5...10])
            battery = Int(value[4])

           print("dabear:: Got bubbledevice: \(metadata)")
           if let writeCharacteristic = writeCharacteristic {
               print("-----set: ", writeCharacteristic)
               peripheral.writeValue(Data([0x02, 0x00, 0x00, 0x00, 0x00, 0x2B]), for: writeCharacteristic, type: .withResponse)
           }
        case .dataPacket://, .decryptedDataPacket:
           rxBuffer.append(value.suffix(from: 4))
           print("dabear:: aggregated datapacket is now of length: \(rxBuffer.count)")
           if rxBuffer.count >= 352 {
               handleCompleteMessage()
               reset()
           }
        case .noSensor:
            delegate?.libreTransmitterReceivedMessage(0x0000, txFlags: 0x34, payloadData: rxBuffer)

            reset()
        case .serialNumber:
            guard value.count >= 10 else { return }
            reset()
            self.uid = [UInt8](value.subdata(in: 2..<10))

            //for historical reasons
            rxBuffer.append(value.subdata(in: 2..<10))

        case .patchInfo:
            guard value.count >= 10 else {
                print("not able to extract patchinfo")
                return
            }
            patchInfo = value.subdata(in: 5 ..< 11).hexEncodedString().uppercased()
        }
    }

    private var rxBuffer = Data()
    private var sensorData: SensorData?
    private var metadata: LibreTransmitterMetadata?

    override func handleCompleteMessage() {
        print("dabear:: bubbleHandleCompleteMessage")

        guard rxBuffer.count >= 352 else {
            return
        }

        metadata = .init(hardware: hardware ?? "unknown", firmware: firmware ?? "unknown", battery: battery ?? 100, name: Self.shortTransmitterName, macAddress: self.mac, patchInfo: patchInfo, uid: self.uid)

        let data = rxBuffer.subdata(in: 8..<352)
        print("dabear:: bubbleHandleCompleteMessage raw data: \([UInt8](rxBuffer))")
        sensorData = SensorData(uuid: rxBuffer.subdata(in: 0..<8), bytes: [UInt8](data), date: Date())

        print("dabear:: bubble got sensordata \(sensorData) and metadata \(metadata), delegate is \(delegate)")

        if let sensorData = sensorData, let metadata = metadata {
            delegate?.libreTransmitterDidUpdate(with: sensorData, and: metadata)
        }
    }
}
