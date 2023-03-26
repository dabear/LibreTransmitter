//
//  Libre2DirectSetup.swift
//  LibreTransmitterUI
//
//  Created by Bjørn Inge Berg on 30/08/2021.
//  Copyright © 2021 Mark Wilson. All rights reserved.
//

import SwiftUI
import LibreTransmitter
import LoopKitUI
import LoopKit

#if canImport(CoreNFC)

struct Libre2DirectSetup: View {

    @State private var presentableStatus: StatusMessage?
    @State private var showPairingInfo = false

    @State private var service = SensorPairingService()

    @State private var pairingInfo = SensorPairingInfo()

    @ObservedObject public var cancelNotifier: GenericObservableObject
    @ObservedObject public var saveNotifier: GenericObservableObject

    func pairSensor() {
        if !Features.phoneNFCAvailable {
            presentableStatus = StatusMessage(title: "Phone NFC required!", message: "Your phone or app is not enabled for NFC communications, which is needed to pair to libre2 sensors")
            return
        }
        print("Asked to pair sensor! phoneNFCAvailable: \(Features.phoneNFCAvailable)")
        showPairingInfo = false

        service.pairSensor()

    }

    func receivePairingInfo(_ info: SensorPairingInfo) {

        print("Received Pairinginfo: \(String(describing: info))")

        pairingInfo = info

        showPairingInfo = true

        // calibrationdata must always be extracted from the full nfc scan
        if let calibrationData = info.calibrationData {
            do {
                try KeychainManager.standard.setLibreNativeCalibrationData(calibrationData)
            } catch {
                NotificationHelper.sendCalibrationNotification(.invalidCalibrationData)
                return
            }
            // here we assume success, data is not changed,
            // and we trust that the remote endpoint returns correct data for the sensor

            NotificationHelper.sendCalibrationNotification(.success)

            UserDefaults.standard.calibrationMapping = CalibrationToSensorMapping(uuid: info.uuid, reverseFooterCRC: calibrationData.isValidForFooterWithReverseCRCs)

        }

        let max = info.sensorData?.maxMinutesWearTime ?? 0

        let sensor = Sensor(uuid: info.uuid, patchInfo: info.patchInfo, maxAge: max)
        UserDefaults.standard.preSelectedSensor = sensor

        SelectionState.shared.selectedUID = pairingInfo.uuid
        
        // only relevant for launch through settings, as selectionstate can be persisted
        // we need to enforce libre2 by removing any selected third party transmitter
        SelectionState.shared.selectedStringIdentifier = nil
        print(" paried and set selected UID to: \(SelectionState.shared.selectedUID?.hex)")
        saveNotifier.notify()
        NotificationHelper.sendLibre2FirectFinishedSetupNotifcation()

    }

    var cancelButton: some View {
        Button("Cancel") {
            print("cancel button pressed")
            cancelNotifier.notify()

        }// .accentColor(.red)
    }
    
    var pairingInfoSection: some View {
        Section(header: Text("Pairinginfo")) {
            if showPairingInfo {

                SettingsItem(title: "UUID", detail: Binding<String>(get: {
                    pairingInfo.uuid.hex
                }, set: { _ in
                    // not used
                }))

                SettingsItem(title: "PatchInfo", detail: Binding<String>(get: {
                    pairingInfo.patchInfo.hex
                }, set: { _ in
                    // not used
                }))

                SettingsItem(title: "Calibrationinfo", detail: Binding<String>(get: {
                    if let c = pairingInfo.calibrationData {
                        return"\(c.i1),\(c.i2), \(c.i3), \(c.i4), \(c.i5), \(c.i6)"

                    }
                    return "Unknown"
                }, set: { _ in
                    // not used
                }))

            } else {
                Text("Not paired yet")
            }

        }
    }
    
    var body : some View {
        GuidePage(content: {
            
            VStack {
                getLeadingImage()
                HStack {
                    InstructionList(instructions: [
                        LocalizedString("Your sensor must be activated and fully warmed up", comment: "Label text for step 1 of libre2 setup"),
                        LocalizedString("Disconnect and unpair any other app or device communicating with the sensor via bluetooth", comment: "Label text for step 2 of libre2 setup"),
                        LocalizedString("Keep phone unlocked and your Loop app in the foreground", comment: "Label text for step 3 of libre2 setup"),
                        LocalizedString("The Bluetooth connection will take up to four minutes before it starts working", comment: "Label text for step 3 of libre2 setup")
                    ])
                }
            }

        }) {
            VStack(spacing: 10) {
                Button("Pair Sensor & connect") {
                    pairSensor()
                }
                .actionButtonStyle(.primary)
            }.padding()
        }
        .navigationTitle("Libre 2 Setup")
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: cancelButton)  // the pair button does the save process for us! //, trailing: saveButton)
        .onReceive(service.publisher, perform: receivePairingInfo)
        .alert(item: $presentableStatus) { status in
            Alert(title: Text(status.title), message: Text(status.message), dismissButton: .default(Text("Got it!")))
        
        }
    }
}

struct Libre2DirectSetup_Previews: PreviewProvider {
    static var previews: some View {
        Libre2DirectSetup(cancelNotifier: GenericObservableObject(), saveNotifier: GenericObservableObject())
    }
}
#endif
