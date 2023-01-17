//
//  ModeSelectionView.swift
//  LibreTransmitterUI
//
//  Created by Bjørn Inge Berg on 02/09/2021.
//  Copyright © 2021 Mark Wilson. All rights reserved.
//

import SwiftUI

struct ModeSelectionView: View {

    @ObservedObject public var cancelNotifier: GenericObservableObject
    @ObservedObject public var saveNotifier: GenericObservableObject

    var modeSelectSection : some View {
        Section(header: Text("Modes")) {
            #if canImport(CoreNFC)
            ZStack {
                NavigationLink(destination: Libre2DirectSetup(cancelNotifier: cancelNotifier, saveNotifier: saveNotifier)) {
                    SettingsItem(title: "Libre 2 Direct", detail: .constant(""))
                        .padding(.top, 30)
                        .padding(.bottom, 30)
                }
            }
            #endif

            ZStack {
                NavigationLink(destination: BluetoothSelection(cancelNotifier: cancelNotifier, saveNotifier: saveNotifier)) {
                    SettingsItem(title: "Bluetooth Transmitters", detail: .constant(""))
                        .padding(.top, 30)
                        .padding(.bottom, 30)
                }
            }

        }
    }

    var cancelButton: some View {
        Button("Cancel") {
            print("cancel button pressed")
            cancelNotifier.notify()

        }// .accentColor(.red)
    }

    var body: some View {
        // no navview needed when embedded into a hostingcontroller
        // NavigationView{
        List {
            Section("Mode selection info") {
                Text("""
Select the type of setup you want

You can choose between connecting directly to a bluetooth equipped Libre sensor or connect to a third party transmitter attached to your sensor
""")
            }
            modeSelectSection
        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: cancelButton)

    }
}

struct ModeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ModeSelectionView(cancelNotifier: GenericObservableObject(), saveNotifier: GenericObservableObject())
    }
}
