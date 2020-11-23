//
//  CGFLoat+Double.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 06/06/2019.
//  Copyright © 2019 Bjørn Inge Berg. All rights reserved.
//

import Foundation
import UIKit
func * (lhs: CGFloat, rhs: Double) -> Double {
    Double(lhs) * rhs
}

func * (lhs: CGFloat, rhs: Double) -> CGFloat {
    lhs * CGFloat(rhs)
}

func * (lhs: Double, rhs: CGFloat) -> Double {
    lhs * Double(rhs)
}

func * (lhs: Double, rhs: CGFloat) -> CGFloat {
    CGFloat(lhs) * rhs
}
