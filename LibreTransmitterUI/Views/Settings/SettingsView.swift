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
import UniformTypeIdentifiers

public struct SettingsItem: View {
    @State var title: String = "" // we don't want this to change after it is set
    @Binding var detail: String

    init(title: String, detail: Binding<String>) {
        self.title = title
        self._detail = detail
    }

    // basically allows caller to set a static string without having to use .constant
    init(title: String, detail: String="") {
        self.title = title
        self._detail = Binding<String>(get: {
            detail
        }, set: { _ in
            // pass
        })
    }

    public var body: some View {
        HStack {
            Text(title)
            if !detail.isEmpty {
                Spacer()
                Text(detail).font(.subheadline)
            }
            
        }

    }
}

struct SettingsView: View {

    @ObservedObject private var displayGlucoseUnitObservable: DisplayGlucoseUnitObservable
    @ObservedObject private var transmitterInfo: LibreTransmitter.TransmitterInfo
    @ObservedObject private var sensorInfo: LibreTransmitter.SensorInfo

    @ObservedObject private var glucoseMeasurement: LibreTransmitter.GlucoseInfo

    @ObservedObject private var notifyComplete: GenericObservableObject
    @ObservedObject private var notifyDelete: GenericObservableObject
    @ObservedObject private var notifyReset: GenericObservableObject
    @ObservedObject private var notifyReconnect: GenericObservableObject

   
    @State private var presentableStatus: StatusMessage?
    @ObservedObject var alarmStatus: LibreTransmitter.AlarmStatus

    @State private var showingDestructQuestion = false
    //@State private var showingExporter = false
    // @Environment(\.presentationMode) var presentationMode

    static func asHostedViewController(
        displayGlucoseUnitObservable: DisplayGlucoseUnitObservable,
        notifyComplete: GenericObservableObject,
        notifyDelete: GenericObservableObject,
        notifyReset: GenericObservableObject,
        notifyReconnect: GenericObservableObject,
        transmitterInfoObservable: LibreTransmitter.TransmitterInfo,
        sensorInfoObervable: LibreTransmitter.SensorInfo,
        glucoseInfoObservable: LibreTransmitter.GlucoseInfo,
        alarmStatus: LibreTransmitter.AlarmStatus) -> DismissibleHostingController {
            DismissibleHostingController(rootView: self.init(
            displayGlucoseUnitObservable: displayGlucoseUnitObservable,
            transmitterInfo: transmitterInfoObservable,
            sensorInfo: sensorInfoObervable,
            glucoseMeasurement: glucoseInfoObservable,
            notifyComplete: notifyComplete,
            notifyDelete: notifyDelete,
            notifyReset: notifyReset,
            notifyReconnect: notifyReconnect,
            alarmStatus: alarmStatus

        ))
    }

    private var glucoseUnit: HKUnit {
        displayGlucoseUnitObservable.displayGlucoseUnit
    }

    static let formatter = NumberFormatter()

