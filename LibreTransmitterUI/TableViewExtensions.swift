//
//  TableViewExtensions.swift
//  LibreTransmitterUI
//
//  Created by Bjørn Inge Berg on 04/06/2021.

import Foundation
import UIKit

extension UITableViewCell: IdentifiableClass { }

extension UITableView {
    func dequeueIdentifiableCell<T: UITableViewCell>(cell: T.Type, for indexPath: IndexPath) -> T {
        // swiftlint:disable:next force_cast
        self.dequeueReusableCell(withIdentifier: T.className, for: indexPath) as! T
    }
}

