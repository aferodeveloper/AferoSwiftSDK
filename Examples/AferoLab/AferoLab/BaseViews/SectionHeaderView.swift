//
//  SectionHeaderView.swift
//  AferoLab
//
//  Created by Justin Middleton on 12/9/17.
//  Copyright © 2017 Afero, Inc. All rights reserved.
//

import UIKit

@IBDesignable class SectionHeaderView: XibBasedView {

    override var xibName: String { return "SectionHeaderView" }
    
    @IBOutlet weak var headerLabel: UILabel!
    
    @IBInspectable var headerText: String? {
        get { return headerLabel.text }
        set { headerLabel.text = newValue }
    }
    
    @IBInspectable var headerTextColor: UIColor? {
        get { return headerLabel.textColor }
        set { headerLabel.textColor = newValue }
    }
    
    @IBOutlet weak var captionLabel: UILabel!

    @IBInspectable var captionText: String? {
        get { return captionLabel.text }
        set {
            captionLabel.text = newValue
            updateUI()
        }
    }
    
    @IBInspectable var captionTextColor: UIColor? {
        get { return captionLabel.textColor }
        set { captionLabel.textColor = newValue }
    }

    @IBOutlet weak var accessoryStackView: UIStackView!
    
    public var accessoryViews: [UIView] {

        get { return accessoryStackView?.arrangedSubviews ?? [] }

        set {
            removeAllAccessoryViews()
            newValue.forEach { add(accessoryView: $0) }
        }
        
    }
    
    public func add(accessoryView: UIView) {
        accessoryStackView.addArrangedSubview(accessoryView)
    }
    
    public func remove(accessoryView: UIView) {
        
        guard accessoryViews.contains(accessoryView) else {
            assert(false, "\(accessoryView) is not one of my views.")
            return
        }
        
        accessoryStackView.removeArrangedSubview(accessoryView)
        accessoryView.removeFromSuperview()
    }
    
    public func removeAllAccessoryViews() {
        accessoryViews.forEach { remove(accessoryView: $0) }
    }
    
    func updateUI() {
        captionLabel.isHidden = captionLabel.text?.isEmpty ?? true
    }
}

@IBDesignable class SectionHeaderTableViewHeaderFooterView: UITableViewHeaderFooterView {
    
    private var sectionHeaderView: SectionHeaderView!
    
    @IBInspectable var headerText: String? {
        get { return sectionHeaderView?.headerText }
        set { sectionHeaderView?.headerText = newValue }
    }
    
    @IBInspectable var headerTextColor: UIColor? {
        get { return sectionHeaderView?.headerTextColor }
        set { sectionHeaderView?.headerTextColor = newValue }
    }

    @IBInspectable var captionText: String? {
        get { return sectionHeaderView?.captionText }
        set { sectionHeaderView?.captionText = newValue }
    }
    
    @IBInspectable var captionTextColor: UIColor? {
        get { return sectionHeaderView?.captionTextColor }
        set { sectionHeaderView?.captionTextColor = newValue }
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        
        contentView.backgroundColor = .white
        sectionHeaderView = SectionHeaderView()
        sectionHeaderView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(sectionHeaderView)

        setupConstraints()
    }
    
    func setupConstraints() {
        
        let views: [String: Any] = [ "v": sectionHeaderView ]
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }

    
    public var accessoryViews: [UIView] {
        get { return sectionHeaderView.accessoryViews }
        set { sectionHeaderView.accessoryViews = newValue }
    }
    
    public func add(accessoryView: UIView) {
        sectionHeaderView.add(accessoryView: accessoryView)
    }
    
    public func remove(accessoryView: UIView) {
        sectionHeaderView.remove(accessoryView: accessoryView)
    }
    
    public func removeAllAccessoryViews() {
        sectionHeaderView.removeAllAccessoryViews()
    }

    
}