    // no navigationview necessary when running inside a uihostingcontroller
    // uihostingcontroller seems to add a navigationview for us, causing problems if we
    // also add one herer
    var body: some View {
            List {
                headerSection
                snoozeSection
                measurementSection
                if !glucoseMeasurement.predictionDate.isEmpty {
                    predictionSection
                }
                
                NavigationLink(destination: deviceInfoSection) {
                    SettingsItem(title: "Device details")
                }
                
                NavigationLink(destination: CalibrationEditView()) {
                    Button(Features.allowsEditingFactoryCalibrationData ? "Edit calibrations" : "View factory calibrations") {
                        print("edit calibration clicked")
                    }
                }
                advancedSection
                sensorChangeSection
                destructSection
                    
                
            }.listStyle(InsetGroupedListStyle())
            .onAppear {
                // only override savedglucose unit if we haven't saved this locally before
                if UserDefaults.standard.mmGlucoseUnit == nil {
                    UserDefaults.standard.mmGlucoseUnit = glucoseUnit
                }
                
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    doneButton
                }
            }
            //.navigationBarTitle("Libre bluetooth", displayMode: .large)
            .navigationTitle("Libre bluetooth")
    }
        

    var snoozeSection: some View {
        Section {
            NavigationLink(destination: SnoozeView(isAlarming: $alarmStatus.isAlarming, activeAlarms: $alarmStatus.glucoseScheduleAlarmResult)) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.blue)
                Text(LocalizedString("Pause Glucose alarms", comment: "Text for pausing glucose alarms")).frame(alignment: .center)
                    .foregroundColor(.blue)
                
            }
        }
    }

    var measurementSection : some View {
        Section(header: Text(LocalizedString("Last measurement", comment: "Text describing header for last measurement section"))) {
            if glucoseUnit == .millimolesPerLiter {
                    SettingsItem(title: "Glucose", detail: $glucoseMeasurement.glucoseMMOL)
            } else if glucoseUnit == .milligramsPerDeciliter {
                    SettingsItem(title: "Glucose", detail: $glucoseMeasurement.glucoseMGDL)
            }

            SettingsItem(title: "Date", detail: $glucoseMeasurement.date )
            SettingsItem(title: "Sensor Footer checksum", detail: $glucoseMeasurement.checksum )
        }
    }

    var predictionSection : some View {
        Section(header: Text(LocalizedString("Last Blood Sugar prediction", comment: "Text describing header for Blood Sugar prediction section"))) {
            if glucoseUnit == .millimolesPerLiter {
                    SettingsItem(title: "CurrentBG", detail: $glucoseMeasurement.predictionMMOL)
            } else if glucoseUnit == .milligramsPerDeciliter {
                    SettingsItem(title: "CurrentBG", detail: $glucoseMeasurement.predictionMGDL)
            }

            SettingsItem(title: "Date", detail: $glucoseMeasurement.predictionDate )

        }
    }
    
    

    var deviceInfoSection: some View {
        List {
            Section(header: Text(LocalizedString("Device Info", comment: "Text describing header for device info section"))) {
                if !transmitterInfo.battery.isEmpty {
                    SettingsItem(title: "Battery", detail: $transmitterInfo.battery )
                }
                
                // The firmware version is not always extractable for all devices
                // and the libre2 direct version does not support it at all
                if !transmitterInfo.hardware.isEmpty {
                    SettingsItem(title: "Hardware", detail: $transmitterInfo.hardware )
                }
                // The firmware version is not always extractable for all devices
                // and the libre2 direct version does not support it at all
                if !transmitterInfo.firmware.isEmpty {
                    SettingsItem(title: "Firmware", detail: $transmitterInfo.firmware )
                }
                
                
                SettingsItem(title: "Connection State", detail: $transmitterInfo.connectionState )
                SettingsItem(title: "Transmitter Type", detail: $transmitterInfo.transmitterType )
                
                
                // The mac address of a given device is normally not available on ios
                // Only the bluetooth identifier, which is a normalized derivative of the mac address is available
                // However, some transmitters, such as the bubble, provide their own mac address as part of its advertisement info
                // which we extract and put herer
                if !transmitterInfo.transmitterMacAddress.isEmpty {
                    SettingsItem(title: "Mac", detail: $transmitterInfo.transmitterMacAddress )
                }
                
                
                
                SettingsItem(title: "Sensor Type", detail: $transmitterInfo.sensorType )
                
                SettingsItem(title: "Sensor Start", detail: sensorInfo.activatedAtString )
                SettingsItem(title: "Sensor End", detail: sensorInfo.expiresAtString )
            }
        }
        .textSelection(.enabled)
    }

    private var doneButton: some View {
        Button("Done", action: {
            notifyComplete.notify()
        })
    }
    
    var sensorChangeSection: some View {
        Section {
            ZStack {
                NavigationLink(destination: AuthView(completeNotifier: notifyComplete, notifyReset: notifyReset, notifyReconnect: notifyReconnect)) {
                    Button("Change Sensor") {
                    }.foregroundColor(.blue)
                }
            }
        }
    }


    var destructSection: some View {
        Section {
            Button("Delete CGM") {
                showingDestructQuestion = true
            }.foregroundColor(.red)
            .alert(isPresented: $showingDestructQuestion) {
                Alert(
                    title: Text(LocalizedString("Are you sure you want to remove this cgm from loop?", comment: "Text describing question to remove the cgmmanager from loop")),
                    message: Text(LocalizedString("There is no undo. Deleting requires authentication!", comment: "Text warning user there is no undo for deleting cgmmanager")),
                    primaryButton: .destructive(Text(LocalizedString("Delete", comment: "Action text for deleting cgmmanager"))) {
                        
                        self.authenticate { success in
                            print("dabear: got authentication response: \(success)")
                            if success {
                                notifyDelete.notify()
                            }
                        }
                        
                    },
                    secondaryButton: .cancel()
                )
            }

        }
    }


    var advancedSection: some View {
        Section(header: Text(LocalizedString("Advanced", comment: "Text describing header for advanced settings section"))) {
            // these subviews don't really need to be notified once glucose unit changes
            // so we just pass glucoseunit directly on init
            ZStack {
                NavigationLink(destination: AlarmSettingsView(glucoseUnit: self.glucoseUnit)) {
                    SettingsItem(title: "Alarms")
                }
            }
            if NotificationHelper.criticalAlarmsEnabled {
                ZStack {
                    NavigationLink(destination: CriticalAlarmsVolumeView()) {
                        SettingsItem(title: "Critical Alarms volume")
                    }
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

        }
    }
    
    private var daysRemaining: Int? {
        let remaining = TimeInterval(minutes: Double(sensorInfo.sensorMinutesLeft))
        if remaining > .days(1)  {
            return Int(remaining.days)
        }
        return nil
    }
    
    private var hoursRemaining: Int? {
        let remaining = TimeInterval(minutes: Double(sensorInfo.sensorMinutesLeft))
        if remaining > .hours(1) {
            return Int(remaining.hours.truncatingRemainder(dividingBy: 24))
        }
        return nil
    }
    
    private var minutesRemaining: Int? {
        let remaining = TimeInterval(minutes: Double(sensorInfo.sensorMinutesLeft))
        if remaining < .hours(2) {
            return Int(remaining.minutes.truncatingRemainder(dividingBy: 60))
        }
        return nil
    }
    
    func timeComponent(value: Int, units: String) -> some View {
        Group {
            Text(String(value)).font(.system(size: 28)).fontWeight(.heavy)
                .foregroundColor(.primary)
                //.foregroundColor(viewModel.podOk ? .primary : .secondary)
            Text(units).foregroundColor(.secondary)
        }
    }
    
    var showProgress : Bool {
        return sensorInfo.expiresAt != nil && sensorInfo.activatedAt != nil
    }
    
    
    var lifecycleProgress: some View {
        VStack(spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                if showProgress {
                    Text(LocalizedString("Sensor expires in ", comment: "Text describing sensor expires in label in settingsview"))
                        .foregroundColor(.secondary)
                } else {
                    Text(LocalizedString("No Connection: ",comment: "Text describing no connection label in settingsview"))
                        .foregroundColor(.secondary)
                    + Text("\(transmitterInfo.connectionState)")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                if showProgress {
                    daysRemaining.map { (days) in
                        timeComponent(value: days, units: days == 1 ?
                                      LocalizedString("day", comment: "Unit for singular day in sensor liferemaining") :
                                        LocalizedString("days", comment: "Unit for plural days in sensor life remaining"))
                    }
                    hoursRemaining.map { (hours) in
                        timeComponent(value: hours, units: hours == 1 ?
                                      LocalizedString("hour", comment: "Unit for singular hour in sensor life remaining") :
                                        LocalizedString("hours", comment: "Unit for plural hours in sensor life remaining"))
                    }
                    minutesRemaining.map { (minutes) in
                        timeComponent(value: minutes, units: minutes == 1 ?
                                      LocalizedString("minute", comment: "Unit for singular minute in sensor life remaining") :
                                        LocalizedString("minutes", comment: "Unit for plural minutes in sensor life remaining"))
                    }
                }
            }
            if showProgress {
                
                SwiftUI.ProgressView(value: sensorInfo.calculateProgress())
                    .scaleEffect(x: 1, y: 4, anchor: .center)
                    .padding(.top, 2)
                //ProgressView(progress: ))
                Spacer()
            }
            //.accentColor(self.viewModel.lifeState.progressColor(guidanceColors: guidanceColors))
        }
    }
    
    var headerImage: some View {
        VStack(alignment: .center) {
            Image(uiImage: UIImage(named: "libresensor200", in: Bundle.current, compatibleWith: nil)!)
                .resizable()
                .aspectRatio(contentMode: ContentMode.fit)
                .frame(height: 100)
                .padding(.horizontal)
        }.frame(maxWidth: .infinity)
    }
    
    var sensorStatusText : String {
        let ret = sensorInfo.sensorState
        return ret.isEmpty ? " - " : ret
    }
    var sensorStatus: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LocalizedString("Sensor State", comment: "Text describing Sensor state label in settingsview"))
                .fontWeight(.heavy)
                .fixedSize()
            Text("\(sensorStatusText)")
                .foregroundColor(.secondary)
                .textSelection(.enabled)
        }
    }
    
    var sensorSerialText : String {
        let ret = sensorInfo.sensorSerial
        print ("got serial: \(ret)")
        return ret.isEmpty ? " - " : ret
    }
    
    var sensorSerial : some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LocalizedString("Sensor Serial", comment: "Text describing Sensor serial label in settingsview"))
                //.font(.system(size: 1))
                .fontWeight(.heavy)
                .fixedSize()
            Text("\(sensorSerialText)")
                .foregroundColor(.secondary)
                .textSelection(.enabled)
        }
    }
    
    var headerSection: some View {
        Section() {
            VStack(alignment: .trailing) {
                
                Spacer()
                headerImage
                
                lifecycleProgress
                Spacer()
                HStack(alignment: .top) {
                    sensorStatus
                    Spacer()
                    sensorSerial
                }
                
                /*Divider()
                Text("some faultAction")
                    .font(Font.footnote.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                 */
                
            }
            /*if true {
                VStack(alignment: .leading, spacing: 4) {
                    Text("some notice title")
                        .font(Font.subheadline.weight(.bold))
                    Text("some notice details")
                        .font(Font.footnote.weight(.semibold))
                }.padding(.vertical, 8)
            }*/
        }
    }

    

}

struct SettingsOverview_Previews: PreviewProvider {
    static var previews: some View {
        NotificationSettingsView(glucoseUnit: HKUnit.millimolesPerLiter)
    }
}
