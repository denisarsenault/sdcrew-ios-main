//
//  MeasurementCell.swift
//  SDCrew
//
//  Created by Izaz Uddin Roman on 21/8/19.
//  Copyright © 2019 Satcom Direct, Inc. All rights reserved.
//

import UIKit

protocol MeasurementCellDelegate {
    func unitSegmentPressed(sender:UISegmentedControl,prevUnit:Int) -> Void
}

class MeasurementCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var unitSegment: UISegmentedControl!
    var delegate:MeasurementCellDelegate?
    var currentUnit:Int = 0
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBAction func segmentPressed(_ sender: UISegmentedControl) {
        delegate?.unitSegmentPressed(sender: sender, prevUnit: currentUnit)
        currentUnit = sender.selectedSegmentIndex
    }
    
}
