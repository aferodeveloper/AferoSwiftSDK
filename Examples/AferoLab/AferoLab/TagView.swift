//
//  TagView.swift
//  AferoLab
//
//  Created by Justin Middleton on 12/4/17.
//  Copyright © 2017 Afero, Inc. All rights reserved.
//

import UIKit

@IBDesignable @objcMembers class TagCollectionViewCell: UICollectionViewCell {

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
    
    private var tagView: TagView!
    
    func initializeView() {
        tagView = TagView(frame: .zero)
        tagView.translatesAutoresizingMaskIntoConstraints = false
        tagView.setContentHuggingPriority(.required, for: .horizontal)
        tagView.setContentHuggingPriority(.required, for: .vertical)
        addSubview(tagView)
    }
    
    func setupConstraints() {
        let views: [String: Any] = [ "v": tagView ]
        let vfl: [String] = [ "H:|[v]|", "V:|[v]|", ]
        
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
    
    @IBInspectable var value: String? {
        get { return tagView.value }
        set { tagView.value = newValue }
    }
    
    @IBInspectable var key: String? {
        get { return tagView.key }
        set { tagView.key = newValue }
    }
    
    @IBInspectable var tagCornerRadius: CGFloat {
        get { return tagView.layer.cornerRadius }
        set { tagView.layer.cornerRadius = newValue }
    }
    
    @IBInspectable var tagBackgroundColor: UIColor? {
        get { return tagView.backgroundColor }
        set { tagView.backgroundColor = newValue }
    }
    
    @IBInspectable var textColor: UIColor? {
        get { return tagView.textColor }
        set { tagView.textColor = newValue }
    }

}

@IBDesignable @objcMembers class TagView: UIView {

    @IBOutlet var contentView: UIView!

    @IBOutlet weak var valueLabel: UILabel!
    @IBInspectable var value: String? {
        get { return valueLabel.text }
        set { valueLabel.text = newValue }
    }
    
    @IBOutlet weak var keySeparatorContainerView: UIView!
    
    
    @IBOutlet weak var keyLabel: UILabel!
    @IBInspectable var key: String? {
        get { return keyLabel.text }
        set { keyLabel.text = newValue }
    }
    
    @IBOutlet weak var separatorLabel: UILabel!
    @IBInspectable var separator: String? {
        get { return separatorLabel.text }
        set { separatorLabel.text = newValue }
    }
    
    @IBInspectable var contentCornerRadius: CGFloat {
        get { return contentView.layer.cornerRadius }
        set { contentView.layer.cornerRadius = newValue }
    }
    
    @IBInspectable var contentBackground: UIColor? {
        get { return contentView.backgroundColor }
        set { contentView.backgroundColor = newValue }
    }
    
    @IBInspectable var textColor: UIColor? {
        get { return valueLabel.textColor }
        set {
            valueLabel.textColor = newValue
            separatorLabel.textColor = newValue
            keyLabel.textColor = newValue
        }
    }

    // MARK: Lifecyle
    
    private var keyTextObservation: NSKeyValueObservation?
    
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
        
        layoutMargins = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        
        key = nil
        value = nil
        
        updateVisibleViews()

        keyTextObservation = keyLabel?.observe(\.text) {
            [weak self] obj, change in
            self?.updateVisibleViews()
        }
        
    }
    
    func initializeView() {
        let bundle = Bundle(for: type(of: self))
        bundle.loadNibNamed("TagViewContent", owner: self, options: nil)
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
    
    private func updateVisibleViews() {
        keySeparatorContainerView.isHidden = (key?.isEmpty ?? true)
        valueLabel.textAlignment = keySeparatorContainerView.isHidden ? .center : .right
    }

}


