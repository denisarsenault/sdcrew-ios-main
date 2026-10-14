//
//  BasicPilotInfoCell.swift
//  SDCrew
//
//  Created by Izaz Uddin Roman on 19/8/19.
//  Copyright © 2019 Satcom Direct, Inc. All rights reserved.
//

import UIKit

class BasicPilotInfoCell: UITableViewCell {

    @IBOutlet weak var pilotName: UILabel!
    @IBOutlet weak var takeOffDayLabel: UILabel!
    @IBOutlet weak var takeOffNightLbl: UILabel!
    @IBOutlet weak var landingDayLbl: UILabel!
    @IBOutlet weak var landingNightLbl: UILabel!
    @IBOutlet weak var pilotRoleLbl: UILabel!
    
    
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
   
}
