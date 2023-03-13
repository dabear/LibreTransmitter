//
//  SensorInfo.swift
//  LibreTransmitter
//
//  Created by Bjørn Inge Berg on 02/07/2021.
//  Copyright © 2021 Mark Wilson. All rights reserved.
//

import Foundation
public class SensorInfo: ObservableObject, Equatable, Hashable {
    @Published public var sensorAge = ""
    @Published public var sensorAgeLeft = ""
    @Published public var sensorEndTime = ""
    @Published public var sensorState = ""
    @Published public var sensorSerial = ""
    
    @Published public var sensorMinutesLeft : Int = 0
    @Published public var sensorMinutesSinceStart : Int = 0
    @Published public var sensorMaxMinutesWearTime : Int = 0
    
    @Published public var sensorStartDate : Date = .distantPast
    @Published public var sensorEndDate : Date = .distantPast
    
    public func calculateProgress() -> Double{
        let minutesLeft = Double(self.sensorMinutesLeft)
        let minutesSinceStart = Double(self.sensorMinutesSinceStart)
        let maxWearTime = Double(self.sensorMaxMinutesWearTime)
        
        if minutesLeft <= 0 {
            return 1
        }
        if maxWearTime == 0 {
            //shouldn't really happen, but if it does we don't want to crash because of a minor UI issue
            return 0
        }
        
        return Date.now.getProgress(range: sensorStartDate...sensorEndDate)
    }
    
    
    
    
    
    
    
    public static func == (lhs: SensorInfo, rhs: SensorInfo) -> Bool {
         lhs.sensorAge == rhs.sensorAge && lhs.sensorAgeLeft == rhs.sensorAgeLeft &&
         lhs.sensorEndTime == rhs.sensorEndTime && lhs.sensorState == rhs.sensorState &&
         lhs.sensorSerial == rhs.sensorSerial

     }

}
