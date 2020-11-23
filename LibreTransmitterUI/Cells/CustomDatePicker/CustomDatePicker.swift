//
//  CustomDatePicker.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 18/06/2019.
//  Copyright © 2019 Bjørn Inge Berg. All rights reserved.
//

import Foundation
import UIKit

enum CustomDateComponents: Int, CaseIterable {
    case from
    case desc
    case to

    static let count = CustomDateComponents.allCases.count
}

class CustomDatePicker: UIPickerView, UIPickerViewDelegate, UIPickerViewDataSource {
    private lazy var startComponentTimes = defaultTimeArray()
    private lazy var endComponentTimes = defaultTimeArray()

    var lastSelectedComponentLeft: DateComponents? {
        let row = self.selectedRow(inComponent: CustomDateComponents.from.rawValue)
        return startComponentTimes[safe: row]
    }
    var lastSelectedComponentRight: DateComponents? {
        let row = self.selectedRow(inComponent: CustomDateComponents.to.rawValue)
        return endComponentTimes[safe: row]
    }

    private var startTimes = [String]()
    private var endTimes = [String]()

    open class var wants12hourClock: Bool {
        Date.LocaleWantsAMPM
    }

    func setPickerLabels(labels: [Int: UILabel], containedView: UIView) { // [component number:label]

        let fontSize: CGFloat = 20
        let labelWidth: CGFloat = containedView.bounds.width / CGFloat(self.numberOfComponents)
        let x: CGFloat = self.frame.origin.x
        let y: CGFloat = (self.frame.size.height / 2) - (fontSize / 2)

        for i in 0...self.numberOfComponents {
            if let label = labels[i] {
                if self.subviews.contains(label) {
                    label.removeFromSuperview()
                }

                label.frame = CGRect(x: x + labelWidth * CGFloat(i), y: y, width: labelWidth, height: fontSize)

                label.font = UIFont.systemFont(ofSize: fontSize)
                label.backgroundColor = .clear
                label.textAlignment = NSTextAlignment.center

                self.addSubview(label)
            }
        }
    }

    func defaultTimeArray() -> [DateComponents] {
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

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    private func commonInit() {
        delegate = self
        dataSource = self

        populateLeftSide()
        populateRightSide()
    }

    func populateLeftSide() {
        for component in startComponentTimes {
            startTimes.append(component.ToTimeString(wantsAMPM: CustomDatePicker.wants12hourClock))
        }
    }

    func populateRightSide() {
        for component in endComponentTimes {
            endTimes.append(component.ToTimeString(wantsAMPM: CustomDatePicker.wants12hourClock))
        }
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch CustomDateComponents(rawValue: component)! {
        case .from:
            return startTimes.count
        case .to:
            return endTimes.count
        case .desc:
            return 1
        }
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        CustomDateComponents.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch CustomDateComponents(rawValue: component)! {
        case .from:
            return startTimes[safe: row] ?? "unknown"
        case .to:
            return endTimes[safe: row] ?? "unknown"
        case .desc:
            return ""
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch CustomDateComponents(rawValue: component)! {
        case .from, .to:
            let fromRow = self.selectedRow(inComponent: CustomDateComponents.from.rawValue)
            let toRow = self.selectedRow(inComponent: CustomDateComponents.to.rawValue)

            if toRow < fromRow {
                self.selectRow(fromRow, inComponent: CustomDateComponents.to.rawValue, animated: false)
            }
        default:
            break
        }
    }
}
