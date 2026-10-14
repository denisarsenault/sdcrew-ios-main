//
//  TrackAndHoldCell.swift
//  SDCrew
//
//  Created by Izaz Uddin Roman on 19/8/19.
//  Copyright © 2019 Satcom Direct, Inc. All rights reserved.
//

import UIKit

class TrackAndHoldCell: UITableViewCell {

    @IBOutlet weak var trackSwitch: UISwitch!
    @IBOutlet weak var holdSwitch: UISwitch!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
