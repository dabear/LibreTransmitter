//
//  LoggerExtension.swift
//  LibreTransmitter
//
//  Created by Bjørn Inge Berg on 19/01/2023.
//  Copyright © 2023 Mark Wilson. All rights reserved.
//

import Foundation
import OSLog

public extension Logger {
    init(forType atype: Any) {
        self.init(subsystem: Features.logSubsystem, category: String(describing: atype))
    }
}
