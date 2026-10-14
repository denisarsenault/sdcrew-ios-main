//
//  TakeoffsCell.swift
//  SDCrew
//
//  Created by Izaz Uddin Roman on 19/8/19.
//  Copyright © 2019 Satcom Direct, Inc. All rights reserved.
//

import UIKit

class TakeoffsCell: UITableViewCell {

    @IBOutlet weak var leftView: UIView!
    @IBOutlet weak var rightView: UIView!
    @IBOutlet weak var firstTitle: UILabel!
    @IBOutlet weak var secTitle: UILabel!
    @IBOutlet weak var firstValue: UILabel!
    @IBOutlet weak var secValue: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        leftView.layer.cornerRadius = 5
        leftView.layer.borderColor = UIColor.white.cgColor
        leftView.layer.borderWidth = 1
        leftView.layer.masksToBounds = true
        
        rightView.layer.cornerRadius = 5
        rightView.layer.borderColor = UIColor.white.cgColor
        rightView.layer.borderWidth = 1
        rightView.layer.masksToBounds = true
    }
    
    func setFirstTitle(title:String,extens:String?) -> Void {
        
        self.firstTitle.attributedText = getAttributedTitle(title: title, extens: extens)
        
    }
    
    func setSecTitle(title:String,extens:String?) -> Void {
        
        self.secTitle.attributedText = getAttributedTitle(title: title, extens: extens)
        
    }
    func getAttributedTitle(title:String,extens:String?) -> NSMutableAttributedString {
        var labelText = " " + title + " "
        var attributedString = NSMutableAttributedString(string: labelText)
        
        if extens != nil{
            labelText = labelText + extens! + " "
            attributedString = NSMutableAttributedString(string: labelText)
            let range = NSString(string:labelText).range(of: extens!)
            attributedString.addAttribute(.foregroundColor, value: UIColor.red, range: range )
        }
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 12), range: NSString(string:labelText).range(of: labelText))
        return attributedString
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBAction func firstMinPressed(_ sender: Any) {
        
    }
    @IBAction func firstPlusPressed(_ sender: Any) {
    }
    
    @IBAction func secMinPressed(_ sender: Any) {
    }
    @IBAction func secPlusPressed(_ sender: Any) {
    }
    
}
