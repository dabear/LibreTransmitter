//
//  GlucoseTrend2.swift
//  LibreTransmitter
//
//  Created by Bjørn Inge Berg on 11/07/2021.
//  Copyright © 2021 Mark Wilson. All rights reserved.
//

import Foundation
#if !canImport(LoopKit) && !canImport(LoopKitUI)
public enum GlucoseTrend: Int, CaseIterable {
    case upUpUp       = 1
    case upUp         = 2
    case up           = 3
    case flat         = 4
    case down         = 5
    case downDown     = 6
    case downDownDown = 7

    public var symbol: String {
        switch self {
        case .upUpUp:
            return "⇈"
        case .upUp:
            return "↑"
        case .up:
            return "↗︎"
        case .flat:
            return "→"
        case .down:
            return "↘︎"
        case .downDown:
            return "↓"
        case .downDownDown:
            return "⇊"
        }
    }

    public var arrows: String {
        switch self {
        case .upUpUp:
            return "↑↑"
        case .upUp:
            return "↑"
        case .up:
            return "↗︎"
        case .flat:
            return "→"
        case .down:
            return "↘︎"
        case .downDown:
            return "↓"
        case .downDownDown:
            return "↓↓"
        }
    }

    public var localizedDescription: String {
        switch self {
        case .upUpUp:
            return LocalizedString("Rising very fast", comment: "Glucose trend up-up-up")
        case .upUp:
            return LocalizedString("Rising fast", comment: "Glucose trend up-up")
        case .up:
            return LocalizedString("Rising", comment: "Glucose trend up")
        case .flat:
            return LocalizedString("Flat", comment: "Glucose trend flat")
        case .down:
            return LocalizedString("Falling", comment: "Glucose trend down")
        case .downDown:
            return LocalizedString("Falling fast", comment: "Glucose trend down-down")
        case .downDownDown:
            return LocalizedString("Falling very fast", comment: "Glucose trend down-down-down")
        }
    }
}

#endif

