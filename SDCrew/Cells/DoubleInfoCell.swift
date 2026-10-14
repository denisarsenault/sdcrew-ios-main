//
//  DoubleInfoCell.swift
//  SDCrew
//
//  Created by Denis Arsenault on 8/18/19.
//  Copyright © 2019 Satcom Direct, Inc. All rights reserved.
//

import UIKit

class DoubleInfoCell: UITableViewCell,UITextFieldDelegate {
    @IBOutlet weak var leftParentView: UIView!
    
    @IBOutlet weak var rightParentView: UIView!
    @IBOutlet weak var refreshBtn: UIButton!
    @IBOutlet weak var firstTitle: UILabel!
    @IBOutlet weak var secTitle: UILabel!
    @IBOutlet weak var firstNote: UILabel!
    @IBOutlet weak var firstInfoTextField: UITextField!
    @IBOutlet weak var secInfoTextField: UITextField!
    @IBOutlet weak var secNote: UILabel!
    

    @IBOutlet weak var leftRefreshBtn: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        leftParentView.layer.cornerRadius = 5
        leftParentView.layer.borderColor = UIColor.white.cgColor
        leftParentView.layer.borderWidth = 1
        leftParentView.layer.masksToBounds = true
        
        rightParentView.layer.cornerRadius = 5
        rightParentView.layer.borderColor = UIColor.white.cgColor
        rightParentView.layer.borderWidth = 1
        rightParentView.layer.masksToBounds = true
        firstInfoTextField.delegate = self
        secInfoTextField.delegate = self
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBAction func refreshBtnPressed(_ sender: Any) {
    }
    
}
