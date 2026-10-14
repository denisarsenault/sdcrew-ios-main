//
//  FlightInfoCell.swift
//  SDCrew
//
//  Created by Denis Arsenault on 8/7/19.
//  Copyright © 2019 Satcom Direct, Inc. All rights reserved.
//

import UIKit

class BasicFlightInfoCell: UITableViewCell {

    @IBOutlet weak var endLoc: UILabel!
    @IBOutlet weak var startLoc: UILabel!
    @IBOutlet weak var flightTimeLbl: UILabel!
    @IBOutlet weak var blockTimeLbl: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
