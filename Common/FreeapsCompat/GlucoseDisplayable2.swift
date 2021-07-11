//
//  GlucoseDisplayable2.swift
//  LibreTransmitter
//
//  Created by Bjørn Inge Berg on 11/07/2021.
//  Copyright © 2021 Mark Wilson. All rights reserved.
//

import Foundation
#if !canImport(LoopKit) && !canImport(LoopKitUI)


import HealthKit

public protocol GlucoseDisplayable {}

public protocol GlucoseRangeCategory{}



public class DisplayGlucoseUnitObservable: ObservableObject {
    @Published public private(set) var displayGlucoseUnit: HKUnit

    public init(displayGlucoseUnit: HKUnit) {
        self.displayGlucoseUnit = displayGlucoseUnit
    }
}

extension DisplayGlucoseUnitObservable {
    public func displayGlucoseUnitDidChange(to displayGlucoseUnit: HKUnit) {
        self.displayGlucoseUnit = displayGlucoseUnit
    }
}


extension HKUnit {

    public static let internationalUnitsPerHour: HKUnit = {
        return HKUnit.internationalUnit().unitDivided(by: .hour())
    }()
    var foundationUnit: Unit? {
        if self == HKUnit.milligramsPerDeciliter {
            return UnitConcentrationMass.milligramsPerDeciliter
        }

        if self == HKUnit.millimolesPerLiter {
            return UnitConcentrationMass.millimolesPerLiter(withGramsPerMole: HKUnitMolarMassBloodGlucose)
        }

        if self == HKUnit.gram() {
            return UnitMass.grams
        }

        return nil
    }
}

#endif
