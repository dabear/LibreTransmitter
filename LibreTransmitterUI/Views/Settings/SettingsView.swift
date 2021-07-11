//
//  SettingsOverview.swift
//  LibreTransmitterUI
//
//  Created by Bjørn Inge Berg on 12/06/2021.
//  Copyright © 2021 Mark Wilson. All rights reserved.
//

import SwiftUI

import LibreTransmitter
import HealthKit
import LoopKit
import LoopKitUI


private struct SettingsItem: View {
    @State var title: String = "" // we don't want this to change after it is set
    @Binding var detail: String

    init(title: String, detail: Binding<String>) {
        self.title = title
        self._detail = detail
    }

    //basically allows caller to set a static string without having to use .constant
    init(title: String, detail: String) {
        self.title = title
        self._detail = Binding<String>(get: {
            detail
        }, set: { newVal in
            //pass
        })
    }

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(detail).font(.subheadline)
        }

    }
}


private class FactoryCalibrationInfo : ObservableObject, Equatable, Hashable{
    @Published var i1 = ""
    @Published var i2 = ""
    @Published var i3 = ""
    @Published var i4 = ""
    @Published var i5 = ""
    @Published var i6 = ""
    @Published var validForFooter = ""


    // For swiftuis stateobject to be able to compare two objects for equality,
    // we must exclude the publishers them selves in the comparison

   static func ==(lhs: FactoryCalibrationInfo, rhs: FactoryCalibrationInfo) -> Bool {
        lhs.i1 == rhs.i1 && lhs.i2 == rhs.i2 &&
        lhs.i3 == rhs.i3 && lhs.i4 == rhs.i4 &&
        lhs.i5 == rhs.i5 && lhs.i6 == rhs.i6 &&
        lhs.validForFooter == rhs.validForFooter

    }

