//
//  MiaomiaoClientSetupViewController.swift
//  Loop
//
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import Combine
import LoopKit
import LoopKitUI
import LibreTransmitter
import SwiftUI
import UIKit

class LibreTransmitterSetupViewController: UINavigationController, CGMManagerSetupViewController, CompletionNotifying {
    weak var completionDelegate: CompletionDelegate?

    // this must follow the protocol from loopkit, so it cannot be weak
    // swiftlint:disable:next weak_delegate
    var setupDelegate: CGMManagerSetupViewControllerDelegate?

    lazy var cgmManager: LibreTransmitterManager? =  LibreTransmitterManager()

    var deviceSelect: UIHostingController<BluetoothSelection>!

    init() {
        SelectionState.shared.selectedStringIdentifier = UserDefaults.standard.preSelectedDevice

        deviceSelect = BluetoothSelection.asHostedViewController()

        super.init(rootViewController: deviceSelect)

        deviceSelect.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        deviceSelect.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    deinit {
        NSLog("dabear MiaomiaoClientSetupViewController() deinit was called")
        //cgmManager = nil
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func stopScan() {
        var v = deviceSelect.rootView
        v.stopScan(true)
        deviceSelect = nil
    }

    @objc
    private func cancel() {
        completionDelegate?.completionNotifyingDidComplete(self)

        stopScan()
    }

    @objc
    private func save() {
        if let cgmManager = cgmManager {
            setupDelegate?.cgmManagerSetupViewController(self, didSetUpCGMManager: cgmManager)

            if let newDevice = deviceSelect.rootView.getNewDeviceId() {
                print("dabear: Setupcontroller will set new device to \(newDevice)")
                UserDefaults.standard.preSelectedDevice = newDevice
            }

            stopScan()
        }
        completionDelegate?.completionNotifyingDidComplete(self)
    }
}
