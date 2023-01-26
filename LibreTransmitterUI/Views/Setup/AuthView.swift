//
//  AuthView.swift
//  LibreTransmitterUI
//
//  Created by Bjørn Inge Berg on 23/01/2023.
//  Copyright © 2023 Mark Wilson. All rights reserved.
//

import SwiftUI
import LoopKitUI
//this view should only be called when setting up a new device in an existing cgmmanager
struct AuthView: View {
    
    // The idea is that the cancel and save notifiers will call this complete notifier from the parent
    @ObservedObject public var completeNotifier : GenericObservableObject
    @ObservedObject public var notifyReset: GenericObservableObject
    @ObservedObject public var notifyReconnect: GenericObservableObject
    
    @StateObject public var cancelNotifier = GenericObservableObject()
    @StateObject public var saveNotifier = GenericObservableObject()
    
    @State private var isAuthenticated = false
    @State private var hasSetupListeners = false
    
    var exclamation: Image {
        Image(systemName: "exclamationmark.triangle.fill")
            
    }
    
    @State var isNavigationActive = false
 
    var buttonSection : some View{
        Section {
            
            if isAuthenticated {
                Text(LocalizedString("Authenticated", comment: "Text confirming user is authenticated in AuthView"))
                    .padding([.top, .horizontal])
                    .transition(AnyTransition.opacity.combined(with: .move(edge: .bottom)))
                NavigationLink(destination: ModeSelectionView(cancelNotifier: cancelNotifier, saveNotifier: saveNotifier), isActive: $isNavigationActive) {
                    Button(action: {
                        self.notifyReset.notify()
                        self.isNavigationActive = true
                    }) {
                        Text(LocalizedString("Sensor Setup", comment: "Text of Sensor Setup Button in AuthView"))
                            .actionButtonStyle(.primary)
                    }
    
                    
                    
                }
                .disabled(!isAuthenticated)
            } else {
                Button(action: {
                    self.authenticate { success in
                        self.isAuthenticated = success
                    }
                }) {
                    Text(LocalizedString("Authenticate", comment: "Text of Authenticate button in AuthView"))
                        .actionButtonStyle(.primary)
                }
                
            }
            
        }
        
    }
    
    
    var cancelButton: some View {
        Button("Cancel") {
            // no need to reconnect here as we haven't been asked to disconnect yet
            completeNotifier.notify()
            
            // If commented out, this will force bluetooth state restoration. Great for testing
            //notifyReconnect.notify()
        }
    }
    
    
    func handleCancel() {
        // Cancel request is coming in from a subview
        // In all cases this means that the connection to existing sensor has been terminated
        // So we always need to reconnect
        print("\(#function) called on authview")
        //completeNotifier.notify()
        notifyReconnect.notify()
    }
    
    func handleSave() {
        print("\(#function) called on authview")
        //completeNotifier.notify()
        
        
        let hasNewDevice = SelectionState.shared.selectedStringIdentifier != UserDefaults.standard.preSelectedDevice
        if hasNewDevice, let newDevice = SelectionState.shared.selectedStringIdentifier {
            print("dabear: authview will set new device to \(newDevice)")
            UserDefaults.standard.preSelectedDevice = newDevice
            SelectionState.shared.selectedUID = nil
            UserDefaults.standard.preSelectedUid = nil

        } else if let newUID = SelectionState.shared.selectedUID {
            // this one is only temporary,
            // as we don't know the bluetooth identifier during nfc setup
            print("dabear: authview will set new libre2 device  to \(newUID)")

            UserDefaults.standard.preSelectedUid = newUID
            SelectionState.shared.selectedUID = nil
            UserDefaults.standard.preSelectedDevice = nil

        } else {

            // this cannot really happen unless you are a developer and have previously
            // stored both preSelectedDevice and selectedUID !
        }
        
        
        notifyReconnect.notify()
    }
    
    var body: some View {
        
        GuidePage(content: {
            VStack {
                getLeadingImage()
                HStack {
                    Text(LocalizedString("You need to authenticate before you can proceed to selecting a new Transmitter or Sensor.", comment: "Text describing the need for authentication before changing device"))
                    
                    Spacer()
                }
                HStack {
                    (
                        Text(exclamation).foregroundColor(.yellow) +
                        Text(LocalizedString("Note that you will loose connection to any existing sensor or transmitter", comment: "Text "))
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                }.padding(.vertical)
            }

        }) {
            VStack(spacing: 10) {
                buttonSection
            }.padding()
        }
        .animation(.default)
        .navigationBarTitle("New Device Setup", displayMode: .inline)
        .navigationBarItems(trailing: cancelButton)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if !hasSetupListeners {
                hasSetupListeners = true
                
                cancelNotifier.listenOnce(listener: handleCancel)
                saveNotifier.listenOnce(listener: handleSave)
            }
            
        }

    }
}




struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView(completeNotifier: GenericObservableObject(), notifyReset: GenericObservableObject(), notifyReconnect: GenericObservableObject())
    }
}
