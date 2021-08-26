//
//  BluetoothSelection.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 17/10/2020.
//  Copyright © 2020 Bjørn Inge Vikhammermo Berg. All rights reserved.
//

import Combine
import CoreBluetooth
import LibreTransmitter
import SwiftUI

private struct Defaults {
    static let rowBackground = Color(UIColor.secondarySystemGroupedBackground)
    static let selectedRowBackground = Color.orange.opacity(0.2)
    static let background = Color(UIColor.systemGroupedBackground)
}

//https://www.objc.io/blog/2020/02/18/a-signal-strength-indicator/
struct SignalStrengthIndicator: View {
    @Binding var bars : Int
    var totalBars: Int = 5
    var body: some View {
        HStack {
            ForEach(0..<totalBars) { bar in
                RoundedRectangle(cornerRadius: 3)
                    .divided(amount: (CGFloat(bar) + 1) / CGFloat(self.totalBars))
                    .fill(Color.primary.opacity(bar < self.bars ? 1 : 0.3))
            }
        }
    }
}

extension Shape {
    func divided(amount: CGFloat) -> Divided<Self> {
        return Divided(amount: amount, shape: self)
    }
}

struct Divided<S: Shape>: Shape {
    var amount: CGFloat // Should be in range 0...1
    var shape: S
    func path(in rect: CGRect) -> Path {
        shape.path(in: rect.divided(atDistance: amount * rect.height, from: .maxYEdge).slice)
    }
}



private struct ListFooter: View {
    var devicesCount = 0
    var body: some View {
        Text("Found devices: \(devicesCount)")
    }
}

private struct DeviceItem: View {
    var device: SomePeripheral
    @Binding var rssi: RSSIInfo?
    var details1: String
    var details2: String?
    var details3: String?

    @ObservedObject var selection: SelectionState = .shared

    func getDeviceImage(_ device: SomePeripheral) -> Image {
        var image: UIImage!
        switch device {
        case let .Left(realDevice):
            image = LibreTransmitters.getSupportedPlugins(realDevice)?.first?.smallImage

        case .Right:
            image = LibreTransmitters.all.randomElement()?.smallImage
        }

        return image == nil  ?  Image(systemName: "exclamationmark.triangle") : Image(uiImage: image)
    }

    func getRowBackground(device: SomePeripheral) -> Color {
        selection.selectedStringIdentifier == device.asStringIdentifier ?
        Defaults.selectedRowBackground : Defaults.rowBackground
    }

    init(device: SomePeripheral, details: String, rssi: Binding<RSSIInfo?>) {
        self.device = device
        self._rssi = rssi

        details1 = device.name ?? "UnknownDevice"
        let split = details.split(separator: "\n")

        if split.count >= 2 {
            details2 = String(split[0])
            details3 = String(split[1])
        } else {
            details2 = details
        }
    }


    var body : some View {
        HStack {
            getDeviceImage(device)
            .frame(width: 100, height: 50, alignment: .leading)

            VStack(alignment: .leading) {
                Text("\(details1)")
                    .font(.system(size: 20, weight: .medium, design: .default))
                if let details2 = details2 {
                    Text("\(details2)")
                }
                if let details3 = details3 {
                    Text("\(details3)")
                }


            }
            Spacer()
            VStack(alignment: .center, spacing: /*@START_MENU_TOKEN@*/nil/*@END_MENU_TOKEN@*/, content: {
                if let rssi = rssi {
                    SignalStrengthIndicator(bars: .constant(rssi.signalBars), totalBars: rssi.totalBars)
                        .frame(width: 40, height: 40, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                }
            })


        }
        .listRowBackground(getRowBackground(device: device))
        .onTapGesture {
            print("tapped \(device.asStringIdentifier)")
            selection.selectedStringIdentifier = device.asStringIdentifier
        }
    }
}

// Decided to use shared instance instead of .environmentObject()
class SelectionState: ObservableObject {
    @Published var selectedStringIdentifier: String? = ""

    static var shared = SelectionState()
}

struct BluetoothSelection: View {
    @ObservedObject var selection: SelectionState = .shared

    public func getNewDeviceId () -> String? {
        selection.selectedStringIdentifier
    }

    private var searcher: BluetoothSearchManager!

    static func asHostedViewController() -> UIHostingController<Self> {
        UIHostingController(rootView: self.init())
    }

