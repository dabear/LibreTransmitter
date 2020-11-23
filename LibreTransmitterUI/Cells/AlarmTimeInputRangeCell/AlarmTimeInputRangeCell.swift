//
//  AlarmTimeInputRangeCell.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 12/04/2019.
//  Copyright © 2019 Bjørn Inge Berg. All rights reserved.
//

import Foundation

import UIKit

protocol AlarmTimeInputCellDelegate: class {
    //func AlarmTimeInputCellDidUpdateValue(_ cell: AlarmTimeInputRangeCell)
    func AlarmTimeInputRangeCellDidTouch(_ cell: AlarmTimeInputRangeCell)
    func AlarmTimeInputRangeCellWasToggled(_ cell: AlarmTimeInputRangeCell, _ isOn: Bool)
}

class AlarmTimeInputRangeCell: UITableViewCell, UITextFieldDelegate {
    private func updateComponentTextField() {
        if let p1 = minComponents?.ToTimeString(), let p2 = maxComponents?.ToTimeString() {
            minValue = "\(p1)-\(p2)"
        }
    }

    public var tag2: String?

    weak var delegate: AlarmTimeInputCellDelegate?
    var minComponents: DateComponents? {
        didSet {
           updateComponentTextField()
        }
    }
    var maxComponents: DateComponents? {
        didSet {
            updateComponentTextField()
        }
    }
    var minValue: String = "" {
        didSet {
            minValueTextField.text = minValue
        }
    }

    lazy var valueNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1

        return formatter
    }()

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

    @IBOutlet weak var toggleIsSelected: UISwitch!

    @IBAction func switchChanged(sender: UISwitch) {
        print("switch changed")
        minValueTextField.isEnabled = sender.isOn

        delegate?.AlarmTimeInputRangeCellWasToggled(self, sender.isOn)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        NSLog("dabear:: required init")
        super.init(coder: aDecoder)
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        // code which you want to execute when the user touch myTextField
        NSLog("dabear:: user has touched mytextfield")
        delegate?.AlarmTimeInputRangeCellDidTouch(self)
        return false
    }

    // MARK: - UITextFieldDelegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        /*DispatchQueue.main.async {
            textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
        }*/
        // code which you want to execute when the user touch myTextField

    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField {
        case minValueTextField:
            minValue = textField.text ?? "defaulta"
        default:
            break
        }

        //delegate?.AlarmTimeInputCelllDidUpdateValue(self)
    }
}
