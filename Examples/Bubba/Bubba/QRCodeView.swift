//
//  File.swift
//  Bubba
//
//  Created by Justin Middleton on 2/13/18.
//  Copyright © 2018 Afero, Inc. All rights reserved.
//

import Foundation
import UIKit
import QRCode
import SVProgressHUD

@IBDesignable class QRCodeView: XibBasedView {
    
    @IBOutlet var tapRecognizer: UITapGestureRecognizer!
    @IBOutlet weak var captionLabel: UILabel!
    
    @IBOutlet weak var qrCodeImageView: UIImageView!
    @IBOutlet weak var associationIdLabel: UILabel!
    @IBOutlet weak var tapToCopyLabel: UILabel!
    
    @IBInspectable var associationId: String? {

        get {
            return associationIdLabel?.text
        }
        
        set {
            associationIdLabel.text = newValue
            tapToCopyLabel.isHidden = newValue == nil
            
            guard let newValue = newValue else {
                qrCodeImageView.image = nil
                return
            }
            
            qrCodeImageView.image = QRCode(newValue)?.image
            setNeedsLayout()
            invalidateIntrinsicContentSize()
        }
    }
    
    override var xibName: String { return "QRCodeView" }
    
    @IBInspectable var textColor: UIColor? {
        get { return captionLabel?.textColor }
        set {
            captionLabel?.textColor = newValue
            associationIdLabel?.textColor = newValue
        }
    }
    
    @IBAction func tapped(_ sender: Any) {
        guard let associationId = associationId else { return }
        UIPasteboard.general.setItems(
            [[ UIPasteboardTypeAutomatic: associationId ]],
            options: [:]
        )
        SVProgressHUD.showSuccess(withStatus: "Copied to Clipboard!", maskType: .gradient)
    }
}
