//
//  NotesCell.swift
//  SDCrew
//
//  Created by Denis Arsenault on 8/22/19.
//  Copyright © 2019 Satcom Direct. All rights reserved.
//

import UIKit

protocol NotesCellDelegate {
    func changeHeightOfNotesCell(extraHeight:Double) -> Bool
}

class NotesCell: UITableViewCell,UITextViewDelegate {

    @IBOutlet weak var resizeICon: UIImageView!
    @IBOutlet weak var noteTextField: UITextView!
    public var delegate:NotesCellDelegate?
    private var initialCenter:CGPoint!
    private var initialHeight:CGFloat!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        noteTextField.layer.borderWidth = 1
        noteTextField.layer.borderColor = UIColor.white.cgColor
        noteTextField.layer.masksToBounds = true
        noteTextField.delegate = self
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        self.resizeICon.addGestureRecognizer(panGesture)
        
        initialHeight = self.noteTextField.frame.height
    }
    
    @objc func handlePanGesture(_ gesture:UIPanGestureRecognizer){
        //if gesture.view != resizeICon {return}
        let currentLoc = gesture.location(in: self.contentView)
        if gesture.state == .began{
             print("pan gesture began")
            initialCenter = currentLoc
        }else if gesture.state == .changed{
             print("pan gesture changed")
            let currentLoc = gesture.location(in: self.contentView)
            let extraHeight = currentLoc.y - initialCenter.y
            var frame = self.noteTextField.frame
            frame.size.height = frame.size.height + extraHeight
            
            let success = delegate?.changeHeightOfNotesCell(extraHeight: Double(extraHeight))
            if success ?? false {
                self.noteTextField.frame = frame
            }
        }else if gesture.state == .cancelled{
            print("pan gesture cancelled")
        }
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool{
        self.noteTextField.isScrollEnabled = false
        return true
    }
    func textViewDidBeginEditing(_ textView: UITextView){
        //self.noteTextField.isScrollEnabled = true
    }
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool{
        textView.resignFirstResponder()
        return true
    }
//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//
//    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