    static private var keychain = KeychainManager()
    //todo: consider using cgmmanagers observable directly
    static func loadState() -> FactoryCalibrationInfo{

        let newState = FactoryCalibrationInfo()

        // User editable calibrationdata: keychain.getLibreNativeCalibrationData()
        // Default Calibrationdata stored in sensor: cgmManager?.calibrationData

        //do not change this, there is UI support for editing calibrationdata anyway
        guard let c = self.keychain.getLibreNativeCalibrationData() else {
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



class SettingsModel : ObservableObject {
    @Published  fileprivate var factoryCalibrationInfos = [FactoryCalibrationInfo()]

}


struct SettingsView: View {

    @ObservedObject private var displayGlucoseUnitObservable: DisplayGlucoseUnitObservable
    @ObservedObject private var transmitterInfo: LibreTransmitter.TransmitterInfo
    @ObservedObject private var sensorInfo: LibreTransmitter.SensorInfo

    @ObservedObject private var glucoseMeasurement: LibreTransmitter.GlucoseInfo


    @ObservedObject private var notifyComplete: GenericObservableObject
    @ObservedObject private var notifyDelete: GenericObservableObject

    //most of the settings are now retrieved from the cgmmanager observables instead
    @StateObject var model = SettingsModel()
    @State private var presentableStatus: StatusMessage?
    @ObservedObject var alarmStatus: LibreTransmitter.AlarmStatus




    

    static func asHostedViewController(
        displayGlucoseUnitObservable: DisplayGlucoseUnitObservable,
        notifyComplete: GenericObservableObject,
        notifyDelete: GenericObservableObject,
        transmitterInfoObservable:LibreTransmitter.TransmitterInfo,
        sensorInfoObervable: LibreTransmitter.SensorInfo,
        glucoseInfoObservable: LibreTransmitter.GlucoseInfo,
        alarmStatus: LibreTransmitter.AlarmStatus) -> UIHostingController<SettingsView> {
        UIHostingController(rootView: self.init(
            displayGlucoseUnitObservable: displayGlucoseUnitObservable, transmitterInfo: transmitterInfoObservable, sensorInfo: sensorInfoObervable, glucoseMeasurement: glucoseInfoObservable, notifyComplete: notifyComplete, notifyDelete: notifyDelete, alarmStatus: alarmStatus

        ))
    }


    @State private var showingDestructQuestion = false

    private var glucoseUnit: HKUnit {
        displayGlucoseUnitObservable.displayGlucoseUnit
    }


    static let formatter = NumberFormatter()

    var dangerModeActivated : Binding<String> = ({
        Binding(
            get: { UserDefaults.standard.dangerModeActivated ? "Activated" : "Not activated" },
            set: { newVal in
                //UserDefaults.standard.dangerModeActivated = newVal
                //we dont support setting it currently
            })
    }

    )()


    // no navigationview necessary when running inside a uihostingcontroller
    // uihostingcontroller seems to add a navigationview for us, causing problems if we
    // also add one herer
    var body: some View {

        overview
            //.navigationViewStyle(StackNavigationViewStyle())
            .navigationBarTitle(Text("Libre Bluetooth"), displayMode: .inline)
            .navigationBarItems(trailing: dismissButton)
            .onAppear{
                print("dabear:: settingsview appeared")

                //only override savedglucose unit if we haven't saved this locally before
                if UserDefaults.standard.mmGlucoseUnit == nil {
                    UserDefaults.standard.mmGlucoseUnit = glucoseUnit
                }
                // Yes we load factory calibrationdata every time the view appears
                // I know this is  bad, but the calibrationdata is stored in
                // the keychain and there is no simple way of wrapping the keychain
                // as an observable in swiftui without bringing in large third party
                // dependencies or hand crafting it, which would be error prone


                let newFactoryInfo = FactoryCalibrationInfo.loadState()

                if newFactoryInfo != self.model.factoryCalibrationInfos.first{
                    print("dabear:: factoryinfo was new")

                    self.model.factoryCalibrationInfos.removeAll()
                    self.model.factoryCalibrationInfos.append(newFactoryInfo)

                }

            }
            .onReceive(glucoseMeasurement.objectWillChange) {
                print("dabear:: swiftui detected glucosemeasurement change")
            }

    }



    var snoozeSection: some View {
        Section {
            NavigationLink(destination: SnoozeView(isAlarming: $alarmStatus.isAlarming, activeAlarms: $alarmStatus.glucoseScheduleAlarmResult)) {
                if alarmStatus.isAlarming {
                    Text("Snooze Alerts").frame(alignment: .center)
                        .padding(.top, 30)
                        .padding(.bottom, 30)
                } else {
                    Text("Snooze Alerts").frame(alignment: .center)
                }
            }
        }
    }



    var measurementSection : some View {
        Section(header: Text("Last measurement")) {
                SettingsItem(title: "Glucose", detail: $glucoseMeasurement.glucose )
                SettingsItem(title: "Date", detail: $glucoseMeasurement.date )
                SettingsItem(title: "Sensor Footer checksum", detail: $glucoseMeasurement.checksum )
        }
    }

    var sensorInfoSection : some View {
        Section(header: Text("Sensor Info")) {
            SettingsItem(title: "Sensor Age", detail: $sensorInfo.sensorAge )
                SettingsItem(title: "Sensor Age Left", detail: $sensorInfo.sensorAgeLeft )
                SettingsItem(title: "Sensor Endtime", detail: $sensorInfo.sensorEndTime )
                SettingsItem(title: "Sensor State", detail: $sensorInfo.sensorState )
                SettingsItem(title: "Sensor Serial", detail: $sensorInfo.sensorSerial )
        }
    }


    var transmitterInfoSection: some View {

        Section(header: Text("Transmitter Info")) {
            SettingsItem(title: "Battery", detail: $transmitterInfo.battery )
            SettingsItem(title: "Hardware", detail: $transmitterInfo.hardware )
            SettingsItem(title: "Firmware", detail: $transmitterInfo.firmware )
            SettingsItem(title: "Connection State", detail: $transmitterInfo.connectionState )
            SettingsItem(title: "Transmitter Type", detail: $transmitterInfo.transmitterType )
            SettingsItem(title: "Mac", detail: $transmitterInfo.transmitterIdentifier )
            SettingsItem(title: "Sensor Type", detail: $transmitterInfo.sensorType )
        }
    }

    var factoryCalibrationSection: some View {
        Section(header: Text("Factory Calibration Parameters")) {
            ForEach(self.model.factoryCalibrationInfos, id: \.self) { factoryCalibrationInfo in

                SettingsItem(title: "i1", detail: factoryCalibrationInfo.i1 )
                SettingsItem(title: "i2", detail: factoryCalibrationInfo.i2 )
                SettingsItem(title: "i3", detail: factoryCalibrationInfo.i3 )
                SettingsItem(title: "i4", detail: factoryCalibrationInfo.i4 )
                SettingsItem(title: "i5", detail: factoryCalibrationInfo.i5 )
                SettingsItem(title: "i6", detail: factoryCalibrationInfo.i6 )
                SettingsItem(title: "Valid for footer", detail: factoryCalibrationInfo.validForFooter )
            }


            ZStack {
                NavigationLink(destination: CalibrationEditView()) {
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


    var destructSection: some View {
        Section {
            Button("Delete CGM") {
                        showingDestructQuestion = true
            }.foregroundColor(.red)
            .alert(isPresented: $showingDestructQuestion) {
                Alert(
                    title: Text("Are you sure you want to remove this cgm from loop?"),
                    message: Text("There is no undo"),
                    primaryButton: .destructive(Text("Delete")) {

                        notifyDelete.notify()
                    },
                    secondaryButton: .cancel()
                )
            }

        }
    }

    //todo: replace sub with navigationlinks
    var advancedSection: some View {
        Section(header: Text("Advanced")) {
            //these subviews don't really need to be notified once glucose unit changes
            // so we just pass glucoseunit directly on init
            ZStack {
                NavigationLink(destination: AlarmSettingsView(glucoseUnit: self.glucoseUnit)) {
                    SettingsItem(title: "Alarms", detail: .constant(""))
                }
            }
            ZStack {
                NavigationLink(destination: GlucoseSettingsView(glucoseUnit: self.glucoseUnit)) {
                    SettingsItem(title: "Glucose Settings", detail: .constant(""))
                }
            }

            ZStack {
                NavigationLink(destination: NotificationSettingsView(glucoseUnit: self.glucoseUnit)) {
                    SettingsItem(title: "Notifications", detail: .constant(""))
                }
            }


            // Decided against adding ui for activating danger mode this time
            // Consider doing it in the future, but no rush. dangermode is only used for calibrationedit and bluetooth devices debugging.


            SettingsItem(title: "Danger mode", detail: dangerModeActivated)
                .onTapGesture {
                    print("danger mode tapped")
                    presentableStatus = StatusMessage(title: "Danger mode", message: "Danger mode was a legacy ui only feature")
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
            destructSection

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
