//
//  CollectionExtensions.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 26/03/2019.
//  Copyright © 2019 Bjørn Inge Berg. All rights reserved.
//

import Foundation

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension Array {
    public mutating func safeIndexAt(_ index: Int, default defaultValue: @autoclosure () -> Element) -> Element? {
        guard index >= 0, index < endIndex else {
            var val: Element?
            while !indices.contains(index) {
                val = defaultValue()
                if let val = val {
                    self.append(val)
                } else {
                    //unsafe to continue as this might be a never ending loop
                    break
                }
            }

            return val
        }

        return self[index]
    }
}

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var addedDict = [Element: Bool]()

        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }

    mutating func removeDuplicates() {
        self = self.removingDuplicates()
    }
}
