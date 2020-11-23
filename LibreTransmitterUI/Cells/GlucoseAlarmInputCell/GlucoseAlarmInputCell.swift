//
//  GlucoseRangeOverrideTableViewCell.swift
//  LoopKit
//
//  Created by Nate Racklyeft on 7/13/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import UIKit

protocol GlucoseAlarmInputCellDelegate: class {
    func glucoseAlarmInputCellDidUpdateValue(_ cell: GlucoseAlarmInputCell, value: Double)
}

class GlucoseAlarmInputCell: UITableViewCell, UITextFieldDelegate {
    public enum GlucoseAlarmType: String {
        case low = "Low"
        case high = "High"
    }

    weak var delegate: GlucoseAlarmInputCellDelegate?

    var minValue: Double = 0 {
        didSet {
            minValueTextField.text = valueNumberFormatter.string(from: NSNumber(value: minValue))
        }
    }

    public var tag2: String?

    lazy var valueNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1

        return formatter
    }()

    var alarmType: GlucoseAlarmType? {
        didSet {
            titleLabel.text = alarmType?.rawValue ?? "invalid"
        }
    }

    var unitString: String? {
        get {
            return unitLabel.text
        }
        set {
            unitLabel.text = newValue
        }
    }

    // MARK: Outlets

    @IBOutlet weak var iconImageView: UIImageView!

    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var unitLabel: UILabel!

    @IBOutlet weak var minValueTextField: UITextField!

    // MARK: - UITextFieldDelegate

    func textFieldDidBeginEditing(_ textField: UITextField) {
        print("textfield did begin editing")
        DispatchQueue.main.async {
            textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        let value = valueNumberFormatter.number(from: textField.text ?? "")?.doubleValue ?? 0

        switch textField {
        case minValueTextField:
            minValue = value

        default:
            break
        }

        delegate?.glucoseAlarmInputCellDidUpdateValue(self, value: value)
    }
}
