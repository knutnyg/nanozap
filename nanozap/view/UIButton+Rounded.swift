//
//  UIButton+Rounded.swift
//  nanozap
//
//  Created by Eivind Siqveland Larsen on 16/06/2018.
//  Copyright © 2018 Knut Nygaard. All rights reserved.
//

import UIKit

// Allows you to edit these properties in the storyboard and see the results!
// See also: https://stackoverflow.com/a/45089222/2219199
@IBDesignable extension UIButton {
    
    @IBInspectable var borderWidth: CGFloat {
        set {
            layer.borderWidth = newValue
        }
        get {
            return layer.borderWidth
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat {
        set {
            layer.cornerRadius = newValue
        }
        get {
            return layer.cornerRadius
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        set {
            guard let uiColor = newValue else { return }
            layer.borderColor = uiColor.cgColor
        }
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
    }
}
