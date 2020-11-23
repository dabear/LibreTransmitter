//
//  NibLoadable.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 11/04/2019.
//  Copyright © 2019 Bjørn Inge Berg. All rights reserved.
//

import LoopKitUI
import UIKit

protocol NibLoadable: IdentifiableClass {
    static func nib() -> UINib
}

extension NibLoadable {
    static func nib() -> UINib {
        UINib(nibName: className, bundle: Bundle(for: self))
    }
}

extension TextFieldTableViewCell: NibLoadable { }

extension AlarmTimeInputRangeCell: NibLoadable { }
extension GlucoseAlarmInputCell: NibLoadable {}
extension SegmentViewCell: NibLoadable {}
extension MMSwitchTableViewCell: NibLoadable {}
extension MMTextFieldViewCell: NibLoadable {}
extension MMTextFieldViewCell2: NibLoadable {}
