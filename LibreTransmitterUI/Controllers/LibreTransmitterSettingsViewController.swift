//
//  MiaomiaoClientSettingsViewController.swift
//  Loop
//
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import HealthKit
import LoopKit
import LoopKitUI
import LibreTransmitter
import UIKit
// swiftlint:disable:next type_body_length
public class LibreTransmitterSettingsViewController: UITableViewController, SubViewControllerWillDisappear { //, CompletionNotifying{
    //public weak var completionDelegate: CompletionDelegate?

    public func onDisappear() {
        // this is being called only from alarm, calibration and notifications ui
        // when they disappear
        // the idea is to reload certain gui elements that may have changed
        self.tableView.reloadData()
    }

    private let isDemoMode = false
    public var cgmManager: LibreTransmitterManager?

    public let glucoseUnit: HKUnit

    public let allowsDeletion: Bool

    public init(cgmManager: LibreTransmitterManager, glucoseUnit: HKUnit, allowsDeletion: Bool) {
        self.cgmManager = cgmManager
        self.glucoseUnit = glucoseUnit

        //only override savedglucose unit if we haven't saved this locally before
        if UserDefaults.standard.mmGlucoseUnit == nil {
            UserDefaults.standard.mmGlucoseUnit = glucoseUnit
        }

        self.allowsDeletion = allowsDeletion

        super.init(style: .grouped)
    }

    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func tableView(_ tableView: UITableView, heightForRowAt index: IndexPath) -> CGFloat {
        switch Section(rawValue: index.section)! {
        case .snooze:

            guard let glucoseDouble = cgmManager?.latestBackfill?.glucoseDouble else {
                return UITableView.automaticDimension
            }

            if let alarms = UserDefaults.standard.glucoseSchedules?.getActiveAlarms(glucoseDouble), alarms.isAlarming() {
                return 100
            }

        default:
            break
        }

        return UITableView.automaticDimension
    }
    override public func viewDidLoad() {
        super.viewDidLoad()

        title = cgmManager?.localizedTitle

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44

        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 55

        tableView.register(SettingsTableViewCell.self, forCellReuseIdentifier: SettingsTableViewCell.className)
        tableView.register(TextButtonTableViewCell.self, forCellReuseIdentifier: TextButtonTableViewCell.className)

        let button = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped(_:)))
        self.navigationItem.setRightBarButton(button, animated: false)
    }

    @objc
    func doneTapped(_ sender: Any) {
        complete()
    }

    private func complete() {
        if let nav = navigationController as? SettingsNavigationViewController {
            nav.notifyComplete()
        }
    }

    // MARK: - UITableViewDataSource

    private enum Section: Int, CaseIterable {
        case snooze
        //case bluetoothDeviceSelect
        case latestReading
        case sensorInfo
        case latestBridgeInfo
        case latestCalibrationData
        case advanced

        case delete
    }

    override public func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count - ( allowsDeletion ? 0 : 1 )
    }

    private enum LatestReadingRow: Int, CaseIterable {
        case glucose
        case date
       // case trend
        case footerChecksum
        case error
    }

    private enum LatestSensorInfoRow: Int, CaseIterable {
        case sensorAge
        case sensorTimeLeft
        case sensorState
        case sensorSerialNumber
    }

    private enum TransmitterInfoRow: Int, CaseIterable {
        case battery
        case hardware
        case firmware
        case connectionState
        case transmitterType
        case transmitterIdentifier
        case sensorType
    }

    private enum LatestCalibrationDataInfoRow: Int, CaseIterable {
        case i1
        case i2
        case i3
        case i4
        case i5
        case i6

        case isValidForFooterWithCRCs

        case edit
    }

    private enum GlucoseSettings: Int, CaseIterable {
        case syncToNs
        case sync
    }

    private enum AdvancedSettingsRow: Int, CaseIterable {
        case alarms
        case glucose
        case glucoseNotifications
        case dangermode
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        /*case .bluetoothDeviceSelect:
                return 1*/
        case .latestReading:
            return LatestReadingRow.allCases.count
        case .sensorInfo:
            return LatestSensorInfoRow.allCases.count
        case .delete:
            return 1
        case .latestBridgeInfo:
            return TransmitterInfoRow.allCases.count

        case .latestCalibrationData:
            return LatestCalibrationDataInfoRow.allCases.count

        case .advanced:
            return AdvancedSettingsRow.allCases.count
        case .snooze:
            return 1
        }
    }

    private lazy var glucoseFormatter: QuantityFormatter = {
        let formatter = QuantityFormatter()
        formatter.setPreferredNumberFormatter(for: glucoseUnit)
        return formatter
    }()

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .long
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()

    private func dangerModeActivation(_ isOk: Bool, controller: UIAlertController) {
        if isOk, let textfield = (controller.textFields?[safe: 0]), let text = textfield.text {
            if let bundleSeed = bundleSeedID() {
                let controller: UIAlertController
                if text.trimmingCharacters(in: .whitespaces).lowercased() == bundleSeed.lowercased() {
                    UserDefaults.standard.dangerModeActivated = true
                    controller = OKAlertController("Danger mode activated! You can now edit calibrations!", title: "Danger mode successful")
                } else {
                    controller = ErrorAlertController("Danger mode could not be activated, check that your team identifier matches", title: "Danger mode unsuccessful")
                }
                let dangerCellIndex = IndexPath(row: AdvancedSettingsRow.dangermode.rawValue, section: Section.advanced.rawValue)

                let editCellIndex = IndexPath(row: LatestCalibrationDataInfoRow.edit.rawValue, section: Section.latestCalibrationData.rawValue)

                self.tableView.reloadRows(at: [dangerCellIndex, editCellIndex], with: .none)

                self.presentStatus(controller)
            }
        }
    }
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        /*case .bluetoothDeviceSelect:
            let cell = tableView.dequeueIdentifiableCell(cell: SettingsTableViewCell.self, for: indexPath)

            cell.textLabel?.text = LocalizedString("Bluetooth settings test", comment: "Bluetooth settings test")
            cell.accessoryType = .disclosureIndicator

            return cell*/
        case .latestReading:

            let cell = tableView.dequeueIdentifiableCell(cell: SettingsTableViewCell.self, for: indexPath)
            let glucose = cgmManager?.latestBackfill

            switch LatestReadingRow(rawValue: indexPath.row)! {
            case .glucose:
                cell.textLabel?.text = LocalizedString("Glucose", comment: "Title describing glucose value")

                if let quantity = glucose?.quantity, let formatted = glucoseFormatter.string(from: quantity, for: glucoseUnit) {
                    cell.detailTextLabel?.text = formatted
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }
            case .date:
                cell.textLabel?.text = LocalizedString("Date", comment: "Title describing glucose date")

                if let date = glucose?.timestamp {
                    cell.detailTextLabel?.text = dateFormatter.string(from: date)
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }
            /*case .trend:
                cell.textLabel?.text = LocalizedString("Trend", comment: "Title describing glucose trend")

                cell.detailTextLabel?.text = glucose?.trendType?.localizedDescription ?? SettingsTableViewCell.NoValueString
            */
            case .footerChecksum:
                cell.textLabel?.text = LocalizedString("Sensor Footer checksum", comment: "Title describing Sensor footer reverse checksum")

                cell.detailTextLabel?.text = isDemoMode ? "demo123" : cgmManager?.sensorFooterChecksums
            case .error:
                cell.textLabel?.text = LocalizedString("Entry Errors", comment: "Title describing Glucose Reading error codes")
                if let errors = glucose?.error {
                    cell.detailTextLabel?.text = errors.debugDescription
                    print("EntryErrors:")
                    debugPrint(errors)
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }

            }

            return cell
        case .delete:
            let cell = tableView.dequeueIdentifiableCell(cell: TextButtonTableViewCell.self, for: indexPath)

            cell.textLabel?.text = LocalizedString("Delete CGM", comment: "Title text for the button to remove a CGM from Loop")
            cell.textLabel?.textAlignment = .center
            cell.tintColor = .delete
            cell.isEnabled = true
            return cell
        case .latestBridgeInfo:
            let cell = tableView.dequeueIdentifiableCell(cell: SettingsTableViewCell.self, for: indexPath)

            switch TransmitterInfoRow(rawValue: indexPath.row)! {
            case .battery:
                cell.textLabel?.text = LocalizedString("Battery", comment: "Title describing transmitter battery level")

                cell.detailTextLabel?.text = cgmManager?.batteryString

            case .firmware:
                cell.textLabel?.text = LocalizedString("Firmware", comment: "Title describing transmitter firmware level")

                cell.detailTextLabel?.text = cgmManager?.firmwareVersion

            case .hardware:
                cell.textLabel?.text = LocalizedString("Hardware", comment: "Title describing the Transmitter hardware level")

                cell.detailTextLabel?.text = cgmManager?.hardwareVersion
            case .connectionState:
                cell.textLabel?.text = LocalizedString("Connection State", comment: "Title for the Transmitter Connection State")

                cell.detailTextLabel?.text = cgmManager?.connectionState
            case .transmitterType:
                cell.textLabel?.text = LocalizedString("Transmitter Type", comment: "Title for the Transmitter Type")

                cell.detailTextLabel?.text = cgmManager?.getDeviceType()
            case .transmitterIdentifier:
                // On ios the mac address of the peripheral is generally not available.
                // However, some devices broadcast their mac address in
                // the advertisement data.
                if let mac = cgmManager?.metaData?.macAddress {
                    cell.textLabel?.text = LocalizedString("Mac", comment: "Title for the Transmitter Mac Address")
                    cell.detailTextLabel?.text = mac
                } else {
                    cell.textLabel?.text = LocalizedString("Identifer", comment: "Title for the Transmitter Identifier")
                    cell.detailTextLabel?.text = UserDefaults.standard.preSelectedDevice
                }
            case .sensorType:
                // the sensorType depends on transmitter support for "patchinfo"
                // Each transmitter must explicitly support this, meaning that
                // patchinfo is not always guaranteed to be available

                cell.textLabel?.text = LocalizedString("Sensor Type", comment: "Title for the Transmitters Connected Sensor Type")
                cell.detailTextLabel?.text = cgmManager?.metaData?.sensorType()?.description ?? "Unknown"
            }

            return cell
        case .latestCalibrationData:

            var cell: UITableViewCell = tableView.dequeueIdentifiableCell(cell: SettingsTableViewCell.self, for: indexPath)

            let data = cgmManager?.calibrationData

            switch LatestCalibrationDataInfoRow(rawValue: indexPath.row)! {
            case .i1:
                cell.textLabel?.text = LocalizedString("i1", comment: "Title describing i1 slopeslope")

                if let data = data {
                    cell.detailTextLabel?.text = "\(data.i1)"
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }
            case .i2:
                cell.textLabel?.text = LocalizedString("i2", comment: "Title describing calibrationdata i2")

                if let data = data {
                    cell.detailTextLabel?.text = "\(data.i2)"
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }
            case .i3:
                cell.textLabel?.text = LocalizedString("i3", comment: "Title describing calibrationdata i3")

                if let data = data {
                    cell.detailTextLabel?.text = "\(data.i3)"
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }
            case .i4:
                cell.textLabel?.text = LocalizedString("i4", comment: "Title describing calibrationdata i4")

                if let data = data {
                    cell.detailTextLabel?.text = "\(data.i4)"
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }

            case .isValidForFooterWithCRCs:
                cell.textLabel?.text = LocalizedString("Valid For Footer", comment: "Title describing calibrationdata validity")

                if let data = data {
                    cell.detailTextLabel?.text = isDemoMode ? "demo123"  : "\(data.isValidForFooterWithReverseCRCs)"
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }
            case .edit:
                cell = tableView.dequeueIdentifiableCell(cell: TextButtonTableViewCell.self, for: indexPath)

                cell.textLabel?.text = LocalizedString("Edit Calibrations", comment: "Title describing calibrationdata edit button")

                cell.textLabel?.textColor = UIColor.blue
                if UserDefaults.standard.dangerModeActivated {
                    cell.detailTextLabel?.text = "Available"
                    cell.accessoryType = .disclosureIndicator
                } else {
                    cell.detailTextLabel?.text = "Unavailable"
                }
            case .i5:
                cell.textLabel?.text = LocalizedString("i5", comment: "Title describing calibrationdata i5")

                if let data = data {
                    cell.detailTextLabel?.text = "\(data.i5)"
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }
            case .i6:
                cell.textLabel?.text = LocalizedString("i6", comment: "Title describing calibrationdata i6")

                if let data = data {
                    cell.detailTextLabel?.text = "\(data.i6)"
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }
            }
            return cell
        case .sensorInfo:
            let cell = tableView.dequeueIdentifiableCell(cell: SettingsTableViewCell.self, for: indexPath)

            switch LatestSensorInfoRow(rawValue: indexPath.row)! {
            case .sensorState:
                cell.textLabel?.text = LocalizedString("Sensor State", comment: "Title describing sensor state")

                cell.detailTextLabel?.text = cgmManager?.sensorStateDescription
            case .sensorAge:
                cell.textLabel?.text = LocalizedString("Sensor Age", comment: "Title describing sensor Age")

                cell.detailTextLabel?.text = cgmManager?.sensorAge

            case .sensorSerialNumber:
                cell.textLabel?.text = LocalizedString("Sensor Serial", comment: "Title describing sensor serial")

                cell.detailTextLabel?.text = isDemoMode ? "0M007DEMO1" :cgmManager?.sensorSerialNumber
            case .sensorTimeLeft:
                cell.textLabel?.text = LocalizedString("Sensor Time Left", comment: "Title describing sensor time left")

                cell.detailTextLabel?.text = cgmManager?.sensorTimeLeft
            }
            return cell
        case .advanced:
            let cell = tableView.dequeueIdentifiableCell(cell: SettingsTableViewCell.self, for: indexPath)

            switch AdvancedSettingsRow(rawValue: indexPath.row)! {
            case .alarms:
                cell.textLabel?.text = LocalizedString("Alarms", comment: "Title describing sensor Gluocse Alarms")
                let schedules = UserDefaults.standard.enabledSchedules?.count ?? 0
                let totalSchedules = max(UserDefaults.standard.glucoseSchedules?.schedules.count ?? 0, GlucoseScheduleList.minimumSchedulesCount)

                cell.detailTextLabel?.text = "enabled: \(schedules) / \(totalSchedules)"
                cell.accessoryType = .disclosureIndicator
            case .glucoseNotifications:
                cell.textLabel?.text = LocalizedString("Notifications", comment: "Title describing  Notifications Setup")

                let allToggles = UserDefaults.standard.allNotificationToggles
                let positives = allToggles.filter({ $0 }).count

                cell.detailTextLabel?.text = "enabled: \(positives) / \(allToggles.count)"
                cell.accessoryType = .disclosureIndicator
            case .dangermode:
                cell.textLabel?.text = LocalizedString("Danger mode", comment: "Title describing  Advanced dangerous settings button")

                if UserDefaults.standard.dangerModeActivated {
                    cell.detailTextLabel?.text = "Activated"
                } else {
                    cell.detailTextLabel?.text = "Deactivated"
                }
            case .glucose:
                cell.textLabel?.text = LocalizedString("Glucose settings", comment: "Title describing Glucose Settings")

                //cell.detailTextLabel?.text = "enabled: \(schedules) / \(totalSchedules)"
                cell.accessoryType = .disclosureIndicator
            }

            return cell
        case .snooze:
            //let cell = tableView.dequeueReusableCell(withIdentifier: SettingsTableViewCell.className, for: indexPath) as! SettingsTableViewCell
            let cell = UITableViewCell(style: .default, reuseIdentifier: "DefaultCell")

            cell.textLabel?.textAlignment = .center
            cell.textLabel?.text = LocalizedString("Snooze Alerts", comment: "Title of cell to snooze active alarms")

            //cell.textLabel?.text = LocalizedString("Snooze Alert", comment: "Title of cell to snooze active alarms")
            //cell.textLabel?.textAlignment = .center

            //cell.detailTextLabel?.text =  ""
            //cell.accessoryType = .none
            return cell
        }
    }

    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        /*case .snooze, .bluetoothDeviceSelect:
            return nil*/
        case .sensorInfo:
            return LocalizedString("Sensor Info", comment: "Section title for latest sensor info")
        case .latestReading:
            return LocalizedString("Latest Reading", comment: "Section title for latest glucose reading")
        case .delete:
            return nil
        case .latestBridgeInfo:
            return LocalizedString("Transmitter info", comment: "Section title for transmitter info")
        case .latestCalibrationData:
            return LocalizedString("Factory Calibration Parameters", comment: "Section title for Factory Calibration Parameters")

        case .advanced:
            return LocalizedString("Advanced", comment: "Advanced Section")
        case .snooze:
            return nil
        }
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch Section(rawValue: indexPath.section)! {
        /*case .bluetoothDeviceSelect:
            let vc = BluetoothSelection.asHostedViewController()
            show(vc, sender: nil)
        */

        case .latestReading:
            tableView.deselectRow(at: indexPath, animated: true)
        case .delete:
            let confirmVC = UIAlertController(cgmDeletionHandler: {
                NSLog("dabear:: confirmed: cgmmanagerwantsdeletion")
                if let cgmManager = self.cgmManager {
                    cgmManager.disconnect()

                    cgmManager.notifyDelegateOfDeletion {
                        DispatchQueue.main.async {
                            self.complete()
                            self.cgmManager = nil
                        }
                    }
                }
            })

            present(confirmVC, animated: true) {
                tableView.deselectRow(at: indexPath, animated: true)
            }
        case .latestBridgeInfo:
            tableView.deselectRow(at: indexPath, animated: true)
        case .latestCalibrationData:

            if LatestCalibrationDataInfoRow(rawValue: indexPath.row)! == .edit {
                if UserDefaults.standard.dangerModeActivated {
                    //ok
                    print("user can edit calibrations")
                    let controller = CalibrationEditTableViewController(cgmManager: self.cgmManager)
                    controller.disappearDelegate = self
                    self.show(controller, sender: self)
                } else {
                    self.presentStatus(OKAlertController("Could not access calibration settings, danger mode was not activated!", title: "No can do!"))
                }
                tableView.deselectRow(at: indexPath, animated: true)
                return
            }

            let confirmVC = UIAlertController(calibrateHandler: {
                if let cgmManager = self.cgmManager {
                    /*guard let (accessToken, url) = cgmManager.keychain.getAutoCalibrateWebCredentials() else {
                        NSLog("dabear:: could not calibrate, accesstoken or url was nil")
                        self.presentStatus(OKAlertController(LibreError.invalidAutoCalibrationCredentials.errorDescription, title: "Error"))

                        return
                    }*/

                    guard let data = cgmManager.lastValidSensorData else {
                        NSLog("No sensordata was present, unable to recalibrate!")
                        self.presentStatus(OKAlertController(LibreError.noSensorData.errorDescription, title: "Error"))

                        return
                    }
                    let params = data.calibrationData

                    do {
                        try self.cgmManager?.keychain.setLibreNativeCalibrationData(params)
                    } catch {
                        NSLog("dabear:: could not save calibrationdata")
                        self.presentOKStatusOnMain(LibreError.invalidCalibrationData.errorDescription, title: "Error")
                        return
                    }

                    self.presentOKStatusOnMain("Calibration Success", title: "Calibration Status")
                }
            })

            present(confirmVC, animated: true) {
                tableView.deselectRow(at: indexPath, animated: true)
            }

        case .sensorInfo:
            tableView.deselectRow(at: indexPath, animated: true)
        case .advanced:
            tableView.deselectRow(at: indexPath, animated: true)

            switch AdvancedSettingsRow(rawValue: indexPath.row)! {
            case .alarms:
                let controller = AlarmSettingsTableViewController(glucoseUnit: self.glucoseUnit)
                controller.disappearDelegate = self
                show(controller, sender: nil)
            case .glucoseNotifications:
                let controller = NotificationsSettingsTableViewController(cgmManager: self.cgmManager!, glucoseUnit: self.glucoseUnit)
                controller.disappearDelegate = self
                show(controller, sender: nil)
            case .dangermode:
                if UserDefaults.standard.dangerModeActivated {
                    UserDefaults.standard.dangerModeActivated = false
                    let dangerCellIndex = IndexPath(row: AdvancedSettingsRow.dangermode.rawValue, section: Section.advanced.rawValue)
                    let editCellIndex = IndexPath(row: LatestCalibrationDataInfoRow.edit.rawValue, section: Section.latestCalibrationData.rawValue)
                    self.tableView.reloadRows(at: [dangerCellIndex, editCellIndex], with: .none)
                } else {
                    let team = bundleSeedID() ?? "Unknown???!"
                    let msg = "To activate dangermode, please input your team identifier. It is important that you take an active choice here, so don't copy/paste but type it in correctly. Your team identifer is: \(team)"

                    let controller = InputAlertController(msg, title: "Activate danger mode", inputPlaceholder: "Confirm your team identifer") { [weak self] isOk, controller in
                        self?.dangerModeActivation(isOk, controller: controller)
                    }
                    self.presentStatus(controller)
                }
            case .glucose:
                let controller = GlucoseSettingsTableViewController(glucoseUnit: self.glucoseUnit)
                controller.disappearDelegate = self
                show(controller, sender: nil)
            }

        case .snooze:
            print("Snooze called")

            //let controller = SnoozeTableViewController(manager: self.cgmManager)

            let container = SwiftSnoozeView.asHostedViewController(manager: self.cgmManager)

            self.show(container, sender: nil)
            //present(controller, sender: nil)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    func presentStatus(_ controller: UIAlertController) {
        self.present(controller, animated: true) {
            NSLog("calibrationstatus shown")
        }
    }

    func presentOKStatusOnMain(_ message: String, title: String) {
        DispatchQueue.main.async { [weak self] in
            let controller = OKAlertController(message, title: title)
            self?.presentStatus(controller)
        }
    }
}

