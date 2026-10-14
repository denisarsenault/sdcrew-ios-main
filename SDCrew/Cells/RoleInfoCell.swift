//
//  RoleInfoCell.swift
//  SDCrew
//
//  Created by Izaz Uddin Roman on 19/8/19.
//  Copyright © 2019 Satcom Direct, Inc. All rights reserved.
//

import UIKit
import DLRadioButton

class RoleInfoCell: UITableViewCell {
    @IBOutlet weak var sicButton: DLRadioButton!
    @IBOutlet weak var picButton: DLRadioButton!
    @IBOutlet weak var nameLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        picButton.isMultipleSelectionEnabled = false
        picButton.otherButtons.append(sicButton)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBAction func radioBtnPressed(_ sender: Any) {
        print(sicButton.isSelected ? "SIC selected" : "PIC selected")
    }
    

}
