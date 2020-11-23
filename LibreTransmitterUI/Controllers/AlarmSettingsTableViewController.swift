//
//  AlarmsClientSettingsViewController.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 11/04/2019.
//  Copyright © 2019 Bjørn Inge Berg. All rights reserved.
//
import LoopKit
import LoopKitUI
import UIKit

import HealthKit

public protocol AlarmSettingsTableViewControllerDelegate: class {
    func deliveryLimitSettingsTableViewControllerDidUpdateMaximumBasalRatePerHour(_ vc: DeliveryLimitSettingsTableViewController)

    func deliveryLimitSettingsTableViewControllerDidUpdateMaximumBolus(_ vc: DeliveryLimitSettingsTableViewController)
}

public enum DeliveryLimitSettingsResult {
    case success(maximumBasalRatePerHour: Double, maximumBolus: Double)
    case failure(Error)
}

public protocol AlarmSettingsTableViewControllerSyncSource: class {
    func syncDeliveryLimitSettings(for viewController: AlarmSettingsTableViewController, completion: @escaping (_ result: DeliveryLimitSettingsResult) -> Void)

    func syncButtonTitle(for viewController: AlarmSettingsTableViewController) -> String

    func syncButtonDetailText(for viewController: AlarmSettingsTableViewController) -> String?

    func deliveryLimitSettingsTableViewControllerIsReadOnly(_ viewController: AlarmSettingsTableViewController) -> Bool
}

public protocol SubViewControllerWillDisappear: class {
    func onDisappear()
}

public class AlarmSettingsTableViewController: UITableViewController, AlarmTimeInputCellDelegate, GlucoseAlarmInputCellDelegate, CustomDatePickerDelegate { // LFTimePickerDelegate,

    func CustomDatePickerDelegateDidTapDone(fromComponent: DateComponents?, toComponents: DateComponents?) {
        print("alertsettings, picker was set to: from:\(String(describing: fromComponent)), to: \(String(describing: toComponents))")

        //datepickerSender?.minValue = start
        //datepickerSender?.maxValue = end
        datepickerSender?.minComponents = fromComponent
        datepickerSender?.maxComponents = toComponents

        if let index = datepickerSender?.tag, let schedule = glucoseSchedules?.schedules.safeIndexAt(index, default: GlucoseSchedule()) {
            schedule.from = fromComponent
            schedule.to = toComponents
            schedule.enabled = datepickerSender?.toggleIsSelected.isOn
        }
    }

    func CustomDatePickerDelegateDidTapCancel() {
        print("alertsettings: picker was cancelled")
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        print("AlarmSettingsTableViewController will now disappear")
        disappearDelegate?.onDisappear()
    }

    public weak var disappearDelegate: SubViewControllerWillDisappear?

    func glucoseAlarmInputCellDidUpdateValue(_ cell: GlucoseAlarmInputCell, value: Double) {
        print("glucoseAlarmInputCellDidUpdateValue ")
        if let schedule = glucoseSchedules?.schedules.safeIndexAt(cell.tag, default: GlucoseSchedule()), let tag2 = cell.tag2 {
            print("glucoseAlarmInputCellDidUpdateValue, value: \(value), tag1: \(cell.tag), tag2: \(tag2)")

            if tag2 == ScheduleRowTypes.highglucose.rawValue {
                if value == 0 {
                    schedule.highAlarm = nil
                } else {
                    schedule.storeHighAlarm(forUnit: self.glucoseUnit, highAlarm: value)
                }
            } else if tag2 == ScheduleRowTypes.lowglucose.rawValue {
                if value == 0 {
                    schedule.lowAlarm = nil
                } else {
                    schedule.storeLowAlarm(forUnit: self.glucoseUnit, lowAlarm: value)
                }
            }
        }
    }

    func AlarmTimeInputRangeCellWasToggled(_ cell: AlarmTimeInputRangeCell, _ isOn: Bool) {
        NSLog("this schedule was toggled \(isOn ? "on" : "off")" )
        if let schedule = glucoseSchedules?.schedules.safeIndexAt(cell.tag, default: GlucoseSchedule()) {
            schedule.enabled = isOn
        }
    }

