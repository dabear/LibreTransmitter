//
//  AlarmTimeInputRangeCell.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 12/04/2019.
//  Copyright © 2019 Bjørn Inge Berg. All rights reserved.
//

import Foundation

import UIKit

protocol mmSwitchTableViewCellDelegate: class {
    //func AlarmTimeInputCellDidUpdateValue(_ cell: AlarmTimeInputRangeCell)
    func mmSwitchTableViewCellDidTouch(_ cell: MMSwitchTableViewCell)
    func mmSwitchTableViewCellWasDisabled(_ cell: MMSwitchTableViewCell)
}

class MMSwitchTableViewCell: UITableViewCell, UITextFieldDelegate {
    weak var delegate: mmSwitchTableViewCellDelegate?

    // MARK: Outlets

    @IBOutlet weak var iconImageView: UIImageView!

    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var toggleIsSelected: UISwitch!

    @IBAction func switchChanged(sender: UISwitch) {
        print("switch changed")

        //delegate?.AlarmTimeInputRangeCellDidTouch(self)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        NSLog("dabear:: required init")
        super.init(coder: aDecoder)
    }
}
