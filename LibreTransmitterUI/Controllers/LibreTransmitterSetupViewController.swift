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
import os.log

class LibreTransmitterSetupViewController: UINavigationController, CGMManagerOnboarding, CompletionNotifying {
    weak var cgmManagerOnboardingDelegate: CGMManagerOnboardingDelegate?
    weak var completionDelegate: CompletionDelegate?

    fileprivate lazy var logger = Logger(forType: Self.self)

    lazy var cgmManager: LibreTransmitterManagerV2? =  LibreTransmitterManagerV2()

    var modeSelection: UIHostingController<ModeSelectionView>!

    init() {
        SelectionState.shared.selectedStringIdentifier = UserDefaults.standard.preSelectedDevice

        let cancelNotifier = GenericObservableObject()
        let saveNotifier = GenericObservableObject()

        modeSelection = UIHostingController(rootView: ModeSelectionView(cancelNotifier: cancelNotifier, saveNotifier: saveNotifier))

        super.init(rootViewController: modeSelection)

        cancelNotifier.listenOnce { [weak self] in
            self?.cancel()
        }

        saveNotifier.listenOnce { [weak self] in
            self?.save()
        }

    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    deinit {
        logger.debug("LibreTransmitterSetupViewController() deinit was called")
        // cgmManager = nil
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func cancel() {
        completionDelegate?.completionNotifyingDidComplete(self)

    }

    @objc
    private func save() {

        let hasNewDevice = SelectionState.shared.selectedStringIdentifier != UserDefaults.standard.preSelectedDevice
        if hasNewDevice, let newDevice = SelectionState.shared.selectedStringIdentifier {
            logger.debug("Setupcontroller will set new device to \(newDevice)")
            UserDefaults.standard.preSelectedDevice = newDevice
            SelectionState.shared.selectedUID = nil
            UserDefaults.standard.preSelectedUid = nil

        } else if let newUID = SelectionState.shared.selectedUID {
            // this one is only temporary,
            // as we don't know the bluetooth identifier during nfc setup
            logger.debug("Setupcontroller will set new libre2 device  to \(newUID)")

            UserDefaults.standard.preSelectedUid = newUID
            SelectionState.shared.selectedUID = nil
            UserDefaults.standard.preSelectedDevice = nil

        } else {

            // this cannot really happen unless you are a developer and have previously
            // stored both preSelectedDevice and selectedUID !
        }

        if let cgmManager {
            logger.debug("Setupcontroller Saving from setup")
            cgmManagerOnboardingDelegate?.cgmManagerOnboarding(didCreateCGMManager: cgmManager)
            cgmManagerOnboardingDelegate?.cgmManagerOnboarding(didOnboardCGMManager: cgmManager)

        } else {
            logger.debug("Setupcontroller not Saving from setup")
        }

        completionDelegate?.completionNotifyingDidComplete(self)
    }
}
