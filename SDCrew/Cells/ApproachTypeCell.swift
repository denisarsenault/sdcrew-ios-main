//
//  ApproachTypeCell.swift
//  SDCrew
//
//  Created by Izaz Uddin Roman on 21/8/19.
//  Copyright © 2019 Satcom Direct, Inc. All rights reserved.
//

import UIKit
import DLRadioButton
protocol ApproachTypeCellDelegate{
    func removeApproachButtonTapped(indexPath: IndexPath)
}

class ApproachTypeCell: UITableViewCell,PopOverListDelegate {

    
    
    var delegate: ApproachTypeCellDelegate?
    var indexPath:IndexPath!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var optionLabel: UILabel!
    @IBOutlet weak private var dropDownView: UIView!
    @IBOutlet weak var evsCheckbox: DLRadioButton!
    @IBOutlet weak private var dropDownIcon: UIImageView!
    var itemNames:NSMutableArray = NSMutableArray(array: ["ASR","SVG","CDC","AMC"])
    private var popoverContent:PopOverListViewController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        dropDownView.layer.cornerRadius = 5
        dropDownView.layer.borderColor = UIColor.white.cgColor
        dropDownView.layer.borderWidth = 1
        dropDownView.layer.masksToBounds = true
        setTitle(title: "Approach Type", extens: nil)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dropDownPressed(gesture:)))
        self.dropDownView.addGestureRecognizer(tapGesture)
        self.dropDownView.tag = 0
        evsCheckbox.layer.cornerRadius = 5
        evsCheckbox.layer.masksToBounds = true
        evsCheckbox.animationDuration = 0
        evsCheckbox.isMultipleSelectionEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(dissmissPopOver), name: NSNotification.Name(rawValue: "DissmissApproachPopOver"), object: nil)
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
    
    @objc func dropDownPressed(gesture:UITapGestureRecognizer) -> Void {
        if self.dropDownView.tag == 0{
            self.dropDownIcon.image = #imageLiteral(resourceName: "upArrow")
            self.dropDownView.tag = 1
            
            popoverContent = PopOverListViewController(style: .plain)
            popoverContent?.itemNames = itemNames
            popoverContent?.delegate = self
            popoverContent?.modalPresentationStyle = .popover
            popoverContent?.optionView = self.dropDownView
            
            if let viewController:UIViewController = delegate as? UIViewController{
                if let popover = popoverContent?.popoverPresentationController {
                    popover.sourceView = viewController.view
                    popover.delegate = viewController as? UIPopoverPresentationControllerDelegate
                }
                viewController.present(popoverContent!, animated: true, completion: nil)
            }
            
            
        }else{
            
        }
    }
    
    @objc func dissmissPopOver() -> Void {
        if self.dropDownView.tag == 1{
            self.dropDownView.tag = 0
            self.dropDownIcon.image = #imageLiteral(resourceName: "downArrow")
        }
    }
    
    func itemSelected(index: Int) {
        self.optionLabel.text = itemNames[index] as? String
        dissmissPopOver()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func removeBtnPressed(_ sender: UIButton) {
        delegate?.removeApproachButtonTapped(indexPath: indexPath)
    }
    
    @IBAction func evsCheckBoxPressed(_ sender: Any) {
        
        
    }
    


}

extension FlightDetailsViewController:UIPopoverPresentationControllerDelegate{
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "DissmissApproachPopOver"), object: nil)
    }
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        
        return UIModalPresentationStyle.none
    }
}
