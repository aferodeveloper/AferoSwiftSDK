//
//  AferoClimateControl.swift
//  AferoLab
//
//  Created by Justin Middleton on 10/20/17.
//  Copyright © 2017 Afero, Inc. All rights reserved.
//

import Foundation
import UIKit
import CocoaLumberjack
import Afero

@IBDesignable class AferoClimateControl: UIView {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var temperatureLabel: UILabel!
    
    // MARK: - Labels
    
    @IBInspectable var title: String? {
        get { return titleLabel.text }
        set { titleLabel.text = newValue }
    }
    
    @IBInspectable var titleNumberOfLines: Int {
        get { return titleLabel.numberOfLines }
        set { titleLabel.numberOfLines = newValue }
    }
    
    @IBInspectable var titleTextColor: UIColor! {
        get { return titleLabel.textColor }
        set { titleLabel.textColor = newValue }
    }
    
    @IBInspectable var isTitleHidden: Bool {
        get { return titleLabel.isHidden }
        set { titleLabel.isHidden = newValue }
    }
    
    @IBInspectable var temperatureValueText: String? {
        get { return temperatureLabel.text }
        set { temperatureLabel.text = newValue }
    }
    
    @IBInspectable var temperatureTextColor: UIColor! {
        get { return temperatureLabel.textColor }
        set { temperatureLabel.textColor = newValue }
    }
    
    @IBInspectable var isTemperatureHidden: Bool {
        get { return temperatureLabel.isHidden }
        set { temperatureLabel.isHidden = newValue }
    }

    // MARK: - Slider

    // MARK: Tint colors
    
    @IBInspectable var minimumTrackTintColor: UIColor? {
        get { return slider.minimumTrackTintColor }
        set { slider.minimumTrackTintColor = newValue }
    }
    
    @IBInspectable var maximumTrackTintColor: UIColor? {
        get { return slider.maximumTrackTintColor }
        set { slider.maximumTrackTintColor = newValue }
    }
    
    @IBInspectable var thumbTintColor: UIColor? {
        get { return slider.thumbTintColor }
        set { slider.thumbTintColor = newValue }
    }
    
    // MARK: Track Images
    
    @IBInspectable var normalMinimumTrackImage: UIImage? {
        get { return slider.minimumTrackImage(for: .normal) }
        set { slider.setMinimumTrackImage(newValue, for: .normal) }
    }

    @IBInspectable var disabledMinimumTrackImage: UIImage? {
        get { return slider.minimumTrackImage(for: .disabled) }
        set { slider.setMinimumTrackImage(newValue, for: .disabled) }
    }

    @IBInspectable var highlightedMinimumTrackImage: UIImage? {
        get { return slider.minimumTrackImage(for: .highlighted) }
        set { slider.setMinimumTrackImage(newValue, for: .highlighted) }
    }
    
    @IBInspectable var normalMaximumTrackImage: UIImage? {
        get { return slider.maximumTrackImage(for: .normal) }
        set { slider.setMaximumTrackImage(newValue, for: .normal) }
    }
    
    @IBInspectable var disabledMaximumTrackImage: UIImage? {
        get { return slider.maximumTrackImage(for: .disabled) }
        set { slider.setMaximumTrackImage(newValue, for: .disabled) }
    }
    
    @IBInspectable var highlightedMaximumTrackImage: UIImage? {
        get { return slider.maximumTrackImage(for: .highlighted) }
        set { slider.setMaximumTrackImage(newValue, for: .highlighted) }
    }
    
    // MARK: Thumb Image
    
    @IBInspectable var normalThumbImage: UIImage? {
        get { return slider.thumbImage(for: .normal) }
        set { slider.setThumbImage(newValue, for: .normal)}
    }

    @IBInspectable var disabledThumbImage: UIImage? {
        get { return slider.thumbImage(for: .disabled) }
        set { slider.setThumbImage(newValue, for: .disabled)}
    }
    
    @IBInspectable var highlightedThumbImage: UIImage? {
        get { return slider.thumbImage(for: .highlighted) }
        set { slider.setThumbImage(newValue, for: .highlighted) }
    }
    
    // MARK: Value Images
    
    @IBInspectable var minimumValueImage: UIImage? {
        get { return slider.minimumValueImage }
        set { slider.minimumValueImage = newValue }
    }

    @IBInspectable var maximumValueImage: UIImage? {
        get { return slider.maximumValueImage }
        set { slider.maximumValueImage = newValue }
    }
    
    // MARK: Lifecyle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
    }
    
    func commonInit() {

        initializeView()
        setupConstraints()
        
        title = "Temperature"
        temperatureValueText = "100°C"
        
    }
    
    func initializeView() {
        let bundle = Bundle(for: type(of: self))
        bundle.loadNibNamed("AferoClimateControlContent", owner: self, options: nil)
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
