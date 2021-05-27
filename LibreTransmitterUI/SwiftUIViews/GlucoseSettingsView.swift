//
//  GlucoseSettingsView.swift
//  LibreTransmitterUI
//
//  Created by Bjørn Inge Berg on 26/05/2021.
//  Copyright © 2021 Mark Wilson. All rights reserved.
//

import SwiftUI
import Combine
import LibreTransmitter
import HealthKit




private struct ListHeader: View {
    var body: some View {
        HStack {
            Image(systemName: "pencil.circle")
            Text("Glucose settings")
        }

    }
}



struct GlucoseSettingsView: View {


    static func asHostedViewController(glucoseUnit: HKUnit, disappearDelegate: SubViewControllerWillDisappear?) -> UIHostingController<Self> {
        UIHostingController(rootView: self.init(glucoseUnit: glucoseUnit, disappearDelegate: disappearDelegate))
    }

    @State private var presentableStatus: StatusMessage?



    public weak var disappearDelegate: SubViewControllerWillDisappear?

    private var glucoseUnit: HKUnit

    public init(glucoseUnit: HKUnit, disappearDelegate: SubViewControllerWillDisappear?=nil) {
        if let savedGlucoseUnit = UserDefaults.standard.mmGlucoseUnit {
            self.glucoseUnit = savedGlucoseUnit
        } else {
            self.glucoseUnit = glucoseUnit
            UserDefaults.standard.mmGlucoseUnit = glucoseUnit
        }

        self.disappearDelegate = disappearDelegate

    }



    @AppStorage("no.bjorninge.mmSyncToNs") var mmSyncToNS: Bool = true
    @AppStorage("no.bjorninge.mmBackfillFromHistory") var mmBackfillFromHistory: Bool = true
    @AppStorage("no.bjorninge.mmBackfillFromTrend") var mmBackfillFromTrend: Bool = false
    @AppStorage("no.bjorninge.shouldPersistSensorData") var shouldPersistSensorData: Bool = false

    var body: some View {
        List {
            Section {
                ListHeader()
            }
            Section(header: Text("Backfill options"), footer:Text("Backfilling from trend is currently not well supported by Loop") ) {
                Toggle("Backfill from history", isOn:$mmBackfillFromHistory)
                Toggle("Backfill from trend", isOn: $mmBackfillFromTrend)
            }
            Section(header: Text("Remote data storage")) {
                Toggle("Upload to nightscout", isOn:$mmSyncToNS)
            }
            Section(header: Text("Debug options"), footer: Text("Adds a lot of data to the Issue Report ")) {
                Toggle("Persist sensordata", isOn:$shouldPersistSensorData)
            }

        }
        .listStyle(InsetGroupedListStyle())
        .alert(item: $presentableStatus) { status in
            Alert(title: Text(status.title), message: Text(status.message) , dismissButton: .default(Text("Got it!")))
        }
        .onDisappear {
            disappearDelegate?.onDisappear()
        }

    }




}


struct GlucoseSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        GlucoseSettingsView(glucoseUnit: HKUnit.millimolesPerLiter, disappearDelegate:nil)
    }
}
