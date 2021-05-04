//
//  CustomDataPickerView.swift
//  LibreTransmitterUI
//
//  Created by Bjørn Inge Berg on 28/04/2021.
//  Copyright © 2021 Mark Wilson. All rights reserved.
//

import SwiftUI

protocol CustomDataPickerDelegate: class {
    func pickerDidPickValidRange()

}

class AlarmTimeCellExternalState : ObservableObject {
    @Published var start : Int = 0
    @Published var end : Int = 0

    // These will be auto populøated
    // when the start and end properties above change
    @Published var startComponents : DateComponents? = nil
    @Published var endComponents : DateComponents? = nil
}

struct StatusMessage: Identifiable {
    var id: String { title }
    let title: String
    let message: String
}


struct CustomDataPickerView: View {
    private var startComponentTimes : [DateComponents]
    private var endComponentTimes : [DateComponents]

    private var startTimes = [String]()
    private var endTimes = [String]()



    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var externalState: AlarmTimeCellExternalState

    public weak var delegate: CustomDataPickerDelegate?

    private func popView() {
        self.presentationMode.wrappedValue.dismiss()
    }

    static func defaultTimeArray() -> [DateComponents] {
        var arr  = [DateComponents]()

        for hr in 0...23 {
            for min in 0 ..< 2 {
                var components = DateComponents()
                components.hour = hr
                components.minute = min == 1 ? 30 : 0
                arr.append(components)
            }
        }
        var components = DateComponents()
        components.hour = 0
        components.minute = 0
        arr.append(components)

        return arr
    }



    private func callDelegate() {
        delegate?.pickerDidPickValidRange()
    }

    private func verifyRange(){

        // This can be simplified but decided not to do so
        // because the intention becomes more clear

        var isok : Bool

        if externalState.start == 0 || externalState.end == 0 {
            isok = true
        } else {
            if externalState.start > externalState.end {
                isok = false
            } else if externalState.end < externalState.start {
                isok = false
            } else {
                isok = true
            }
        }

        print("is ok? \(isok)")
        if isok {
            callDelegate()
            popView()

        } else {
            presentableStatus = .init(title: "Interval error", message: "Selected time interval was incorrectly specified")
        }


    }

    
    var pickers: some View {
        NavigationView {
            HStack {
                Picker("", selection: $externalState.start.animation(), content: {
                    ForEach(startTimes.indices) { i in
                        Text("\(startTimes[i])").tag(i)
                   }
                })
                //.border(Color.green)

                .zIndex(10)
                .frame(width: 100)
                .clipped()
                .labelsHidden()

                Text("To ")

                Picker("", selection: $externalState.end.animation(), content: {
                    ForEach(endTimes.indices) { i in
                        Text("\(endTimes[i])").tag(i)
                   }
                })
                //.border(Color.red)
                .zIndex(11)
                .frame(width: 100)
                .clipped()
                .labelsHidden()

            }


        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle("Schedule")
        .navigationBarItems(leading:
            Button("Cancel"){
                print("cancel button pressed...")
                popView()
                
            }.accentColor(.red), trailing:
                Button("Save") {
                    print("Save button pressed...")
                    verifyRange()
                }
                .accentColor(.red)

        )

    }


    @State private var presentableStatus: StatusMessage?


    var body: some View {

        pickers
        .pickerStyle(InlinePickerStyle())
        .onChange(of: externalState.start, perform: { value in
            print("selectedtart changed to \(value)")
            externalState.startComponents = startComponentTimes[value]



        })
        .onChange(of: externalState.end, perform: { value in
            print("selectedEnd changed to \(value)")
            externalState.endComponents = endComponentTimes[value]



        })
        .onAppear {
            //this could potentially fail with out of bounds but we trust our parent view!
            externalState.startComponents = startComponentTimes[externalState.start]
            externalState.endComponents = endComponentTimes[externalState.end]
        }
        .alert(item: $presentableStatus) { status in
            Alert(title: Text(status.title), message: Text(status.message) , dismissButton: .default(Text("Got it!")))
        }


    }


    init() {
        startComponentTimes = Self.defaultTimeArray()
        endComponentTimes = Self.defaultTimeArray()


        //string representations of the datecomponents arrays   

        for component in startComponentTimes {
            startTimes.append(component.ToTimeString(wantsAMPM:  Date.LocaleWantsAMPM))
        }

        for component in endComponentTimes {
            endTimes.append(component.ToTimeString(wantsAMPM:  Date.LocaleWantsAMPM))

        }

    }
}

struct CustomDataPickerView_Previews: PreviewProvider {
    static var previews: some View {
        CustomDataPickerView().environmentObject(AlarmTimeCellExternalState())
    }
}
