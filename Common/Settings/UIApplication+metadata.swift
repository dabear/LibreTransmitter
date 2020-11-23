//
//  UIApplication+metadata.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 30/12/2019.
//  Copyright © 2019 Bjørn Inge Berg. All rights reserved.
//

import Foundation

private let prefix = "no-bjorninge-mm"
enum AppMetaData {
    static var allProperties: String {
        Bundle.current.infoDictionary?.compactMap {
            $0.key.starts(with: prefix) ? "\($0.key): \($0.value)" : nil
        }.joined(separator: "\n") ?? "none"
    }
}

extension Bundle {
    static var current: Bundle {
        class Helper { }
        return Bundle(for: Helper.self)
    }
}
