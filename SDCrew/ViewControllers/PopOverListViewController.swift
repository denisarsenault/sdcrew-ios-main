//
//  PopOverListViewController.swift
//  Bombardier_Voice
//
//  Created by Denis Arsenault on 8/8/18.
//  Copyright © 2018 Satcom Direct Technologies Ltd. All rights reserved.
//

import UIKit

public protocol PopOverListDelegate {
    func itemSelected(index:Int)

}

class PopOverListViewController: UITableViewController {

    var delegate:PopOverListDelegate?
    
    var itemNames:NSMutableArray = NSMutableArray()
    var rowHeight:Int = 44
    var optionView:UIView?
    var selectedIndex:Int = 0
    var groupNumber:Int = 0

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = #colorLiteral(red: 0.01960784314, green: 0.1098039216, blue: 0.2666666667, alpha: 1)
        
        
        
        if itemNames.count == 0{
            
            itemNames.add("")

        }
        

        var maxRow = 10
        if(itemNames.count < maxRow ){
            maxRow = itemNames.count
        }
        let tableHeight = CGFloat( rowHeight) * CGFloat( maxRow);
        
        
        if let presentationController = self.popoverPresentationController , let parentView = optionView{
            let globalPoint = parentView.superview?.convert(parentView.frame.origin, to: nil)
            let originX = (globalPoint?.x)! + parentView.bounds.width/2
            let originY = (globalPoint?.y)! + tableHeight / 2
            self.preferredContentSize = CGSize(width: parentView.bounds.width, height: tableHeight)
            presentationController.permittedArrowDirections =  UIPopoverArrowDirection(rawValue: 0) //[.up] //[.up, .down]
            presentationController.sourceRect = CGRect(x:originX , y:originY , width: 1, height: 1)
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        self.view.superview?.layer.cornerRadius = 5
        self.view.superview?.layer.borderWidth = 1
        self.view.superview?.layer.borderColor = UIColor.white.cgColor
        self.view.superview?.layer.masksToBounds = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
         self.tableView.scrollToRow(at: IndexPath(row: selectedIndex, section: 0), at: .middle, animated: true)
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(rowHeight)
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return (itemNames.count)
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "popUpCell")
        
        let currentItemName = itemNames.object(at: indexPath.row) as? String
        cell.textLabel?.text = currentItemName
        cell.textLabel?.textColor = UIColor.white
        //cell.textLabel?.textAlignment = .center
        cell.textLabel?.font = UIFont.systemFont(ofSize: 15)
        cell.backgroundColor = #colorLiteral(red: 0.01960784314, green: 0.1098039216, blue: 0.2666666667, alpha: 1)
        return cell
    }


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.dismiss(animated: true, completion: {
            self.delegate?.itemSelected(index: indexPath.row)
        })
    }

}

