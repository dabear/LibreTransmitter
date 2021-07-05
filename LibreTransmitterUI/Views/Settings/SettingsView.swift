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

class SettingsModel : ObservableObject {
    @Published  fileprivate var factoryCalibrationInfos = [FactoryCalibrationInfo()]

}


struct SettingsView: View {

    @EnvironmentObject private var displayGlucoseUnitObservable: DisplayGlucoseUnitObservable
    @EnvironmentObject private var transmitterInfo: LibreTransmitter.TransmitterInfo
    @EnvironmentObject private var sensorInfo: LibreTransmitter.SensorInfo
    //@EnvironmentObject private var glucoseMeasurement: LibreTransmitter.GlucoseInfo
    @ObservedObject private var glucoseMeasurement: LibreTransmitter.GlucoseInfo


    @EnvironmentObject private var notifyComplete: GenericObservableObject

    //most of the settings are now retrieved from the cgmmanager observables instead
    @StateObject var model = SettingsModel()
    @State private var presentableStatus: StatusMessage?



    public var cgmManager: LibreTransmitterManager?

    

    static func asHostedViewController(cgmManager: LibreTransmitterManager, displayGlucoseUnitObservable: DisplayGlucoseUnitObservable, notifyComplete: GenericObservableObject, transmitterInfoObservable: LibreTransmitter.TransmitterInfo, sensorInfoObervable: LibreTransmitter.SensorInfo, glucoseInfoObservable: LibreTransmitter.GlucoseInfo) -> UIHostingController<AnyView> {
        UIHostingController(rootView: AnyView(self.init(glucoseMeasurement: glucoseInfoObservable, cgmManager: cgmManager)
                                                .environmentObject(notifyComplete)
                                                .environmentObject(displayGlucoseUnitObservable)
                                                .environmentObject(transmitterInfoObservable)
                                                .environmentObject(sensorInfoObervable)
                                                //.environmentObject(glucoseInfoObservable)
        ))
    }


    @State private var showingDestructQuestion = false

    private var glucoseUnit: HKUnit {
        displayGlucoseUnitObservable.displayGlucoseUnit
    }


    static let formatter = NumberFormatter()

    var dangerModeActivated : Binding<Bool> = ({
        Binding(
            get: { UserDefaults.standard.dangerModeActivated },
            set: { newVal in
                UserDefaults.standard.dangerModeActivated = newVal
            })
    }

    )()


    var hasActiveAlarm: Bool {
        var res = false
        if let glucoseDouble = cgmManager?.latestBackfill?.glucoseDouble, let activeAlarms = UserDefaults.standard.glucoseSchedules?.getActiveAlarms(glucoseDouble) {
            res = [.high,.low].contains(activeAlarms)
        }

        return res
    }


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
                // Yes we load factory calibrationdata every time the view appears
                // I know this is  bad, but the calibrationdata is stored in
                // the keychain and there is no simple way of wrapping the keychain
                // as an observable in swiftui without bringing in large third party
                // dependencies or hand crafting it, which would be error prone


                let newFactoryInfo = FactoryCalibrationInfo.loadState(cgmManager: self.cgmManager)

                if newFactoryInfo != self.model.factoryCalibrationInfos.first{
                    print("dabear:: factoryinfo was new")

                    self.model.factoryCalibrationInfos.removeAll()
                    self.model.factoryCalibrationInfos.append(newFactoryInfo)

                }

            }
            .onAppear{

                //only override savedglucose unit if we haven't saved this locally before
                if UserDefaults.standard.mmGlucoseUnit == nil {
                    UserDefaults.standard.mmGlucoseUnit = glucoseUnit
                }
            }
            .onChange(of: glucoseMeasurement) { newVal in
                print("dabear:: swiftui detected glucosemeasurement change")
            }

    }



    var snoozeSection: some View {
        Section {
            NavigationLink(destination: SnoozeView(manager: cgmManager)) {
                if hasActiveAlarm {
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
                SettingsItem(title: "Glucose", detail: glucoseMeasurement.glucose )
                SettingsItem(title: "Date", detail: glucoseMeasurement.date )
                SettingsItem(title: "Sensor Footer checksum", detail: glucoseMeasurement.checksum )
        }
    }

    var sensorInfoSection : some View {
        Section(header: Text("Sensor Info")) {
            SettingsItem(title: "Sensor Age", detail: sensorInfo.sensorAge )
                SettingsItem(title: "Sensor Age Left", detail: sensorInfo.sensorAgeLeft )
                SettingsItem(title: "Sensor Endtime", detail: sensorInfo.sensorEndTime )
                SettingsItem(title: "Sensor State", detail: sensorInfo.sensorState )
                SettingsItem(title: "Sensor Serial", detail: sensorInfo.sensorSerial )
        }
    }


    var transmitterInfoSection: some View {

        Section(header: Text("Transmitter Info")) {
            SettingsItem(title: "Battery", detail: transmitterInfo.battery )
            SettingsItem(title: "Hardware", detail: transmitterInfo.hardware )
            SettingsItem(title: "Firmware", detail: transmitterInfo.firmware )
            SettingsItem(title: "Connection State", detail: transmitterInfo.connectionState )
            SettingsItem(title: "Transmitter Type", detail: transmitterInfo.transmitterType )
            SettingsItem(title: "Mac", detail: transmitterInfo.transmitterIdentifier )
            SettingsItem(title: "Sensor Type", detail: transmitterInfo.sensorType )
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
                        print("Deleting...")
                        if let cgmManager = self.cgmManager {
                            cgmManager.disconnect()
                            cgmManager.notifyDelegateOfDeletion {
                                DispatchQueue.main.async {
                                    self.notifyComplete.notify()
                                }
                            }
                        }
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


            SettingsItem(title: "Danger mode", detail: dangerModeActivated.wrappedValue ? "Activated" : "Not Activated")
                .onTapGesture {
                    print("danger mode tapped")
                    presentableStatus = StatusMessage(title: "Danger mode", message: "Danger was a legacy ui only feature")
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
