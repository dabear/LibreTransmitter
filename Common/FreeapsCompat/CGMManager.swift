//
//  CGMManager.swift
//  LibreTransmitter
//
//  Created by Bjørn Inge Berg on 11/07/2021.
//  Copyright © 2021 Mark Wilson. All rights reserved.
//

import Foundation
#if !canImport(LoopKit) && !canImport(LoopKitUI)
public protocol CGMManager {
     typealias RawStateValue = [AnyHashable : Any]
    typealias NotifyCallback = ()->Void

    func notifyDelegateOfDeletion(_ callback: NotifyCallback)

}
public extension CGMManager {
    func notifyDelegateOfDeletion(_ callback: NotifyCallback) {
        //do nothing
    }
}


public struct CGMManagerStatus {
    public var hasValidSensorSession: Bool = true

}

public enum Alert {
    public typealias Sound = String
    public typealias AlertIdentifier = String
}

public protocol CGMManagerDelegate {
    /// Asks the delegate for a date with which to filter incoming glucose data
    ///
    /// - Parameter manager: The manager instance
    /// - Returns: The date data occuring on or after which should be kept
    func startDateToFilterNewData(for manager: CGMManager) -> Date?

    /// Informs the delegate that the device has updated with a new result
    ///
    /// - Parameters:
    ///   - manager: The manager instance
    ///   - result: The result of the update
    func cgmManager(_ manager: CGMManager, hasNew readingResult: CGMReadingResult) -> Void

    /// Informs the delegate that the manager is deactivating and should be deleted
    ///
    /// - Parameter manager: The manager instance
    func cgmManagerWantsDeletion(_ manager: CGMManager)

    /// Informs the delegate that the manager has updated its state and should be persisted.
    ///
    /// - Parameter manager: The manager instance
    func cgmManagerDidUpdateState(_ manager: CGMManager)

    /// Asks the delegate for credential store prefix to avoid namespace conflicts
    ///
    /// - Parameter manager: The manager instance
    /// - Returns: The unique prefix for the credential store
    func credentialStoragePrefix(for manager: CGMManager) -> String
}

public class WeakSynchronizedDelegate<Delegate> {

    private var _queue: DispatchQueue

    public init(queue: DispatchQueue = .main) {
        _queue = queue
    }

    public var delegate: Delegate? {
        get{
            nil
        }
        set {

        }
    }

    public var queue: DispatchQueue! {
        get {
            _queue

        }
        set {
            _queue = newValue
        }
    }
}


public enum CGMReadingResult {
    case noData
    case unreliableData
    case newData([NewGlucoseSample])
    case error(Error)
}

public protocol DeviceStatusBadge {}

public protocol BluetoothProvider {}

public protocol DeviceStatusHighlight {}
public protocol DeviceLifecycleProgress {}

public protocol CGMManagerUI {}

public protocol LoopUIColorPalette {}

public protocol CGMManagerOnboardNotifying {
    /// Delegate to notify about cgm manager onboarding.
    var cgmManagerOnboardDelegate: CGMManagerOnboardDelegate? { get set }
}

class CGMManagerSettingsNavigationViewController: UIViewController, CGMManagerOnboardNotifying, CompletionNotifying {
    var completionDelegate: CompletionDelegate?


    open weak var cgmManagerOnboardDelegate: CGMManagerOnboardDelegate?

    func notifySetup(cgmManager: CGMManagerUI) {
        cgmManagerOnboardDelegate?.cgmManagerOnboardNotifying(didOnboardCGMManager: cgmManager)
    }
    init(rootViewController: AnyObject) {
        //do notning
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func notifyComplete() {}

    func notifyDelegateOfDeletion(){}

}

public enum SetupUIResult<UserInteractionRequired, CreatedAndOnboarded> {
    case userInteractionRequired(UserInteractionRequired)
    case createdAndOnboarded(CreatedAndOnboarded)
}

public protocol CompletionNotifying {
    var completionDelegate: CompletionDelegate? { set get }
}


public protocol CompletionDelegate: class {
    func completionNotifyingDidComplete(_ object: CompletionNotifying)
}

public protocol DeviceManagerUI {
    /// An image representing a device configuration after it is set up
    var smallImage: UIImage? { get }
}

public protocol CGMManagerCreateDelegate: AnyObject {
    /// Informs the delegate that the specified cgm manager was created.
    ///
    /// - Parameters:
    ///     - cgmManager: The cgm manager created.
    func cgmManagerCreateNotifying(didCreateCGMManager cgmManager: CGMManagerUI)
}

public protocol CGMManagerCreateNotifying {
    /// Delegate to notify about cgm manager creation.
    var cgmManagerCreateDelegate: CGMManagerCreateDelegate? { get set }
}

public protocol CGMManagerOnboardDelegate: AnyObject {
    /// Informs the delegate that the specified cgm manager was onboarded.
    ///
    /// - Parameters:
    ///     - cgmManager: The cgm manager onboarded.
    func cgmManagerOnboardNotifying(didOnboardCGMManager cgmManager: CGMManagerUI)
}


#endif

