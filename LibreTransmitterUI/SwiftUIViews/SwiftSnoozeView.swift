//
//  TestView.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 15/10/2020.
//  Copyright © 2020 Bjørn Inge Vikhammermo Berg. All rights reserved.
//

import LibreTransmitter
import SwiftUI

struct SwiftSnoozeView: View {
    static func asHostedViewController(manager: LibreTransmitterManager?)-> UIHostingController<Self> {
        UIHostingController(rootView: self.init(manager: manager))
    }

    var pickerTimes: [TimeInterval]! = nil

    var formatter = DateComponentsFormatter()

    func formatInterval(_ interval: TimeInterval) -> String {
        formatter.string(from: interval)!
    }

    init(manager: LibreTransmitterManager?) {
        self.pickerTimes = pickerTimesArray()
        self.manager = manager
        formatter.allowsFractionalUnits = false
        formatter.unitsStyle = .full
    }

    private weak var manager: LibreTransmitterManager?

    func pickerTimesArray() -> [TimeInterval] {
        var arr  = [TimeInterval]()

        let mins10 = 0.166_67
        let mins20 = mins10 * 2
        let mins30 = mins10 * 3
        //let mins40 = mins10 * 4

        for hr in 0..<2 {
            for min in [0.0, mins20, mins20 * 2] {
                arr.append(TimeInterval(hours: Double(hr) + min))
            }
        }
        for hr in 2..<4 {
            for min in [0.0, mins30] {
                arr.append(TimeInterval(hours: Double(hr) + min))
            }
        }

        for hr in 4...8 {
            arr.append(TimeInterval(hours: Double(hr)))
        }

        return arr
    }

    func getSnoozeDescription() -> String {
        var snoozeDescription  = ""
        var celltext = ""

        if let glucoseDouble = manager?.latestBackfill?.glucoseDouble, let activeAlarms = UserDefaults.standard.glucoseSchedules?.getActiveAlarms(glucoseDouble) {
            switch activeAlarms {
            case .high:
                celltext = "High Glucose Alarm active"
            case .low:
                celltext = "Low Glucose Alarm active"
            case .none:
                celltext = "No Glucose Alarm active"
            }
        } else {
            celltext = "No Glucose Alarm active"
        }

        if let until = GlucoseScheduleList.snoozedUntil {
            snoozeDescription = "snoozing until \(until.description(with: .current))"
        } else {
            snoozeDescription = "not snoozing"
        }

        return [celltext, snoozeDescription].joined(separator: ", ")
    }

    @State private var selectedInterval = 0
    @State private var snoozeDescription = "nothing to see here"

    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Button(action: {
                            print("snooze from testview clicked")
                            let interval = pickerTimes[selectedInterval]
                            let snoozeFor = formatter.string(from: interval)!
                            let untilDate = Date() + interval
                            UserDefaults.standard.snoozedUntil = untilDate < Date() ? nil : untilDate
                            print("will snooze for \(snoozeFor) until \(untilDate.description(with: .current))")
                            snoozeDescription = getSnoozeDescription()
                        }) {
                            Text("Click to Snooze Alerts")
                                .padding()
                }
            }
            .frame( minHeight: 100, alignment: .top)

            VStack {
                Picker(selection: $selectedInterval, label: Text("Strength")) {
                    ForEach(0 ..< pickerTimes.count) {
                        Text(formatInterval(self.pickerTimes[$0]))
                    }
                }

                .scaledToFill()
            }
            .frame(minHeight: 150, maxHeight: 500, alignment: .center)

            VStack(alignment: .leading) {
                Text(snoozeDescription)
            }
            .frame( minHeight: 100, alignment: .bottom)
        }
        .onAppear {
            snoozeDescription = getSnoozeDescription()
        }.onDisappear {
            print("ContentView disappeared!")
        }
    }
}

struct TestView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftSnoozeView(manager: nil)
    }
}
