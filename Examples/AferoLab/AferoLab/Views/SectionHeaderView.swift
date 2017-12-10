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
    
}

@IBDesignable class SectionHeaderTableViewHeaderFooterView: UITableViewHeaderFooterView {
    
    private var sectionHeaderView: SectionHeaderView!
    
    @IBInspectable var headerText: String? {
        get { return sectionHeaderView?.headerLabel?.text }
        set { sectionHeaderView?.headerLabel?.text = newValue }
    }
    
    @IBInspectable var headerTextColor: UIColor? {
        get { return sectionHeaderView?.headerLabel?.textColor }
        set { sectionHeaderView?.headerLabel?.textColor = newValue }
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
        sectionHeaderView = SectionHeaderView(frame: contentView.bounds)
        sectionHeaderView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        contentView.backgroundColor = .white
        contentView.addSubview(sectionHeaderView)
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
