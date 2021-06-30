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
            Text(detail).font(.subheadline)
        }

    }
}

private class GlucoseInfo : ObservableObject{
    @Published var glucose = ""
    @Published var date = ""
    @Published var checksum = ""
    @Published var entryErrors = ""

}

private class SensorInfo : ObservableObject{
    @Published var sensorAge = ""
    @Published var sensorAgeLeft = ""
    @Published var sensorEndTime = ""
    @Published var sensorState = ""
    @Published var sensorSerial = ""

}

private class TransmitterInfo : ObservableObject{
    @Published var battery = ""
    @Published var hardware = ""
    @Published var firmware = ""
    @Published var connectionState = ""
    @Published var transmitterType = ""
    @Published var macAddress = ""
    @Published var sensorType = ""


}


private class FactoryCalibrationInfo : ObservableObject{
    @Published var i1 = ""
    @Published var i2 = ""
    @Published var i3 = ""
    @Published var i4 = ""
    @Published var i5 = ""
    @Published var i6 = ""
    @Published var validForFooter = ""


}

class GenericObservableObject : ObservableObject {
    private var cancellables = Set<AnyCancellable>()


    func notify(){
        objectWillChange.send()
    }

    @discardableResult func listenOnce(listener: @escaping () -> Void) -> Self{
        objectWillChange
        .sink {  [weak self]_ in
            listener()
            self?.cancellables.removeAll()
            
        }
        .store(in: &cancellables)
        return self
    }
}


struct SettingsOverview: View {


    static func asHostedViewController(cgmManager: LibreTransmitterManager, displayGlucoseUnitObservable: DisplayGlucoseUnitObservable, allowsDeletion: Bool, notifyComplete: GenericObservableObject) -> UIHostingController<AnyView> {
        UIHostingController(rootView: AnyView(self.init(cgmManager: cgmManager, displayGlucoseUnitObservable: displayGlucoseUnitObservable, allowsDeletion: allowsDeletion).environmentObject(notifyComplete)))
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

    @StateObject private var glucoseMeasurement = GlucoseInfo()
    @StateObject private var sensorInfo = SensorInfo()
    @StateObject private var transmitterInfo = TransmitterInfo()
    @StateObject private var factoryCalibrationInfo = FactoryCalibrationInfo()


    @EnvironmentObject private var notifyComplete: GenericObservableObject


    func bindableIsDangerModeActivated() -> Binding<Bool> {
        return Binding(
            get: { return UserDefaults.standard.dangerModeActivated },
            set: { newVal in
                UserDefaults.standard.dangerModeActivated = newVal
            })
    }

    // no navigationview necessary when running inside a uihostingcontroller
    // uihostingcontroller seems to add a navigationview for us, causing problems if we
    // also add one herer
    var body: some View {
        //NavigationView {
            overview
                //.navigationViewStyle(StackNavigationViewStyle())
                .navigationBarTitle(Text("Libre Bluetooth"), displayMode: .inline)
                .navigationBarItems(trailing: dismissButton)
        //}

    }



    var snoozeSection: some View {
        Section {
            NavigationLink(destination: SwiftSnoozeView(manager: cgmManager)) {
                Text("Snooze Alerts").frame(alignment: .center)
            }
        }
    }

    var measurementSection : some View {
        Section(header: Text("Last measurement")) {
            SettingsItem(title: "Glucose", detail: glucoseMeasurement.glucose)
            SettingsItem(title: "Date", detail: glucoseMeasurement.date)
            SettingsItem(title: "Sensor Footer checksum", detail: glucoseMeasurement.checksum)
            SettingsItem(title: "Entry Errors", detail: glucoseMeasurement.entryErrors)

        }
    }

    var sensorInfoSection : some View {
        Section(header: Text("Sensor Info")) {
            SettingsItem(title: "Sensor Age", detail: sensorInfo.sensorAge)
            SettingsItem(title: "Sensor Age Left", detail: sensorInfo.sensorAgeLeft)
            SettingsItem(title: "Sensor Endtime", detail: sensorInfo.sensorEndTime)
            SettingsItem(title: "Sensor State", detail: sensorInfo.sensorState)
            SettingsItem(title: "Sensor Serial", detail: sensorInfo.sensorSerial)


        }
    }

    var transmitterInfoSection: some View {
        Section(header: Text("Transmitter Info")) {
            SettingsItem(title: "Battery", detail: transmitterInfo.battery)
            SettingsItem(title: "Hardware", detail: transmitterInfo.hardware)
            SettingsItem(title: "Firmware", detail: transmitterInfo.firmware)
            SettingsItem(title: "Connection State", detail: transmitterInfo.connectionState)
            SettingsItem(title: "Transmitter Type", detail: transmitterInfo.transmitterType)
            SettingsItem(title: "Mac", detail: transmitterInfo.macAddress)
            SettingsItem(title: "Sensor Type", detail: transmitterInfo.sensorType)

        }
    }

    var factoryCalibrationSection: some View {
        Section(header: Text("Factory Calibration Parameters")) {
            SettingsItem(title: "i1", detail: factoryCalibrationInfo.i1)
            SettingsItem(title: "i2", detail: factoryCalibrationInfo.i2)
            SettingsItem(title: "i3", detail: factoryCalibrationInfo.i3)
            SettingsItem(title: "i4", detail: factoryCalibrationInfo.i4)
            SettingsItem(title: "i5", detail: factoryCalibrationInfo.i5)
            SettingsItem(title: "i6", detail: factoryCalibrationInfo.i6)
            SettingsItem(title: "Valid for footer", detail: factoryCalibrationInfo.validForFooter)


            ZStack {
                NavigationLink(destination: CalibrationEditView(cgmManager: cgmManager)) {
                    Button("Edit calibrations") {
                        print("edit calibration clicked")
                    }
                }

            }

        }
    }

    @Environment(\.presentationMode) var presentationMode



    private var dismissButton: some View {
        Button( action: {
            // This should be enough
            //self.presentationMode.wrappedValue.dismiss()

            //but since Loop uses uihostingcontroller wrapped in cgmviewcontroller we need
            // to notify the parent to close the cgmviewcontrollers navigation
            notifyComplete.notify()
        }) {
            Text("Done")
        }
    }



    //todo: replace sub with navigationlinks
    var advancedSection: some View {
        Section(header: Text("Advanced")) {

            ZStack {
                NavigationLink(destination: AlarmSettingsView(glucoseUnit: self.glucoseUnit)) {
                    SettingsItem(title: "Alarms")
                }
            }
            ZStack {
                NavigationLink(destination: GlucoseSettingsView(glucoseUnit: self.glucoseUnit)) {
                    SettingsItem(title: "Glucose Settings")
                }
            }

            ZStack {
                NavigationLink(destination: NotificationSettingsView(glucoseUnit: self.glucoseUnit)) {
                    SettingsItem(title: "Notifications")
                }
            }


            SettingsItem(title: "Danger mode", detail: bindableIsDangerModeActivated().wrappedValue ? "Activated" : "Not Activated")
                .onTapGesture {
                    print("danger mode tapped")
                }

        }
    }

    var overview: some View {
        List {
           
            snoozeSection
            measurementSection
            sensorInfoSection
            transmitterInfoSection
            factoryCalibrationSection
            advancedSection

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