    private var datepickerSender: AlarmTimeInputRangeCell?
    /*public func didPickTime(_ start: String, end: String, startComponents: DateComponents?, endComponents: DateComponents?) {
        NSLog("YES, TIME WAS PICKED")
        print(startComponents)
        print(endComponents)
        
        //datepickerSender?.minValue = start
        //datepickerSender?.maxValue = end
        datepickerSender?.minComponents = startComponents
        datepickerSender?.maxComponents = endComponents
        
        if let index = datepickerSender?.tag, let schedule = glucoseSchedules?.schedules.safeIndexAt(index, default: GlucoseSchedule()) {
            schedule.from = startComponents
            schedule.to = endComponents
            schedule.enabled = datepickerSender?.toggleIsSelected.isOn
            
            
        }
    }*/

    private var glucoseUnit: HKUnit
    public weak var delegate: AlarmSettingsTableViewControllerDelegate?

    func AlarmTimeInputRangeCellDidTouch(_ cell: AlarmTimeInputRangeCell) {
        print("dabear:: AlarmTimeInputRangeCellDidTouch called")
        //1. Create a LFTimePickerController
        //let timePicker = LFTimePickerController()

        //2. Present the timePicker
        //self.navigationController?.pushViewController(timePicker, animated: true)
        //self.navigationController?.show(timePicker, sender: cell)
        let timePicker = CustomDatePickerViewController()
        show(timePicker, sender: cell)

        timePicker.delegate = self
        self.datepickerSender = cell
    }

    public var isReadOnly = false

    private var isSyncInProgress = false {
        didSet {
            for cell in tableView.visibleCells {
                switch cell {
                case let cell as TextButtonTableViewCell:
                    cell.isEnabled = !isSyncInProgress
                    cell.isLoading = isSyncInProgress
                case let cell as TextFieldTableViewCell:
                    cell.textField.isEnabled = !isReadOnly && !isSyncInProgress
                default:
                    break
                }
            }

            for item in navigationItem.rightBarButtonItems ?? [] {
                item.isEnabled = !isSyncInProgress
            }

            navigationItem.hidesBackButton = isSyncInProgress
        }
    }
    private lazy var glucoseSchedules: GlucoseScheduleList? = UserDefaults.standard.glucoseSchedules

    private lazy var valueNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()

        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1

