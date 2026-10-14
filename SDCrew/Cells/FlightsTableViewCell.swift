//
//  FlightsTableViewCell.swift
//  Test
//
//  Created by Izaz Uddin Roman on 18/8/19.
//  Copyright © 2019 Satcom Direct, Inc. All rights reserved.
//

import UIKit

class FlightsTableViewCell: UITableViewCell {
    
    //MARK:- Outlets
    @IBOutlet weak var flightNameLbl: UILabel!
    @IBOutlet weak var flightSourceLbl: UILabel!
    @IBOutlet weak var flightDestinationLbl: UILabel!
    @IBOutlet weak var takeOffDateLbl: UILabel!
    @IBOutlet weak var tripIdLbl: UILabel!
    @IBOutlet weak var landingDateLbl: UILabel!
    @IBOutlet weak var aircraftImg: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.cornerRadius = 6.0
        self.layer.borderWidth = 1.0
        self.layer.borderColor = #colorLiteral(red: 0, green: 0.1098039216, blue: 0.2705882353, alpha: 1)
        self.clipsToBounds = true

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
