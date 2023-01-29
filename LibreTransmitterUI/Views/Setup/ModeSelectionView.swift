//
//  ModeSelectionView.swift
//  LibreTransmitterUI
//
//  Created by Bjørn Inge Berg on 02/09/2021.
//  Copyright © 2021 Mark Wilson. All rights reserved.
//

import SwiftUI
import LoopKitUI

struct ModeSelectionView: View {

    @ObservedObject public var cancelNotifier: GenericObservableObject
    @ObservedObject public var saveNotifier: GenericObservableObject
    

    var modeSelectSection : some View {
        Section(header: Text(LocalizedString("Connection options", comment: "Text describing options for connecting to sensor or transmitter"))) {
            #if canImport(CoreNFC)
            ZStack {
                NavigationLink(destination: Libre2DirectSetup(cancelNotifier: cancelNotifier, saveNotifier: saveNotifier)) {
                    
                    SettingsItem(title: LocalizedString("Libre 2 Direct", comment: "Libre 2 connection option"))
                        .actionButtonStyle(.primary)
                        .padding([.top, .bottom], 8)
                        
                }
            }
            #endif

            ZStack {
                NavigationLink(destination: BluetoothSelection(cancelNotifier: cancelNotifier, saveNotifier: saveNotifier)) {
                    SettingsItem(title: LocalizedString("Bluetooth Transmitters", comment: "Bluetooth Transmitter connection option"))
                        .actionButtonStyle(.primary)
                        .padding([.top, .bottom], 8)
                }
            }

        }
    }

    var cancelButton: some View {
        Button(LocalizedString("Cancel", comment: "Cancel button")) {
            cancelNotifier.notify()

        }// .accentColor(.red)
    }
    
    var infoText: some View {
        Text(LocalizedString("""
Select the type of setup you want.

You can choose between connecting directly to a bluetooth equipped Libre sensor or connecting to a third party transmitter attached to your sensor.

Note that the not all sensor types can be supported and that you sensor needs to be already activated and finished warming up.

Fair warning: The sensor will be *not* be using the manufacturer's algorithm, and some safety mitigations present in the manufacturers algorithm might be missing when you use this.
""", comment: "Connection Info body"))
    }
    


    var body : some View {
        GuidePage(content: {
            VStack {
                getLeadingImage()
                HStack {
                    infoText
                        .minimumScaleFactor(0.9)
                        .lineLimit(nil)
                    Spacer()
                    
                }
            }

        }) {
            VStack(spacing: 10) {
                modeSelectSection
            }.padding()
        }
        .animation(.default)
        .navigationBarTitle("New Device Setup", displayMode: .inline)
        .navigationBarItems(trailing: cancelButton)
        .navigationBarBackButtonHidden(true)
    }
}

struct ModeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ModeSelectionView(cancelNotifier: GenericObservableObject(), saveNotifier: GenericObservableObject())
    }
}
