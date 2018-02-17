//
//  File.swift
//  Bubba
//
//  Created by Justin Middleton on 2/13/18.
//  Copyright © 2018 Afero, Inc. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable class QRCodeView: XibBasedView {
    
    @IBOutlet weak var captionLabel: UILabel!
    
    @IBOutlet weak var qrCodeImageView: UIImageView!
    @IBOutlet weak var associationIdLabel: UILabel!
    
    override var xibName: String { return "QRCodeView" }
    
    @IBInspectable var textColor: UIColor? {
        get { return captionLabel?.textColor }
        set {
            captionLabel?.textColor = newValue
            associationIdLabel?.textColor = newValue
        }
    }
    
}