private extension UIAlertController {
    convenience init(cgmDeletionHandler handler: @escaping () -> Void) {
        self.init(
            title: nil,
            message: LocalizedString("Are you sure you want to delete this CGM?", comment: "Confirmation message for deleting a CGM"),
            preferredStyle: .actionSheet
        )

        addAction(UIAlertAction(
            title: LocalizedString("Delete CGM", comment: "Button title to delete CGM"),
            style: .destructive,
            handler: { _ in
                handler()
            }
        ))

        let cancel = LocalizedString("Cancel", comment: "The title of the cancel action in an action sheet")
        addAction(UIAlertAction(title: cancel, style: .cancel, handler: nil))
    }
    convenience init(calibrateHandler handler: @escaping () -> Void) {
        self.init(
            title: nil,
            message: LocalizedString("Are you sure you want to recalibrate this sensor?", comment: "Confirmation message for recalibrate sensor"),
            preferredStyle: .actionSheet
        )

        addAction(UIAlertAction(
            title: LocalizedString("Recalibrate", comment: "Button title to recalibrate"),
            style: .destructive,
            handler: { _ in
                handler()
            }
        ))

        let cancel = LocalizedString("Cancel", comment: "The title of the cancel action in an action sheet")
        addAction(UIAlertAction(title: cancel, style: .cancel, handler: nil))
    }
}