    // Should contain all discovered and compatible devices
    // This list is expected to contain 10 or 20 items at the most
    @State var allDevices = [SomePeripheral]()
    @State var deviceDetails = [String: String]()
    @State var rssi = [String: RSSIInfo]()

    var nullPubliser: Empty<CBPeripheral, Never>!
    var debugMode = false

    init(debugMode: Bool = false) {
        self.debugMode = debugMode

        if self.debugMode {
            allDevices = Self.getMockData()
            nullPubliser = Empty<CBPeripheral, Never>()

        } else {
            self.searcher = BluetoothSearchManager()
        }

        LibreTransmitter.NotificationHelper.requestNotificationPermissionsIfNeeded()

       
    }

    public mutating func stopScan(_ removeSearcher: Bool = false) {
        self.searcher?.disconnectManually()
        if removeSearcher {
            self.searcher = nil
        }
    }

    var headerSection: some View {
        Section {
            Text("Select the third party transmitter you want to connect to")
                .listRowBackground(Defaults.background)
                .padding(.top)
            HStack {
                Image(systemName: "link.circle")
                Text("Libre Transmitters")
            }
        }
    }
    var list : some View {
        List {
            headerSection

            Section {
                ForEach(allDevices) { device in
                    if debugMode {
                        let randomRSSI = RSSIInfo(bledeviceID: device.asStringIdentifier, signalStrength: -90 + (1...70).randomElement()!)
                        DeviceItem(device: device, details: "mockdatamockdata mockdata mockdata\nmockdata2 nmockdata2", rssi: .constant(randomRSSI))
                    } else {
                        DeviceItem(device: device, details: deviceDetails[device.asStringIdentifier]!, rssi: Binding<RSSIInfo?>(get: {
                            rssi[device.asStringIdentifier]
                        }, set: { newVal in
                            //not ever needed
                        }) )
                    }



                }
            }
            Section {
                ListFooter(devicesCount: allDevices.count)
            }
        }
        .onAppear {
            //devices = Self.getMockData()
            if debugMode {
                allDevices = Self.getMockData()
            } else {
                print("dabear:: asking searcher to search!")
                self.searcher?.scanForCompatibleDevices()
            }
        }
        .onDisappear {
            if !self.debugMode {
                print("dabear:: asking searcher to stop searching!")
                self.searcher?.disconnectManually()
            }
        }
    }

    func receiveRSSI(_ rssi: RSSIInfo) {
        let now = Date().description
        print("\(now) got rssi \(rssi.signalStrength) for bluetoothdevice \(rssi.bledeviceID)")
        self.rssi[rssi.bledeviceID] = rssi

    }

    var body: some View {
        if debugMode {
            list
                .onReceive(nullPubliser) { _ in
                    print("nullpublisher received element!?")
                    //allDevices.append(SomePeripheral.Left(device))
                }
        } else {
            list
                .onReceive(searcher.passThroughMetaData) { newDevice, advertisement in
                    print("received searcher passthrough")

                    let alreadyAdded = allDevices.contains { existingDevice -> Bool in
                        existingDevice.asStringIdentifier == newDevice.asStringIdentifier
                    }
                    if !alreadyAdded {
                        if let parsedAdvertisement = LibreTransmitters.getSupportedPlugins(newDevice)?.first?.getDeviceDetailsFromAdvertisement(advertisementData: advertisement) {
                            deviceDetails[newDevice.asStringIdentifier] = parsedAdvertisement
                        } else {
                            deviceDetails[newDevice.asStringIdentifier] = newDevice.asStringIdentifier
                        }
                        allDevices.append(SomePeripheral.Left(newDevice))
                    }
                }
                .onReceive(searcher.throttledRSSI.throttledPublisher, perform: receiveRSSI)
        }


    }
}

extension BluetoothSelection {
    static func getMockData() -> [SomePeripheral] {
        [
            SomePeripheral.Right(MockedPeripheral(name: "device1")),
            SomePeripheral.Right(MockedPeripheral(name: "device2")),
            SomePeripheral.Right(MockedPeripheral(name: "device3")),
            SomePeripheral.Right(MockedPeripheral(name: "device4"))
        ]
    }
}

struct BluetoothSelection_Previews: PreviewProvider {
    static var previews: some View {
        var testData = SelectionState.shared
        testData.selectedStringIdentifier = "device4"

        return BluetoothSelection(debugMode: true)
    }
}
