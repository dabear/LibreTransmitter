//
//  GlucoseNotificationsSettingsTableViewController.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 07/05/2019.
//  Copyright © 2019 Bjørn Inge Berg All rights reserved.
//
import LoopKit
import LoopKitUI
import UIKit

import HealthKit
public class NotificationsSettingsTableViewController: UITableViewController, mmTextFieldViewCellCellDelegate {
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("NotificationsSettingsTableViewController will now disappear")
        disappearDelegate?.onDisappear()
    }

    public weak var disappearDelegate: SubViewControllerWillDisappear?

    private var glucoseUnit: HKUnit

    public init(glucoseUnit: HKUnit) {
        if let savedGlucoseUnit = UserDefaults.standard.mmGlucoseUnit {
            self.glucoseUnit = savedGlucoseUnit
        } else {
            self.glucoseUnit = glucoseUnit
            UserDefaults.standard.mmGlucoseUnit = glucoseUnit
        }

        // todo: save/persist glucoseUnit in init
        // to make it accessible for the non-ui part of this plugin
        self.glucseSegmentsStrings = self.glucoseSegments.map({ $0.localizedShortUnitString })

        super.init(style: .grouped)
    }
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override public func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(AlarmTimeInputRangeCell.nib(), forCellReuseIdentifier: AlarmTimeInputRangeCell.className)

        tableView.register(GlucoseAlarmInputCell.nib(), forCellReuseIdentifier: GlucoseAlarmInputCell.className)

        tableView.register(TextFieldTableViewCell.nib(), forCellReuseIdentifier: TextFieldTableViewCell.className)
        tableView.register(TextButtonTableViewCell.self, forCellReuseIdentifier: TextButtonTableViewCell.className)
        tableView.register(SegmentViewCell.nib(), forCellReuseIdentifier: SegmentViewCell.className)

        tableView.register(MMSwitchTableViewCell.nib(), forCellReuseIdentifier: MMSwitchTableViewCell.className)

        tableView.register(MMTextFieldViewCell.nib(), forCellReuseIdentifier: MMTextFieldViewCell.className)
        self.tableView.rowHeight = 44
    }

    private let glucoseSegments = [HKUnit.millimolesPerLiter, HKUnit.milligramsPerDeciliter]
    private var glucseSegmentsStrings: [String]

    private enum NotificationsSettingsRow: Int, CaseIterable {
        case always
        case alertEveryXTime
        case lowBattery
        case invalidSensorDetected
        //case alarmNotifications
        case newSensorDetected
        case noSensorDetected
        case expireSoonAlarm
        case unit
        case glucoseVibrate
        case glucseAlarmsAlsoShowBattery
        case glucoseAlarmsShowTransmitterBattery

        static let count = NotificationsSettingsRow.allCases.count
    }

    override public func numberOfSections(in tableView: UITableView) -> Int {
        //dynamic number of schedules + sync row
        1
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        NotificationsSettingsRow.count
    }

    private weak var notificationEveryXTimesCell: MMTextFieldViewCell?

    @objc
    private func notificationAlwaysChanged(_ sender: UISwitch) {
        print("notificationalways changed to \(sender.isOn)")
        UserDefaults.standard.mmAlwaysDisplayGlucose = sender.isOn
        notificationEveryXTimesCell?.isEnabled = !sender.isOn
    }

    @objc
    private func notificationLowBatteryChanged(_ sender: UISwitch) {
        print("notificationLowBatteryChanged changed to \(sender.isOn)")
        UserDefaults.standard.mmAlertLowBatteryWarning = sender.isOn
    }
    @objc
    private func alarmsSchedulesActivatedChanged(_ sender: UISwitch) {
        print("alarmsSchedulesActivatedChanged changed to \(sender.isOn)")
        //UserDefaults.standard. = sender.isOn
    }

    @objc
    private func glucseAlarmsAlsoShowBatteryChanged(_ sender: UISwitch) {
        print("glucseAlarmsAlsoShowBatteryChanged changed to \(sender.isOn)")
        UserDefaults.standard.mmShowPhoneBattery = sender.isOn
    }

    @objc
    private func showTransmitterBatteryChanged(_ sender: UISwitch) {
       print("showTransmitterBatteryChanged changed to \(sender.isOn)")
       UserDefaults.standard.mmShowTransmitterBattery = sender.isOn
    }

    @objc
    private func sensorChangeEventChanged(_ sender: UISwitch) {
        print("sensorChangeEventChanged changed to \(sender.isOn)")
        UserDefaults.standard.mmAlertNewSensorDetected = sender.isOn
    }

    @objc
    private func notificationlertWillSoonExpireChanged(_ sender: UISwitch) {
        print("mmAlertWillSoonExpire changed to \(sender.isOn)")
        UserDefaults.standard.mmAlertWillSoonExpire = sender.isOn
    }

    @objc
    private func noSensorDetectedEventChanged(_ sender: UISwitch) {
        print("noSensorDetectedEventChanged changed to \(sender.isOn)")
        UserDefaults.standard.mmAlertNoSensorDetected = sender.isOn
    }

    @objc
    private func unitSegmentValueChanged(_ sender: UISegmentedControl) {
        if let newUnit = glucoseSegments[safe: sender.selectedSegmentIndex] {
            print("unitSegmentValueChanged   changed to \(newUnit.localizedShortUnitString)")
            UserDefaults.standard.mmGlucoseUnit = newUnit
        }
    }

    @objc
    private func notificationGlucoseAlarmsVibrate(_ sender: UISwitch) {
        print("mmGlucoseAlarmsVibrate changed to \(sender.isOn)")
        UserDefaults.standard.mmGlucoseAlarmsVibrate = sender.isOn
    }

    func mmTextFieldViewCellDidUpdateValue(_ cell: MMTextFieldViewCell, value: String?) {
        if let value = value, let intVal = Int(value) {
            print("textfield was updated: \(intVal)")
            UserDefaults.standard.mmNotifyEveryXTimes = intVal
        }
    }

    // swiftlint:disable:next function_body_length
    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch NotificationsSettingsRow(rawValue: indexPath.row)! {
        case .always:
            let switchCell = tableView.dequeueIdentifiableCell(cell: MMSwitchTableViewCell.self, for: indexPath)

            switchCell.toggleIsSelected?.isOn = UserDefaults.standard.mmAlwaysDisplayGlucose
            //switchCell.titleLabel?.text = "test"

            switchCell.titleLabel?.text = NSLocalizedString("Always Notify Glucose", comment: "The title text for the looping enabled switch cell")

            switchCell.toggleIsSelected?.addTarget(self, action: #selector(notificationAlwaysChanged(_:)), for: .valueChanged)
            switchCell.contentView.layoutMargins.left = tableView.separatorInset.left
            return switchCell
        case .alertEveryXTime:
            notificationEveryXTimesCell = tableView.dequeueIdentifiableCell(cell: MMTextFieldViewCell.self, for: indexPath)

            notificationEveryXTimesCell?.textInput?.text = String(UserDefaults.standard.mmNotifyEveryXTimes)
            notificationEveryXTimesCell!.titleLabel.text = NSLocalizedString("Notify Per Reading (0-9)", comment: "The title text for the Notify every reading nr")
            notificationEveryXTimesCell!.delegate = self
            notificationEveryXTimesCell!.isEnabled = !UserDefaults.standard.mmAlwaysDisplayGlucose

            return notificationEveryXTimesCell!

        case .unit:

            let cell = tableView.dequeueIdentifiableCell(cell: SegmentViewCell.self, for: indexPath)
            cell.label.text = "Unit Override"
            cell.segment.replaceSegments(segments: glucseSegmentsStrings)
            if let selectIndex = glucseSegmentsStrings.firstIndex(where: { item -> Bool in
                item == glucoseUnit.localizedShortUnitString
            }) {
                cell.segment.selectedSegmentIndex = selectIndex
            }

            cell.segment.addTarget(self, action: #selector(unitSegmentValueChanged(_:)), for: .valueChanged)
            cell.segment.addTarget(self, action: #selector(unitSegmentValueChanged(_:)), for: .touchUpInside)

            return cell

        case .lowBattery:
            let switchCell = tableView.dequeueIdentifiableCell(cell: MMSwitchTableViewCell.self, for: indexPath)

            switchCell.toggleIsSelected?.isOn = UserDefaults.standard.mmAlertLowBatteryWarning
            //switchCell.titleLabel?.text = "test"

            switchCell.titleLabel?.text = NSLocalizedString("Low Battery", comment: "The title text for the miaomiao low battery notifications")

            switchCell.toggleIsSelected?.addTarget(self, action: #selector(notificationLowBatteryChanged(_:)), for: .valueChanged)
            switchCell.contentView.layoutMargins.left = tableView.separatorInset.left
            return switchCell
        case .invalidSensorDetected:
            let switchCell = tableView.dequeueIdentifiableCell(cell: MMSwitchTableViewCell.self, for: indexPath)

            switchCell.toggleIsSelected?.isOn = UserDefaults.standard.mmAlertInvalidSensorDetected
            //switchCell.titleLabel?.text = "test"

            switchCell.titleLabel?.text = NSLocalizedString("Invalid Sensor", comment: "The title text for the miaomiao Invalid sensor detected")

            switchCell.toggleIsSelected.isEnabled = false

            return switchCell

        case .newSensorDetected:
            let switchCell = tableView.dequeueIdentifiableCell(cell: MMSwitchTableViewCell.self, for: indexPath)

            switchCell.toggleIsSelected?.isOn = UserDefaults.standard.mmAlertNewSensorDetected
            //switchCell.titleLabel?.text = "test"

            switchCell.titleLabel?.text = NSLocalizedString("Sensor Change", comment: "The title text for the miaomiao sensor change detected event")

            switchCell.toggleIsSelected?.addTarget(self, action: #selector(sensorChangeEventChanged(_:)), for: .valueChanged)
            switchCell.contentView.layoutMargins.left = tableView.separatorInset.left
            return switchCell
        case .noSensorDetected:
            let switchCell = tableView.dequeueIdentifiableCell(cell: MMSwitchTableViewCell.self, for: indexPath)

            switchCell.toggleIsSelected?.isOn = UserDefaults.standard.mmAlertNoSensorDetected
            //switchCell.titleLabel?.text = "test"

            switchCell.titleLabel?.text = NSLocalizedString("Sensor Not found", comment: "The title text for the miaomiao sensor not found event")

            switchCell.toggleIsSelected?.addTarget(self, action: #selector(noSensorDetectedEventChanged(_:)), for: .valueChanged)
            switchCell.contentView.layoutMargins.left = tableView.separatorInset.left
            return switchCell
        case .expireSoonAlarm:
            let switchCell = tableView.dequeueIdentifiableCell(cell: MMSwitchTableViewCell.self, for: indexPath)

            switchCell.toggleIsSelected?.isOn = UserDefaults.standard.mmAlertWillSoonExpire
            //switchCell.titleLabel?.text = "test"

            switchCell.titleLabel?.text = NSLocalizedString("Sensor Expires Soon", comment: "The title text for the miaomiao sensor Sensor Expires soon event")

            switchCell.toggleIsSelected?.addTarget(self, action: #selector(notificationlertWillSoonExpireChanged(_:)), for: .valueChanged)
            switchCell.contentView.layoutMargins.left = tableView.separatorInset.left
            return switchCell
        case .glucoseVibrate:
            let switchCell = tableView.dequeueIdentifiableCell(cell: MMSwitchTableViewCell.self, for: indexPath)

            switchCell.toggleIsSelected?.isOn = UserDefaults.standard.mmGlucoseAlarmsVibrate
            //switchCell.titleLabel?.text = "test"

            switchCell.titleLabel?.text = NSLocalizedString("Glucose Alarms Vibrate", comment: "The title text for the Glucose Alarms vibrate notifications")

            switchCell.toggleIsSelected?.addTarget(self, action: #selector(notificationGlucoseAlarmsVibrate(_:)), for: .valueChanged)
            switchCell.contentView.layoutMargins.left = tableView.separatorInset.left
            return switchCell
        case .glucseAlarmsAlsoShowBattery:
            let switchCell = tableView.dequeueIdentifiableCell(cell: MMSwitchTableViewCell.self, for: indexPath)

            switchCell.toggleIsSelected?.isOn = UserDefaults.standard.mmShowPhoneBattery
            //switchCell.titleLabel?.text = "test"

            switchCell.titleLabel?.text = NSLocalizedString("Glucose Alarms Show Phone Battery", comment: "The title text for the Glucose Alarms Show Phone Battery notifications")

            switchCell.toggleIsSelected?.addTarget(self, action: #selector(glucseAlarmsAlsoShowBatteryChanged(_:)), for: .valueChanged)
            switchCell.contentView.layoutMargins.left = tableView.separatorInset.left
            return switchCell
        case .glucoseAlarmsShowTransmitterBattery:
            let switchCell = tableView.dequeueIdentifiableCell(cell: MMSwitchTableViewCell.self, for: indexPath)

            switchCell.toggleIsSelected?.isOn = UserDefaults.standard.mmShowTransmitterBattery
            //switchCell.titleLabel?.text = "test"

            switchCell.titleLabel?.text = NSLocalizedString("Glucose Alarms Show Transmitter Battery", comment: "The title text for the Glucose Alarms Show Transmitter Battery notifications")

            switchCell.toggleIsSelected?.addTarget(self, action: #selector(showTransmitterBatteryChanged(_:)), for: .valueChanged)
            switchCell.contentView.layoutMargins.left = tableView.separatorInset.left
            return switchCell
        }
    }

    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        LocalizedString("Notification settings", comment: "The title text for the Notification settings")
    }

    override public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        nil
    }

    override public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        true
    }

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch NotificationsSettingsRow(rawValue: indexPath.row)! {
        case .always:
            print("selected always row")
        case .unit:
            print("selected unit row")
        case .lowBattery:
            print("selected low battery row")
        case .invalidSensorDetected:
            print("selected invalidSensorDetected")
            //case .alarmNotifications:
        //    print("selected alarmNotifications")
        case .newSensorDetected:
            print("selected sensorChanged")
        case .noSensorDetected:
            print("selected noSensorDetected")
        case .expireSoonAlarm:
            print("selected expireSoonAlarm")
        case .alertEveryXTime:
            print("selected alertEveryXTime")
        case .glucoseVibrate:
            print("selected glucoseVibrate")
        case .glucseAlarmsAlsoShowBattery:
            print("selected glucseAlarmsAlsoShowBattery")
        case .glucoseAlarmsShowTransmitterBattery:
            print("selected glucoseAlarmsShowTransmitterBattery")
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
}
