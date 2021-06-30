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

private class GlucoseInfo : ObservableObject, Equatable{
    @Published var glucose = ""
    @Published var date = ""
    @Published var checksum = ""
    //@Published var entryErrors = ""


    //todo: remove all these utility functions and get this info as an observable
    // from the cgmmanager directly
    static func loadState(cgmManager: LibreTransmitterManager?, unit: HKUnit) -> GlucoseInfo{

        let newState = GlucoseInfo()

        guard let cgmManager = cgmManager, let d = cgmManager.latestBackfill else {
            return newState
        }


        // We know we need this every time,
        // so no point in lazying it as was done in uikit version

        let formatter = QuantityFormatter()
        formatter.setPreferredNumberFormatter(for: unit)

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .long
        dateFormatter.doesRelativeDateFormatting = true

        newState.glucose = formatter.string(from: d.quantity, for: unit) ?? "-"
        newState.date = dateFormatter.string(from: d.timestamp)
        newState.checksum = cgmManager.sensorFooterChecksums


        return newState
    }



}

private class SensorInfo : ObservableObject, Equatable{
    @Published var sensorAge = ""
    @Published var sensorAgeLeft = ""
    @Published var sensorEndTime = ""
    @Published var sensorState = ""
    @Published var sensorSerial = ""

    //todo: remove all these utility functions and get this info as an observable
    // from the cgmmanager directly
    static func loadState(cgmManager: LibreTransmitterManager?) -> SensorInfo{

        let newState = SensorInfo()

        guard let cgmManager = cgmManager else {
            return newState
        }

        newState.sensorAge = cgmManager.sensorAge
        newState.sensorAgeLeft = cgmManager.sensorTimeLeft
        newState.sensorEndTime = cgmManager.sensorEndTime
        newState.sensorState = cgmManager.sensorStateDescription
        newState.sensorSerial = cgmManager.sensorSerialNumber

        return newState
    }

}

private class TransmitterInfo : ObservableObject, Equatable{
    @Published var battery = ""
    @Published var hardware = ""
    @Published var firmware = ""
    @Published var connectionState = ""
    @Published var transmitterType = ""
    @Published var transmitterIdentifier = "" //either mac or apple proprietary identifere
    @Published var sensorType = ""

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


private class FactoryCalibrationInfo : ObservableObject, Equatable{
    @Published var i1 = ""
    @Published var i2 = ""
    @Published var i3 = ""
    @Published var i4 = ""
    @Published var i5 = ""
    @Published var i6 = ""
    @Published var validForFooter = ""

    //todo: consider using cgmmanagers observable directly
    static func loadState(cgmManager: LibreTransmitterManager?) -> FactoryCalibrationInfo{

        let newState = FactoryCalibrationInfo()

        // User editable calibrationdata: cgmManager?.keychain.getLibreNativeCalibrationData()
        // Calibrationdata stored in sensor: cgmManager?.calibrationData

        //do not change this, there is UI support for editing calibrationdata anyway
        guard let c = cgmManager?.keychain.getLibreNativeCalibrationData() else {
            return newState
        }



        newState.i1 = String(c.i1)
        newState.i2 = String(c.i2)
        newState.i3 = String(c.i3)
        newState.i4 = String(c.i4)
        newState.i5 = String(c.i5)
        newState.i6 = String(c.i6)
        newState.validForFooter = String(c.isValidForFooterWithReverseCRCs)

        return newState
    }


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
        UIHostingController(rootView: AnyView(self.init(cgmManager: cgmManager, allowsDeletion: allowsDeletion)
                                                .environmentObject(notifyComplete)
                                                .environmentObject(displayGlucoseUnitObservable)))
    }

    @State private var presentableStatus: StatusMessage?


    @EnvironmentObject private var displayGlucoseUnitObservable: DisplayGlucoseUnitObservable



    private var glucoseUnit: HKUnit {
        displayGlucoseUnitObservable.displayGlucoseUnit
    }

    public let allowsDeletion: Bool
    public var cgmManager: LibreTransmitterManager?

    public init(cgmManager: LibreTransmitterManager, allowsDeletion: Bool) {
        self.cgmManager = cgmManager
        self.allowsDeletion = allowsDeletion

        //only override savedglucose unit if we haven't saved this locally before
        if UserDefaults.standard.mmGlucoseUnit == nil {
            UserDefaults.standard.mmGlucoseUnit = glucoseUnit
        }


    }


    static let formatter = NumberFormatter()


    //Yes, these *must be state and not stateobjects as implemented currently

    @State private var glucoseMeasurement = GlucoseInfo()
    @State private var sensorInfo = SensorInfo()
    @State private var transmitterInfo = TransmitterInfo()
    @State private var factoryCalibrationInfo = FactoryCalibrationInfo()


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
                .onAppear{
                    //yes we load newstate each time settings appear. See previous todo
                    let newTransmitterInfo = TransmitterInfo.loadState(cgmManager: self.cgmManager)
                    if newTransmitterInfo != self.transmitterInfo {
                        self.transmitterInfo = newTransmitterInfo
                    }

                    let newSensorInfo = SensorInfo.loadState(cgmManager: self.cgmManager)

                    if newSensorInfo != self.sensorInfo {
                        self.sensorInfo = newSensorInfo
                    }

                    let newFactoryInfo = FactoryCalibrationInfo.loadState(cgmManager: self.cgmManager)

                    if newFactoryInfo != self.factoryCalibrationInfo {
                        self.factoryCalibrationInfo = newFactoryInfo
                    }

                    let newGlucoseInfo = GlucoseInfo.loadState(cgmManager: self.cgmManager, unit: glucoseUnit)

                    if newGlucoseInfo != self.glucoseMeasurement {
                        self.glucoseMeasurement = newGlucoseInfo
                    }


                }

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
            //SettingsItem(title: "Entry Errors", detail: glucoseMeasurement.entryErrors)

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
            SettingsItem(title: "Mac", detail: transmitterInfo.transmitterIdentifier)
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
            //these subviews don't really need to be notified once glucose unit changes
            // so we just pass glucoseunit directly on init
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


            // Decided against adding ui for activating danger mode this time
            // Consider doing it in the future, but no rush. dangermode is only used for calibrationedit and bluetooth devices debugging. 
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
        NotificationSettingsView(glucoseUnit: HKUnit.millimolesPerLiter)
    }
}
