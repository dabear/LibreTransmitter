//
//  GlucoseNotificationsSettingsTableViewController.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 07/05/2019.
//  Copyright © 2019 Bjørn Inge Berg. All rights reserved.
//
import LoopKit
import LoopKitUI
import UIKit

import HealthKit
import LibreTransmitter

public class CalibrationEditTableViewController: UITableViewController, mmTextFieldViewCellCellDelegate2 {
    public var cgmManager: LibreTransmitterManager?

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("CalibrationEditTableViewController will now disappear")
        disappearDelegate?.onDisappear()
    }

    public weak var disappearDelegate: SubViewControllerWillDisappear?

    private var newParams: SensorData.CalibrationInfo?

    public init(cgmManager: LibreTransmitterManager?) {
        self.cgmManager = cgmManager
        super.init(style: .grouped)

        newParams = cgmManager?.keychain.getLibreNativeCalibrationData()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override public func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(AlarmTimeInputRangeCell.nib(), forCellReuseIdentifier: AlarmTimeInputRangeCell.className)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")

        tableView.register(GlucoseAlarmInputCell.nib(), forCellReuseIdentifier: GlucoseAlarmInputCell.className)

        tableView.register(TextFieldTableViewCell.nib(), forCellReuseIdentifier: TextFieldTableViewCell.className)
        tableView.register(TextButtonTableViewCell.self, forCellReuseIdentifier: TextButtonTableViewCell.className)
        tableView.register(SegmentViewCell.nib(), forCellReuseIdentifier: SegmentViewCell.className)

        tableView.register(MMSwitchTableViewCell.nib(), forCellReuseIdentifier: MMSwitchTableViewCell.className)

        tableView.register(MMTextFieldViewCell2.nib(), forCellReuseIdentifier: MMTextFieldViewCell2.className)
        self.tableView.rowHeight = 44
    }

    private enum CalibrationDataInfoRow: Int {
        case i1
        case i2
        case i3
        case i4
        case i5
        case i6
        case isValidForFooterWithCRCs

        static let count = 7
    }

    private enum Section: Int {
        case CalibrationDataInfoRow
        case sync
    }

    override public func numberOfSections(in tableView: UITableView) -> Int {
        //dynamic number of schedules + sync row
        2
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .CalibrationDataInfoRow:
            return CalibrationDataInfoRow.count
        case .sync:
            return 1
        }
    }
    /*
    weak var slopeslopece: mmTextFieldViewCell2?
    weak var slopeslopeCell: mmTextFieldViewCell2?
    weak var slopeoffsetCell: mmTextFieldViewCell2?
    weak var offsetslopeCell: mmTextFieldViewCell2?
    weak var offsetoffsetCell: mmTextFieldViewCell2?
    weak var isValidForFooterWithCRCsCell: mmTextFieldViewCell2?
    */

    func mmTextFieldViewCellDidUpdateValue(_ cell: MMTextFieldViewCell2, value: String?) {
        if let value = value, let numVal = Double(value), let intVal = Int(value) {
            switch CalibrationDataInfoRow(rawValue: cell.tag)! {
            case .isValidForFooterWithCRCs:
                //this should not happen as crc can not change

                print("isValidForFooterWithCRCs was updated: \(numVal)")
            case .i1:
                newParams?.i1 = intVal
                print("i1 was updated: \(numVal)")
            case .i2:
                newParams?.i2 = intVal
                print("i2 was updated: \(numVal)")
            case .i3:
                newParams?.i3 = numVal
                print("i3 was updated: \(numVal)")
            case .i4:
                newParams?.i4 = numVal
                print("i4 was updated: \(numVal)")
            case .i5:
                newParams?.i5 = numVal
                print("i5 was updated: \(numVal)")
            case .i6:
                newParams?.i6 = numVal
                print("i6 was updated: \(numVal)")
            }
        }
    }

    // swiftlint:disable:next function_body_length
    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == Section.sync.rawValue {
            let cell = tableView.dequeueIdentifiableCell(cell: TextButtonTableViewCell.self, for: indexPath)

            cell.textLabel?.text = LocalizedString("Save calibrations", comment: "The title for Save calibration")
            return cell
        }
        let cell = tableView.dequeueIdentifiableCell(cell: MMTextFieldViewCell2.self, for: indexPath)
        cell.tag = indexPath.row
        cell.delegate = self

        switch CalibrationDataInfoRow(rawValue: indexPath.row)! {
        case .i1:

            cell.textInput?.text = String(newParams?.i1 ?? 0)
            cell.titleLabel.text = NSLocalizedString("i1", comment: "The title text for i1 calibration setting")

        case .i2:
            cell.textInput?.text = String(newParams?.i2 ?? 0)
            cell.titleLabel.text = NSLocalizedString("i2", comment: "The title text for i2 calibration setting")

        case .i3:
            cell.textInput?.text = String(newParams?.i3 ?? 0)
            cell.titleLabel.text = NSLocalizedString("i4", comment: "The title text for i4 calibration setting")
        case .i4:
            cell.textInput?.text = String(newParams?.i4 ?? 0)
            cell.titleLabel.text = NSLocalizedString("i4", comment: "The title text for i4 calibration setting")

        case .isValidForFooterWithCRCs:
            cell.textInput?.text = String(newParams?.isValidForFooterWithReverseCRCs ?? 0)

            cell.titleLabel.text = NSLocalizedString("IsValidForFooter", comment: "The title for the footer crc checksum linking these calibration values to this particular sensor")

            cell.isEnabled = false
        case .i5:
            cell.textInput?.text = String(newParams?.i5 ?? 0)
            cell.titleLabel.text = NSLocalizedString("i5", comment: "The title text for extra i5 calibration setting")

        case .i6:
            cell.textInput?.text = String(newParams?.i6 ?? 0)
            cell.titleLabel.text = NSLocalizedString("i6", comment: "The title text for extra i6 calibration setting")
        }

        return cell
    }

    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == Section.sync.rawValue {
            return nil
        }
        return LocalizedString("Calibrations edit mode", comment: "The title text for the Calibrations edit mode")
    }

    override public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
         nil
    }

    override public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        true
    }

    // swiftlint:disable:next cyclomatic_complexity
    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch  Section(rawValue: indexPath.section)! {
        case .CalibrationDataInfoRow:
            switch CalibrationDataInfoRow(rawValue: indexPath.row)! {
            case .i1:
                print("i1 clicked")
            case .i2:
                print("i2 clicked")

            case .i3:
                print("i3 clicked")
            case .i4:
                print("i4 clicked")
            case .isValidForFooterWithCRCs:
                print("isValidForFooterWithCRCs clicked")
            case .i5:
                print("i5 clicked")
            case .i6:
                print("i6 clicked")
            }
        case .sync:
            print("calibration save clicked")
            var isSaved = false
            let controller: UIAlertController

            if let params = newParams {
                do {
                    try self.cgmManager?.keychain.setLibreNativeCalibrationData(params)
                    isSaved = true
                } catch {
                    print("error: \(error.localizedDescription)")
                }
            }

            if isSaved {
                controller = OKAlertController("Calibrations saved!", title: "ok")
            } else {
                controller = ErrorAlertController("Calibrations could not be saved, Check that footer crc is non-zero and that all values have sane defaults", title: "calibration error")
            }

            self.present(controller, animated: false)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
}
