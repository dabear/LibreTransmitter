//
//  SegmentViewCell.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 15/05/2019.
//  Copyright © 2019 Bjørn Inge Berg. All rights reserved.
//

import UIKit

extension UISegmentedControl {
    func replaceSegments(segments: [String]) {
        self.removeAllSegments()
        for segment in segments {
            self.insertSegment(withTitle: segment, at: self.numberOfSegments, animated: false)
        }
    }
}

class SegmentViewCell: UITableViewCell {
    @IBOutlet weak var segment: UISegmentedControl!

    @IBOutlet weak var label: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
