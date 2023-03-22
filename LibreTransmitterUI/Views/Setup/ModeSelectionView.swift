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
            
                NavigationLink(destination: Libre2DirectSetup(cancelNotifier: cancelNotifier, saveNotifier: saveNotifier)) {
                    
                    SettingsItem(title: LocalizedString("Libre 2 Direct", comment: "Libre 2 connection option"))
                        .actionButtonStyle(.primary)
                        .padding([.top, .bottom], 8)
                        
                }
            
            #endif

            
                NavigationLink(destination: BluetoothSelection(cancelNotifier: cancelNotifier, saveNotifier: saveNotifier)) {
                    SettingsItem(title: LocalizedString("Bluetooth Transmitters", comment: "Bluetooth Transmitter connection option"))
                        .actionButtonStyle(.primary)
                        .padding([.top, .bottom], 8)
                }
            

        }
    }

    var cancelButton: some View {
        Button(LocalizedString("Cancel", comment: "Cancel button")) {
            cancelNotifier.notify()

        }// .accentColor(.red)
    }
    

    var body : some View {
        GuidePage(content: {
            VStack {
                getLeadingImage()
                
                HStack {
                    InstructionList(instructions: [
                        LocalizedString("Sensor should be activated and fully warmed up", comment: "Label text for step 1 of connection setup"),
                        LocalizedString("Select the type of setup you want.", comment: "Label text for step 2 of connection setup"),
                        LocalizedString("Not all sensor types can be supported, see readme.md", comment: "Label text for step 3 of connection setup"),
                        LocalizedString("Fair warning: The sensor will be not be using the manufacturer's algorithm, and some safety mitigations present in the manufacturers algorithm might be missing when you use this.", comment: "Label text for step 4 of connection setup")
                    ])
                }
                    
  
            }

        }) {
            VStack(spacing: 10) {
                modeSelectSection
            }.padding()
        }
        .animation(.default)
        //TODO: make this non-inline. Be warned that non-inline here for some reason creates overlapping UI elements and unresponsive ui :/
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
