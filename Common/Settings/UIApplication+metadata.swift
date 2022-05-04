//
//  UIApplication+metadata.swift
//  MiaomiaoClient
//
//  Created by Bjørn Inge Berg on 30/12/2019.
//  Copyright © 2019 Bjørn Inge Berg. All rights reserved.
//

import Foundation


public enum AppMetaData {
    public static var allProperties: String = "unknown"

}

extension Bundle {
    static var current: Bundle {
        class Helper { }
        return Bundle(for: Helper.self)
    }
}
