//
//  View.swift
//  SDCrew
//
//  Created by Denis Arsenault on 8/18/19.
//  Copyright © 2019 Satcom Direct, Inc. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func roundCorners(corners: CACornerMask, radius: CGFloat) {
        self.clipsToBounds = true
        self.layer.cornerRadius = radius
        self.layer.maskedCorners = corners
    }
    func addBottomBorderWithColor(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x:0,y: self.frame.size.height - width, width:self.frame.size.width,height:  width)
        self.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        self.layer.addSublayer(border)
    }
}
