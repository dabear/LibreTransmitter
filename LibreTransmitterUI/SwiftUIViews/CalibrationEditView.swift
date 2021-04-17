//
//  CalibrationEditView.swift
//  LibreTransmitterUI
//
//  Created by Bjørn Inge Berg on 24/03/2021.
//  Copyright © 2021 Mark Wilson. All rights reserved.
//

import SwiftUI
import Combine
import LibreTransmitter



fileprivate var valueNumberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.locale = Locale.current
    formatter.minimumFractionDigits = 1

    return formatter
}()

fileprivate var intNumberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .none
    formatter.locale = Locale.current
    formatter.minimumFractionDigits = 1
    formatter.maximumFractionDigits = 0

    return formatter
}()


private struct ErrorTextFieldStyle : TextFieldStyle {
    public func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.red,  lineWidth: 3))
    }
}

public struct CalibrationItem: View  {



    static func localeTextToDouble(_ text: String) -> Double? {
        valueNumberFormatter.number(from: text)?.doubleValue
    }
    static func doubleToLocateText(_ dbl: Double) -> String? {
        valueNumberFormatter.string(from: dbl as NSNumber)
    }

    static func localeTextToInt(_ text: String) -> Int? {
        intNumberFormatter.number(from: text)?.intValue
    }
    static func intToLocateText(_ dbl: Double) -> String? {
        intNumberFormatter.string(from: dbl as NSNumber)
    }

    @State private(set) var hasError = false


    var textField: some View {



        TextField("Calibration item \(description)", text: $numericString)
            .onReceive(Just(numericString)) { value in

                print("onreceive called")


                guard let newValue = Self.localeTextToDouble(value) else {
                    //consider this or coloring view to indicate error
                    //self.numericString = "\(numericValue)"
                    print("onreceive guard failed")
                    hasError = true

                    return
                }

                let isInteger = newValue.truncatingRemainder(dividingBy: 1.0) == 0.0

                if requiresIntegerValue && !isInteger {
                    //consider this or coloring view to indicate error
                    //self.numericString = "\(numericValue)"
                    hasError = true
                    return

                }

                if self.numericValue != newValue {
                    self.numericValue = newValue
                }

                hasError = false



        }
       .onAppear {
            if requiresIntegerValue {
                self.numericString = Self.intToLocateText(numericValue) ?? "unknown"
            } else {
                self.numericString = Self.doubleToLocateText(numericValue) ?? "unknown"
            }
        }
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .disableAutocorrection(true)
        .keyboardType(.decimalPad)
        .border(Color(UIColor.separator))
        .disabled(isReadOnly)



    }




    var textFieldWithError : some View{
        textField
        .overlay(
            VStack {
                if hasError {
                    Rectangle()
                    .stroke(Color.red, lineWidth: 1)
                } else {
                    EmptyView()
                }

            }
        )
    }

    public var body: some View {
        HStack {
            Text("\(description)")
            textFieldWithError


        }
        .padding(1)

    }

    init(description: String, numericValue:  Binding<Double>, isReadOnly:Bool=false ) {
        self.description = description
        self._numericValue = numericValue
        self.requiresIntegerValue = false
        self.isReadOnly = isReadOnly
    }


   

    init(description: String, numericValue wrapper:  Binding<Int>, isReadOnly:Bool=false) {
        self.description = description
        self.requiresIntegerValue = true
        self.isReadOnly = isReadOnly


        //allows an int to behave as a double, should be just fine in most cases
        let bd = Binding<Double>(get: { Double(wrapper.wrappedValue) },
                              set: { wrapper.wrappedValue = Int($0) })
        self._numericValue = bd


    }

    var description: String
    var isReadOnly: Bool = false

    var requiresIntegerValue = false
    //numericvalue assumes that all ints can be encoded as doubles, which might not be true always though.
    @Binding var numericValue: Double
    @State private var numericString: String  = ""



}

private struct ListHeader: View {
    var body: some View {
        HStack {
            Image(systemName: "pencil.circle")
            Text("Edit Calibration data")
        }


    }
}
fileprivate typealias Params = SensorData.CalibrationInfo

struct BlueButtonStyle: ButtonStyle {

  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
        .font(.headline)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .contentShape(Rectangle())
        .padding()
        .foregroundColor(configuration.isPressed ? Color.white.opacity(0.5) : Color.white)
        .listRowBackground(configuration.isPressed ? Color.blue.opacity(0.5) : Color.blue)
  }
}

struct CalibrationMessage: Identifiable {
    var id: String { title }
    let title: String
    let message: String
}

struct CalibrationEditView: View {

    static func asHostedViewController(cgmManager: LibreTransmitterManager?)-> UIHostingController<Self> {
        UIHostingController(rootView: self.init(cgmManager: cgmManager, debugMode: false))
    }


    @State private var isPressed = false

    @State private var presentableStatus: CalibrationMessage?

    public var isReadOnly : Bool {
        if debugMode {
            return false
        }

        return !hasExistingParams
    }

    var body: some View {
        List {
            Section {
                ListHeader()
            }
            Section {
                CalibrationItem(description: "i1", numericValue: $newParams.i1, isReadOnly: isReadOnly)
                CalibrationItem(description: "i2", numericValue: $newParams.i2, isReadOnly: isReadOnly)
                CalibrationItem(description: "i3", numericValue: $newParams.i3, isReadOnly: isReadOnly)
                CalibrationItem(description: "i4", numericValue: $newParams.i4, isReadOnly: isReadOnly)
                CalibrationItem(description: "i5", numericValue: $newParams.i5, isReadOnly: isReadOnly)
                CalibrationItem(description: "i6", numericValue: $newParams.i6, isReadOnly: isReadOnly)


            }
            Section {
                Text("Valid for footer: \(newParams.isValidForFooterWithReverseCRCs)")

            }
            Section {
                Button(action: {
                    print("calibrationsaving in progress")
                    self.isPressed.toggle()

                    if isReadOnly {
                        presentableStatus = CalibrationMessage(title: "Could not save", message:"Calibration parameters are readonly and cannot be saved")
                        return
                    }

                    do {
                        try self.cgmManager?.keychain.setLibreNativeCalibrationData(newParams)
                        print("calibrationsaving completed")

                        presentableStatus = CalibrationMessage(title: "OK", message: "Calibrations saved!")
                    } catch {
                        print("error: \(error.localizedDescription)")
                        presentableStatus = CalibrationMessage(title: "Calibration error", message:"Calibrations could not be saved, Check that footer crc is non-zero and that all values have sane defaults")
                    }


                }, label: {
                    Text("Save")

                }).buttonStyle(BlueButtonStyle())
                .alert(item: $presentableStatus) { status in
                    Alert(title: Text(status.title), message: Text(status.message) , dismissButton: .default(Text("Got it!")))
                }

            }
        }
    }

    public var cgmManager: LibreTransmitterManager!
    @ObservedObject private var newParams: Params

    private var debugMode = false
    private var hasExistingParams = false

    public init(cgmManager: LibreTransmitterManager?, debugMode:Bool=false) {
        self.cgmManager = cgmManager
        self.debugMode = debugMode


        if let params = cgmManager?.keychain.getLibreNativeCalibrationData() {
            hasExistingParams = true
            self.newParams = params
        } else {
            hasExistingParams = false
            self.newParams = Params(i1: 1,i2: 2,i3: 3,i4: 4,i5: 5,i6: 5,isValidForFooterWithReverseCRCs: 1337)
        }

    }



}

struct CalibrationEditView_Previews: PreviewProvider {
    static var previews: some View {
        CalibrationEditView(cgmManager: nil, debugMode: true)
    }
}
