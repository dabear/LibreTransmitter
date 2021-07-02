//
//  TransmitterInfo.swift
//  LibreTransmitter
//
//  Created by Bjørn Inge Berg on 02/07/2021.
//  Copyright © 2021 Mark Wilson. All rights reserved.
//

public class TransmitterInfo : ObservableObject, Equatable, Hashable{
    @Published public var battery = ""
    @Published public var hardware = ""
    @Published public var firmware = ""
    @Published public var connectionState = ""
    @Published public var transmitterType = ""
    @Published public var transmitterIdentifier = "" //either mac or apple proprietary identifere
    @Published public var sensorType = ""

    public static func ==(lhs: TransmitterInfo, rhs: TransmitterInfo) -> Bool {
         lhs.battery == rhs.battery && lhs.hardware == rhs.hardware &&
         lhs.firmware == rhs.firmware && lhs.connectionState == rhs.connectionState &&
         lhs.transmitterType == rhs.transmitterType && lhs.transmitterIdentifier == rhs.transmitterIdentifier &&
         lhs.sensorType == rhs.sensorType

     }

    //todo: remove all these utility functions and get this info as an observable
    // from the cgmmanager directly
    static func loadState(cgmManager: LibreTransmitterManager?) -> TransmitterInfo{

        let newState = TransmitterInfo()

        guard let cgmManager = cgmManager else {
            return newState
        }

        newState.battery = cgmManager.batteryString
        newState.hardware = cgmManager.hardwareVersion
        newState.firmware = cgmManager.firmwareVersion
        newState.connectionState = cgmManager.connectionState
        newState.transmitterType = cgmManager.getDeviceType()
        newState.transmitterIdentifier = cgmManager.metaData?.macAddress ??  UserDefaults.standard.preSelectedDevice ?? "Unknown"
        newState.sensorType = cgmManager.metaData?.sensorType()?.description ?? "Unknown"

        return newState
    }

}