        return formatter
    }()

    // MARK: -
    public init(glucoseUnit: HKUnit) {
        self.glucoseUnit = glucoseUnit

        super.init(style: .grouped)
        print("loaded glucose schedule was \(glucoseSchedules)")
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
    }

    // MARK: - Table view data source

    private var glucoseSchedulesCount: Int {
        let count = glucoseSchedules?.schedules.count ?? 0
        return count >= GlucoseScheduleList.minimumSchedulesCount ? count : GlucoseScheduleList.minimumSchedulesCount
    }

    private enum ScheduleRow: Int {
        case timerange
        case lowglucose
        case highglucose

        static let count = 3
    }

    private enum ScheduleRowTypes: String {
        case timerange
        case lowglucose
        case highglucose
    }

    override public func numberOfSections(in tableView: UITableView) -> Int {
        //dynamic number of schedules + sync row
        glucoseSchedulesCount + 1
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        /*switch Section(rawValue: section)! {
         case .schedule1:
         return ScheduleRow.count
         case .schedule2:
         return ScheduleRow.count
         case .sync:
         return 1
         }*/

        switch section {
        case let x where x < glucoseSchedulesCount:
            return ScheduleRow.count
        default:
            return 1
        }
    }

    // swiftlint:disable:next function_body_length
    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case let x where x < glucoseSchedulesCount:

            let bundle = Bundle(for: type(of: self))

            var savedSchedule = glucoseSchedules?.schedules[safe: indexPath.section]

            switch ScheduleRow(rawValue: indexPath.row)! {
            case .timerange:
                let cell = tableView.dequeueIdentifiableCell(cell: AlarmTimeInputRangeCell.self, for: indexPath)
                //cell.minValue = "first"
                //cell.maxValue = "second"
                cell.delegate = self
                cell.tag = indexPath.section
                cell.tag2 = ScheduleRowTypes.timerange.rawValue
                if let schedule = savedSchedule {
                    cell.minComponents = schedule.from
                    cell.maxComponents = schedule.to
                    cell.toggleIsSelected.isOn = schedule.enabled ?? true
                }

                cell.iconImageView.image = UIImage(named: "icons8-schedule-50", in: bundle, compatibleWith: traitCollection)

                return cell
            case .lowglucose:
                let cell = tableView.dequeueIdentifiableCell(cell: GlucoseAlarmInputCell.self, for: indexPath)
                cell.tag = indexPath.section
                cell.tag2 = ScheduleRowTypes.lowglucose.rawValue
                cell.delegate = self
                cell.alarmType = .low
                cell.minValueTextField.placeholder = "glucose"
                cell.unitString = self.glucoseUnit.localizedShortUnitString
                cell.minValueTextField.keyboardType = .decimalPad
                cell.iconImageView.image = UIImage(named: "icons8-drop-down-arrow-50", in: bundle, compatibleWith: traitCollection)

                if let schedule = savedSchedule,
                    let glucose = schedule.retrieveLowAlarm(forUnit: self.glucoseUnit) {
                    cell.minValue = glucose
                }

                return cell
            case .highglucose:
                let cell = tableView.dequeueIdentifiableCell(cell: GlucoseAlarmInputCell.self, for: indexPath)
                cell.tag = indexPath.section
                cell.tag2 = ScheduleRowTypes.highglucose.rawValue
                cell.delegate = self
                cell.alarmType = .high
                cell.minValueTextField.keyboardType = .decimalPad

                cell.unitString = self.glucoseUnit.localizedShortUnitString
                cell.minValueTextField.placeholder = "glucose"
                cell.iconImageView.image = UIImage(named: "icons8-slide-up-50", in: bundle, compatibleWith: traitCollection)

                if let schedule = savedSchedule,
                    let glucose = schedule.retrieveHighAlarm(forUnit: self.glucoseUnit) {
                    cell.minValue = glucose
                }

                return cell
            }

        default: //case .sync:
            let cell = tableView.dequeueIdentifiableCell(cell: TextButtonTableViewCell.self, for: indexPath)

            cell.textLabel?.text = LocalizedString("Save glucose alarms", comment: "The title for Save glucose alarms")
            cell.isEnabled = !isSyncInProgress
            cell.isLoading = isSyncInProgress

            return cell
        }
    }

    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case let x where x < glucoseSchedulesCount:
            return LocalizedString("Glucose Alarm Schedule", comment: "The title text for the Glucose Alarm Schedule") + " #\(section + 1)"
        default: //case .sync:
            return nil
        }
    }

    override public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
         nil
    }

    override public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        true
    }

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case let x where x < glucoseSchedulesCount:
            if let cell = tableView.cellForRow(at: indexPath) as? TextFieldTableViewCell {
                if cell.textField.isFirstResponder {
                    cell.textField.resignFirstResponder()
                } else {
                    cell.textField.becomeFirstResponder()
                }
            }
        default: //case .sync:
            tableView.endEditing(true)

            isSyncInProgress = true

            DispatchQueue.main.async {
                var alert: UIAlertController
                print("before saving, schedules is: \(self.glucoseSchedules)")
                if let settings = self.glucoseSchedules {
                    print("Saving glucose schedule as: : \(settings) ")

                    let validationResult = settings.validateGlucoseSchedules()

                    switch validationResult {
                    case .success:
                        UserDefaults.standard.glucoseSchedules = settings
                        print("Saved glucose schedule was \(String(describing: UserDefaults.standard.glucoseSchedules))")
                        alert = OKAlertController("Glucose alarms successfully saved", title: "Glucose Alarms")

                    case .error(let description):
                        alert = ErrorAlertController("Glucose schedule could not be saved: \(description)", title: "Schedule not saved")

                        print("Could not save glucose schedules, validation failed")
                    }
                } else {
                    alert = ErrorAlertController("Glucose schedules could not be modified", title: "Schedule not saved")
                }
                self.present(alert, animated: true)
                self.isSyncInProgress = false
            }
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
}
