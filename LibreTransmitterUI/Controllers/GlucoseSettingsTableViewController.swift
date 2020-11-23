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

public class GlucoseSettingsTableViewController: UITableViewController, mmTextFieldViewCellCellDelegate {
    func mmTextFieldViewCellDidUpdateValue(_ cell: MMTextFieldViewCell, value: String?) {
    }

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

    private enum GlucoseSettings: Int, CaseIterable {
        case syncToNs
        case backfillFromHistory
        case backfillFromTrend

        case persistRawSensorDataForDebugging

        static let count = GlucoseSettings.allCases.count
    }

    override public func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        GlucoseSettings.count
    }

    @objc
    private func syncToNsChanged(_ sender: UISwitch) {
        print("syncToNsChanged changed to \(sender.isOn)")
        UserDefaults.standard.mmSyncToNs = sender.isOn
    }

    @objc
    private func backfillFromTrendChanged(_ sender: UISwitch) {
        print("mmBackfillFromTrend changed to \(sender.isOn)")
        UserDefaults.standard.mmBackfillFromTrend = sender.isOn
    }

    @objc
    private func backfillFromHistoryChanged(_ sender: UISwitch) {
        print("backfillFromHistory changed to \(sender.isOn)")
        UserDefaults.standard.mmBackfillFromHistory = sender.isOn
    }

    @objc
    private func persistSensorDataChanged(_ sender: UISwitch) {
        print("persistSensorDataChanged changed to \(sender.isOn)")
        UserDefaults.standard.shouldPersistSensorData = sender.isOn
        if !sender.isOn {
            UserDefaults.standard.queuedSensorData = nil
        }
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let switchCell = tableView.dequeueIdentifiableCell(cell: MMSwitchTableViewCell.self, for: indexPath)

        switch GlucoseSettings(rawValue: indexPath.row)! {
        case .backfillFromHistory:
            switchCell.toggleIsSelected?.isOn = UserDefaults.standard.mmBackfillFromHistory
            switchCell.titleLabel?.text = NSLocalizedString("Backfill from history", comment: "The title text forbackfill from history setting")

            switchCell.toggleIsSelected?.addTarget(self, action: #selector(backfillFromHistoryChanged(_:)), for: .valueChanged)
        case .backfillFromTrend:
            switchCell.toggleIsSelected?.isOn = UserDefaults.standard.mmBackfillFromTrend
            switchCell.titleLabel?.text = NSLocalizedString("Backfill from trend", comment: "The title text forbackfill from trend setting")

            switchCell.toggleIsSelected?.addTarget(self, action: #selector(backfillFromTrendChanged(_:)), for: .valueChanged)
        case .syncToNs:

            switchCell.toggleIsSelected?.isOn = UserDefaults.standard.mmSyncToNs
            //switchCell.titleLabel?.text = "test"

            switchCell.titleLabel?.text = NSLocalizedString("Sync to Nightscout", comment: "The title text for the sync to nightscout setting")

            switchCell.toggleIsSelected?.addTarget(self, action: #selector(syncToNsChanged(_:)), for: .valueChanged)
        case .persistRawSensorDataForDebugging:
            switchCell.toggleIsSelected?.isOn = UserDefaults.standard.shouldPersistSensorData
            //switchCell.titleLabel?.text = "test"

            switchCell.titleLabel?.text = NSLocalizedString("Issue Report with sensordata", comment: "Persist sensordata in Issue Report")

            switchCell.toggleIsSelected?.addTarget(self, action: #selector(persistSensorDataChanged(_:)), for: .valueChanged)
        }

        switchCell.contentView.layoutMargins.left = tableView.separatorInset.left
        return switchCell
    }

    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        LocalizedString("Glucose settings", comment: "The title text for the glucose settings")
    }

    override public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        LocalizedString("Backfilling from trend will display glucose values for each of the 16 last minutes. Loop is not optimized for dealing with this scenario", comment: "The title text for the glucose settings")
    }

    override public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        true
    }

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let setting = String(describing: GlucoseSettings(rawValue: indexPath.row)!)

        print("Selected setting \(setting)")

        tableView.deselectRow(at: indexPath, animated: true)
    }
}
