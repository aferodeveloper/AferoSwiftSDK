//
//  XibBasedView.swift
//  AferoLab
//
//  Created by Justin Middleton on 12/8/17.
//  Copyright © 2017 Afero, Inc. All rights reserved.
//

import Foundation

import UIKit

@IBDesignable class XibBasedView: UIView {
    
    /// The name of the nib to load. Overriding is mandatory.
    var xibName: String { fatalError("XibBasedView subclasses must override xibName") }
    
    @IBInspectable var cornerRadius: CGFloat {
        get { return layer.cornerRadius }
        set { layer.cornerRadius = newValue }
    }
    
    @IBInspectable var borderWidth : CGFloat {
        get { return layer.borderWidth }
        set { layer.borderWidth = newValue }
    }
    
    @IBInspectable var borderColor: UIColor? {
        
        get {
            guard let cgColor = layer.borderColor else { return  nil}
            return UIColor(cgColor: cgColor)
        }
        
        set { layer.borderColor = newValue?.cgColor }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        initializeView()
        setupConstraints()
    }
    
    @IBOutlet var contentView: UIView!
    
    func initializeView() {
        let bundle = Bundle(for: type(of: self))
        let xibName = self.xibName
        bundle.loadNibNamed(xibName, owner: self, options: nil)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
    }
    
    func setupConstraints() {
        let views: [String: Any] = [ "v": contentView ]
        let vfl: [String] = [ "H:|-[v]-|", "V:|-[v]-|", ]
        
        let constraints = vfl.flatMap {
            NSLayoutConstraint.constraints(
                withVisualFormat: $0,
                options: [],
                metrics: nil,
                views: views
            )
        }
        
        NSLayoutConstraint.activate(constraints)
    }
    
}

