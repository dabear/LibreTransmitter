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
    init(title: String, detail: String) {
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
            Spacer()
            Text(detail).font(.subheadline)
        }

    }
}

private class FactoryCalibrationInfo: ObservableObject, Equatable, Hashable {
    @Published var i1 = ""
    @Published var i2 = ""
    @Published var i3 = ""
    @Published var i4 = ""
    @Published var i5 = ""
    @Published var i6 = ""
    @Published var validForFooter = ""
    
    // For swiftuis stateobject to be able to compare two objects for equality,
    // we must exclude the publishers them selves in the comparison

   static func == (lhs: FactoryCalibrationInfo, rhs: FactoryCalibrationInfo) -> Bool {
        lhs.i1 == rhs.i1 && lhs.i2 == rhs.i2 &&
        lhs.i3 == rhs.i3 && lhs.i4 == rhs.i4 &&
        lhs.i5 == rhs.i5 && lhs.i6 == rhs.i6 &&
        lhs.validForFooter == rhs.validForFooter

    }

    // todo: consider using cgmmanagers observable directly
    static func loadState() -> FactoryCalibrationInfo {

        let newState = FactoryCalibrationInfo()

        // User editable calibrationdata: keychain.getLibreNativeCalibrationData()
        // Default Calibrationdata stored in sensor: cgmManager?.calibrationData

        // do not change this, there is UI support for editing calibrationdata anyway
        guard let c = KeychainManagerWrapper.standard.getLibreNativeCalibrationData() else {
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



struct SettingsView: View {

    @ObservedObject private var displayGlucoseUnitObservable: DisplayGlucoseUnitObservable
    @ObservedObject private var transmitterInfo: LibreTransmitter.TransmitterInfo
    @ObservedObject private var sensorInfo: LibreTransmitter.SensorInfo

    @ObservedObject private var glucoseMeasurement: LibreTransmitter.GlucoseInfo

    @ObservedObject private var notifyComplete: GenericObservableObject
    @ObservedObject private var notifyDelete: GenericObservableObject

   
    @State private var presentableStatus: StatusMessage?
    @ObservedObject var alarmStatus: LibreTransmitter.AlarmStatus

    @State private var showingDestructQuestion = false
    //@State private var showingExporter = false
    // @Environment(\.presentationMode) var presentationMode

    static func asHostedViewController(
        displayGlucoseUnitObservable: DisplayGlucoseUnitObservable,
        notifyComplete: GenericObservableObject,
        notifyDelete: GenericObservableObject,
        transmitterInfoObservable: LibreTransmitter.TransmitterInfo,
        sensorInfoObervable: LibreTransmitter.SensorInfo,
        glucoseInfoObservable: LibreTransmitter.GlucoseInfo,
        alarmStatus: LibreTransmitter.AlarmStatus) -> UIHostingController<SettingsView> {
        UIHostingController(rootView: self.init(
            displayGlucoseUnitObservable: displayGlucoseUnitObservable,
            transmitterInfo: transmitterInfoObservable,
            sensorInfo: sensorInfoObervable,
            glucoseMeasurement: glucoseInfoObservable,
            notifyComplete: notifyComplete,
            notifyDelete: notifyDelete,
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
                
                transmitterInfoSection
                
                
                NavigationLink(destination: CalibrationEditView()) {
                    Button("Edit calibrations") {
                        print("edit calibration clicked")
                    }
                }
                advancedSection
                
                // disable for now due to null byte document issues
                /*if false {
                 logExportSection
                 }*/
                
                destructSection
                    .listStyle(InsetGroupedListStyle())
                
                
            }

            .onAppear {
                print("dabear:: settingsview appeared")
                // While loop does this request on our behalf, freeaps does not
                NotificationHelper.requestNotificationPermissionsIfNeeded()
                
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
                Text("Pause Glucose alarms").frame(alignment: .center)
                    .foregroundColor(.blue)
                
            }
        }
    }

    var measurementSection : some View {
        Section(header: Text("Last measurement")) {
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
        Section(header: Text("Last Blood Sugar prediction")) {
            if glucoseUnit == .millimolesPerLiter {
                    SettingsItem(title: "CurrentBG", detail: $glucoseMeasurement.predictionMMOL)
            } else if glucoseUnit == .milligramsPerDeciliter {
                    SettingsItem(title: "Glucose", detail: $glucoseMeasurement.predictionMGDL)
            }

            SettingsItem(title: "Date", detail: $glucoseMeasurement.predictionDate )

        }
    }

    var transmitterInfoSection: some View {
        Section(header: Text("Transmitter Info")) {
            if !transmitterInfo.battery.isEmpty {
                SettingsItem(title: "Battery", detail: $transmitterInfo.battery )
            }
            SettingsItem(title: "Hardware", detail: $transmitterInfo.hardware )
            SettingsItem(title: "Firmware", detail: $transmitterInfo.firmware )
            SettingsItem(title: "Connection State", detail: $transmitterInfo.connectionState )
            SettingsItem(title: "Transmitter Type", detail: $transmitterInfo.transmitterType )
            SettingsItem(title: "Mac", detail: $transmitterInfo.transmitterIdentifier )
            SettingsItem(title: "Sensor Type", detail: $transmitterInfo.sensorType )
        }
    }


    private var doneButton: some View {
        Button("Done", action: {
            notifyComplete.notify()
        })
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

    // todo: replace sub with navigationlinks
    var advancedSection: some View {
        Section(header: Text("Advanced")) {
            // these subviews don't really need to be notified once glucose unit changes
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

        }
    }

    /*var logExportSection : some View {
        Section {
            Button("Export logs") {
                showingExporter = true
            }.foregroundColor(.blue)
        }
    }*/
    
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
        return ["Notifying"].contains(transmitterInfo.connectionState)
    }
    
    
    var lifecycleProgress: some View {
        VStack(spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                if showProgress {
                    Text("Sensor expires in ")
                        .foregroundColor(.secondary)
                } else {
                    Text("No Connection: ")
                        .foregroundColor(.secondary)
                    + Text("\(transmitterInfo.connectionState)")
                        .foregroundColor(.secondary)
                }
                /*Text("Sensor Status: ")
                    .foregroundColor(.primary)
                + Text("\(transmitterInfo.connectionState)")
                    .foregroundColor(.secondary)
                 */
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
        var ret = sensorInfo.sensorState
        return ret.isEmpty ? " - " : ret
    }
    var sensorStatus: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Sensor State")
                .fontWeight(.heavy)
                .fixedSize()
            Text("\(sensorStatusText)")
                .foregroundColor(.secondary)
                .textSelection(.enabled)
        }
    }
    
    var sensorSerialText : String {
        var ret = sensorInfo.sensorSerial
        return ret.isEmpty ? " - " : ret
    }
    
    var sensorSerial : some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Sensor Serial")
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
/*
struct LogsAsTextFile: FileDocument {
    // tell the system we support only plain text
    static var readableContentTypes = [UTType.plainText]

    // a simple initializer that creates new, empty documents
    init() {
    }

    // this initializer loads data that has been saved previously
    init(configuration: ReadConfiguration) throws {
    }

    // this will be called when the system wants to write our data to disk
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        var data = Data()
        do {
            data = try getLogs()
        } catch {
            data.append("No logs available".data(using: .utf8, allowLossyConversion: false)!)
        }

        let wrapper = FileWrapper(regularFileWithContents: data)
        let today = Date().getFormattedDate(format: "yyyy-MM-dd")
        wrapper.preferredFilename = "libretransmitterlogs-\(today).txt"
        return wrapper

    }
}*/

struct SettingsOverview_Previews: PreviewProvider {
    static var previews: some View {
        NotificationSettingsView(glucoseUnit: HKUnit.millimolesPerLiter)
    }
}
