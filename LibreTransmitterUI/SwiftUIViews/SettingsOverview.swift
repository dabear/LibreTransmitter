//
//  SettingsOverview.swift
//  LibreTransmitterUI
//
//  Created by Bjørn Inge Berg on 12/06/2021.
//  Copyright © 2021 Mark Wilson. All rights reserved.
//

import SwiftUI
import Combine
import LibreTransmitter
import HealthKit
import LoopKit
import LoopKitUI


private struct SettingsItem: View {
    @State var title: String = ""
    @State var detail: String = ""

    var body: some View {
        HStack {
                Text(title)
                Spacer()
                Text(detail)
        }

    }
}


private struct SnoozeOverview: View {
    var body: some View {
        HStack {
            Text("Snooze overview")
        }

    }
}

private struct LastMeasurementOverview: View {
    var body: some View {
        HStack {
            Text("Last measurement overview")
            
        }

    }
}

private struct TransmitterOverview: View {
    var body: some View {
        HStack {
            Text("Transmitter overview")
        }

    }
}

private struct FactoryCalibrationOverview: View {
    var body: some View {
        HStack {
            Text("Factory calibration overview")
        }

    }
}

private struct AdvancedSettingsOverview: View {
    var body: some View {
        HStack {
            Text("Factory calibration overview")
        }

    }
}


struct SettingsOverview: View {


    static func asHostedViewController(cgmManager: LibreTransmitterManager, displayGlucoseUnitObservable: DisplayGlucoseUnitObservable, allowsDeletion: Bool) -> UIHostingController<Self> {
        UIHostingController(rootView: self.init(cgmManager: cgmManager, displayGlucoseUnitObservable: displayGlucoseUnitObservable, allowsDeletion: allowsDeletion))
    }

    @State private var presentableStatus: StatusMessage?


    private let displayGlucoseUnitObservable: DisplayGlucoseUnitObservable
    private lazy var cancellables = Set<AnyCancellable>()

    private var glucoseUnit: HKUnit {
        displayGlucoseUnitObservable.displayGlucoseUnit
    }

    public let allowsDeletion: Bool
    public var cgmManager: LibreTransmitterManager?

    public init(cgmManager: LibreTransmitterManager, displayGlucoseUnitObservable: DisplayGlucoseUnitObservable, allowsDeletion: Bool) {
        self.cgmManager = cgmManager
        self.displayGlucoseUnitObservable = displayGlucoseUnitObservable
        self.allowsDeletion = allowsDeletion

        //only override savedglucose unit if we haven't saved this locally before
        if UserDefaults.standard.mmGlucoseUnit == nil {
            UserDefaults.standard.mmGlucoseUnit = glucoseUnit
        }


    }


    static let formatter = NumberFormatter()

    var body: some View {
        NavigationView {
            overview
        }
    }

    var headerSection: some View {
        Section {
            HStack {
                Image(systemName: "pencil.circle")
                Text("Settings")
            }
        }
    }

    var overview: some View {
        List {
            headerSection
            
            Section {
                SnoozeOverview()
            }
            Section(header: Text("Last measurement")) {
                LastMeasurementOverview()

            }

            Section(header: Text("Transmitter info")) {
                TransmitterOverview()
            }

            Section(header: Text("Factory calibration")){
                FactoryCalibrationOverview()
            }

            Section(header: Text("Advanced")){
                AdvancedSettingsOverview()
            }


        }
        .listStyle(InsetGroupedListStyle())
        .alert(item: $presentableStatus) { status in
            Alert(title: Text(status.title), message: Text(status.message) , dismissButton: .default(Text("Got it!")))
        }


    }




}


struct SettingsOverview_Previews: PreviewProvider {
    static var previews: some View {
        NotificationSettingsView(glucoseUnit: HKUnit.millimolesPerLiter, disappearDelegate:nil)
    }
}
