//
//  ApproachesCell.swift
//  SDCrew
//
//  Created by Izaz Uddin Roman on 21/8/19.
//  Copyright © 2019 Satcom Direct, Inc. All rights reserved.
//

import UIKit

protocol ApproachCellDelegate{
    func addApproachButtonTapped(indexPath: IndexPath)
}

class ApproachesCell: UITableViewCell {
    
    @IBOutlet weak var approachBtn: UIButton!
    var delegate: ApproachCellDelegate?
    var indexPath:IndexPath!
    
    @IBAction func addApproachBtn(_ sender: UIButton) {
        delegate?.addApproachButtonTapped(indexPath: indexPath)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        approachBtn.layer.cornerRadius = 5
        approachBtn.layer.masksToBounds = true
        approachBtn.setTitle("  Add Approach ⊕  ", for: .normal)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
