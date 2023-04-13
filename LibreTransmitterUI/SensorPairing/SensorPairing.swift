//
//  SensorPairing.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21.
//
import Foundation
import Combine
import LibreTransmitter


class SensorPairingInfo: ObservableObject, Codable {
    @Published private(set) var uuid: Data
    @Published private(set) var patchInfo: Data
    @Published private(set) var fram: Data
    @Published private(set) var streamingEnabled: Bool
    @Published private(set) var initialIdentificationStrategy: Libre2IdentificationStrategy = .byUid
    
    @Published private(set) var sensorName : String? = nil
    
    enum CodingKeys: CodingKey {
        case uuid, patchInfo, fram, streamingEnabled, initialIdentificationStrategy, sensorName
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(uuid, forKey: .uuid)
        try container.encode(patchInfo, forKey: .patchInfo)
        try container.encode(fram, forKey: .fram)
        try container.encode(streamingEnabled, forKey: .streamingEnabled)
        try container.encode(initialIdentificationStrategy, forKey: .initialIdentificationStrategy)
        try container.encode(sensorName, forKey: .sensorName)

       
    }
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        uuid = try container.decode(Data.self, forKey: .uuid)
        patchInfo = try container.decode(Data.self, forKey: .patchInfo)
        
        fram = try container.decode(Data.self, forKey: .fram)
        streamingEnabled = try container.decode(Bool.self, forKey: .streamingEnabled)
        initialIdentificationStrategy = try container.decode(Libre2IdentificationStrategy.self, forKey: .initialIdentificationStrategy)
        sensorName = try container.decode(String?.self, forKey: .sensorName)


       
    }
    

    public init(uuid: Data=Data(), patchInfo: Data=Data(), fram: Data=Data(), streamingEnabled: Bool = false, initialIdentificationStrategy: Libre2IdentificationStrategy = .byUid, sensorName: String? = nil ) {
        self.uuid = uuid
        self.patchInfo = patchInfo
        self.fram = fram
        self.streamingEnabled = streamingEnabled
        self.initialIdentificationStrategy = initialIdentificationStrategy
        self.sensorName = sensorName
    }

    var sensorData: SensorData? {
        SensorData(bytes: [UInt8](self.fram))
    }

    var calibrationData: SensorData.CalibrationInfo? {
        sensorData?.calibrationData
    }
    
    var description: String {
        let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted

            do {
                let data = try encoder.encode(self)  //convert user to json data here
                return String(data: data, encoding: .utf8)!   //print to console
            } catch {
                return "SensorPairingInfoError"
            }
    }

}

protocol SensorPairingProtocol {
    func pairSensor() -> AnyPublisher<SensorPairingInfo, Never>
}
