//
//  AlarmTimeInputRangeCell.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 12/04/2019.
//  Copyright © 2019 Bjørn Inge Berg. All rights reserved.
//

import Foundation

import UIKit

protocol mmTextFieldViewCellCellDelegate: class {
    func mmTextFieldViewCellDidUpdateValue(_ cell: MMTextFieldViewCell, value: String?)
}

private var maxLengths = [UITextField: Int]()

class MMTextFieldViewCell: UITableViewCell, UITextFieldDelegate {
    weak var delegate: mmTextFieldViewCellCellDelegate?

    // MARK: Outlets

    @IBOutlet weak var iconImageView: UIImageView!

    @IBOutlet weak var titleLabel: UILabel!

    @IBAction func didStartEditing(_ sender: Any) {
        print("did start editing textfield cell")
        textInput!.becomeFirstResponder()
        textInput!.selectAll(nil)
    }
    @IBAction func didStopEditing(_ sender: Any) {
        print("did stop editing textfield cell")
        textInput!.resignFirstResponder()
        delegate?.mmTextFieldViewCellDidUpdateValue(self, value: textInput?.text)
    }

    public var isEnabled: Bool {
        get {
            titleLabel!.isEnabled && textInput!.isEnabled
        }
        set {
            titleLabel!.isEnabled = newValue
            textInput!.isEnabled = newValue
        }
    }

    @IBOutlet weak var textInput: AllowedCharsTextField?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        print("here1")
    }

    required init?(coder aDecoder: NSCoder) {
        NSLog("dabear:: required init")
        super.init(coder: aDecoder)
        print("here2")
        textInput?.keyboardType = .numberPad
    }
}

// 2
extension AllowedCharsTextField {
    // 3
    @IBInspectable var maxLength: Int {
        get {
            // 4
            guard let length = maxLengths[self] else {
                return Int.max
            }
            return length
        }
        set {
            maxLengths[self] = newValue
            // 5
            addTarget(
                self,
                action: #selector(limitLength),
                for: UIControl.Event.editingChanged
            )
        }
    }

    @objc
    func limitLength(textField: UITextField) {
        // 6
        NSLog("maxlength for uitextfield is: \(maxLength)")
        guard let prospectiveText = textField.text, prospectiveText.count > maxLength else {
            NSLog("limitlength returned, prospectiveText.count is \(textField.text?.count)")
            return
        }
        NSLog("limitlength continue")

        let selection = selectedTextRange

        text = String(prospectiveText.prefix(maxLength))

        selectedTextRange = selection
    }
}

// 1
class AllowedCharsTextField: UITextField, UITextFieldDelegate {
    // 2
    @IBInspectable var allowedChars: String = ""

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // 3
        delegate = self
        // 4
        autocorrectionType = .no
    }

    // 5
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // 6

        if string.isEmpty || allowedChars.isEmpty {
            return true
        }

        // 7
        let currentText = (textField.text ?? "") as NSString
        let prospectiveText = currentText.replacingCharacters(in: range, with: string)

        return  prospectiveText.containsOnlyCharactersIn(matchCharacters: allowedChars)
    }
}

// 8
extension String {
    // Returns true if the string contains only characters found in matchCharacters.
    func containsOnlyCharactersIn(matchCharacters: String) -> Bool {
        let disallowedCharacterSet = NSCharacterSet(charactersIn: matchCharacters).inverted
        return self.rangeOfCharacter(from: disallowedCharacterSet) == nil
    }
}
