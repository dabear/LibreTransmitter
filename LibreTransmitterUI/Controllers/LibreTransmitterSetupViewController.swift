//
//  MiaomiaoClientSetupViewController.swift
//  Loop
//
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import Combine


import LibreTransmitter
import SwiftUI
import UIKit
import os.log

class LibreTransmitterSetupViewController: UINavigationController, CGMManagerCreateNotifying, CGMManagerOnboardNotifying, CompletionNotifying {
    weak var cgmManagerCreateDelegate: CGMManagerCreateDelegate?
    weak var cgmManagerOnboardDelegate: CGMManagerOnboardDelegate?
    weak var completionDelegate: CompletionDelegate?

    fileprivate var logger = Logger.init(subsystem: "no.bjorninge.libre", category: "LibreTransmitterSetupViewController")

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
        logger.debug("dabear MiaomiaoClientSetupViewController() deinit was called")
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
            cgmManagerCreateDelegate?.cgmManagerCreateNotifying(didCreateCGMManager: cgmManager)
            cgmManagerOnboardDelegate?.cgmManagerOnboardNotifying(didOnboardCGMManager: cgmManager)

            if let newDevice = deviceSelect.rootView.getNewDeviceId() {
                logger.debug("dabear: Setupcontroller will set new device to \(newDevice)")
                UserDefaults.standard.preSelectedDevice = newDevice
            }

            stopScan()
        }
        completionDelegate?.completionNotifyingDidComplete(self)
    }
}
