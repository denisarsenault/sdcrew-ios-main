//
//  SingleInfoCell.swift
//  SDCrew
//
//  Created by Denis Arsenault on 8/7/19.
//  Copyright © 2019 Satcom Direct, Inc. All rights reserved.
//

import UIKit

class SingleInfoCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var infoLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        parentView.layer.cornerRadius = 5
        parentView.layer.borderColor = UIColor.white.cgColor
        parentView.layer.borderWidth = 1
        parentView.layer.masksToBounds = true
        
    }

    func setTitle(title:String,extens:String?) -> Void {
        var labelText = " " + title + " "
        var attributedString = NSMutableAttributedString(string: labelText)
        
        if extens != nil{
            labelText = labelText + extens! + " "
            attributedString = NSMutableAttributedString(string: labelText)
            let range = NSString(string:labelText).range(of: extens!)
            attributedString.addAttribute(.foregroundColor, value: UIColor.red, range: range )
        }
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 12), range: NSString(string:labelText).range(of: labelText))
        self.titleLabel.attributedText = attributedString
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
