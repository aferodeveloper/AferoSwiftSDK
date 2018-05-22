//
//  DeviceInspectorTableViewCells.swift
//  AferoLab
//
//  Created by Justin Middleton on 12/13/17.
//  Copyright © 2017 Afero, Inc. All rights reserved.
//

import Foundation
import UIKit
import Afero

// MARK: - Device Characteristic Cell

class DeviceInspectorDeviceCharacteristicCell: UITableViewCell {
    
    @IBOutlet weak var characteristicNameLabel: UILabel!
    var characteristicName: String? {
        get { return characteristicNameLabel.text }
        set { characteristicNameLabel.text = newValue }
    }
    
    @IBOutlet weak var characteristicValueLabel: UILabel!
    var characteristicValue: String? {
        get { return characteristicValueLabel.text }
        set { characteristicValueLabel.text = newValue }
    }
    
}

// MARK: - Attribute Cells -

/// A cell which displays a single attribute. To configure,
/// simply set the `attribute` property.

class DeviceInspectorGenericAttributeCell: UITableViewCell {
    
    @IBOutlet weak var attributeNameLabel: UILabel!
    @IBOutlet weak var attributeIdLabel: UILabel!
    @IBOutlet weak var attributeTypeLabel: UILabel!
    @IBOutlet weak var attributeStringValueLabel: UILabel!
    @IBOutlet weak var attributeByteValueLabel: UILabel!
    @IBOutlet weak var attributeUpdatedTimestampLabel: UILabel!
    
    /// The (compound) value which is used to populate all fields.
    
    var attribute: DeviceModelable.Attribute? {
        
        didSet {
            
            guard let attribute = attribute else {
                attributeNameLabel?.text = nil
                attributeIdLabel?.text = nil
                attributeTypeLabel?.text = nil
                attributeStringValueLabel?.text = nil
                attributeByteValueLabel?.text = nil
                attributeUpdatedTimestampLabel?.text = nil
                return
            }
            
            attributeNameLabel?.text = attribute.config.descriptor.semanticType
            attributeIdLabel?.text = "\(attribute.config.descriptor.id)"
            attributeTypeLabel?.text = attribute.config.descriptor.dataType.stringValue ?? "<unknown>"
            attributeStringValueLabel?.text = attribute.value.stringValue ?? "<empty>"
            attributeByteValueLabel?.text = attribute.value.byteArray.description
            
            var attributeUpdatedTimestampText = "-"
            if let updatedTimestamp = attribute.updatedTimestamp {
                attributeUpdatedTimestampText = String(describing: updatedTimestamp)
            }
            
            attributeUpdatedTimestampLabel?.text = attributeUpdatedTimestampText
            setNeedsLayout()
        }
    }
    
}

// MARK: - DeviceInspectorTagCollectionCell -

// MARK: DeviceInspectorTagCollectionCellDelegate

protocol DeviceInspectorTagCollectionCellDelegate: class {
    func tagCollectionCell(_ cell: DeviceInspectorTagCollectionCell, preferredHeightDidChangeTo newHeight: CGFloat)
    func tagCollectionCell(_ cell: DeviceInspectorTagCollectionCell, presentTagEditorForTagAt indexPath: IndexPath)
}

// MARK: DeviceInspectorTagCollectionCell

class DeviceInspectorTagCollectionCell: UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegate {
    
    weak var delegate: DeviceInspectorTagCollectionCellDelegate?
    
    // MARK: Model
    
    func set(tags: Set<DeviceTagCollection.DeviceTag>) {
        self.tags = tags.sorted()
    }
    
    var tags: [DeviceModelable.DeviceTag] = [] {
        didSet {
            collectionView?.reloadData()
            collectionView?.collectionViewLayout.invalidateLayout()
        }
    }
    
    func tag(for indexPath: IndexPath) -> DeviceModelable.DeviceTag? {
        guard indexPath.item > 0 else { return nil }
        return tags[indexPath.item]
    }
    
    func indexPath(for tag: DeviceModelable.DeviceTag) -> IndexPath? {
        
        guard let tagId = tag.id else {
            return nil
        }
        
        guard let item = tags.index(where: { $0.id == tagId }) else {
            return nil
        }
        
        return IndexPath(item: item, section: 0)
    }
    
    // MARK: <UICollectionViewDataSource>
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tags.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let reuseId: String
        
        switch indexPath.item {
        default: reuseId = "TagCell"
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseId, for: indexPath)
        
        if let collectionCell = cell as? TagCollectionViewCell {
            configure(cell: collectionCell, for: indexPath)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.tagCollectionCell(self, presentTagEditorForTagAt: indexPath)
    }
    
    func configure(cell: TagCollectionViewCell, for indexPath: IndexPath) {
        guard let t = tag(for: indexPath) else { return }
        cell.key = t.key
        cell.value = t.value
    }
    
    // MARK: UI
    
    override func prepareForReuse() {
        super.prepareForReuse()
        tags = []
    }
    
    private var contentSizeObservation: NSKeyValueObservation?
    
    @IBOutlet weak var collectionView: UICollectionView! {
        
        didSet {
            
            collectionView?.dataSource = self
            collectionView?.delegate = self
            
            if let flowLayout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
                flowLayout.estimatedItemSize = CGSize(width: 100, height: 32)
                flowLayout.minimumLineSpacing = 5.0
                flowLayout.minimumInteritemSpacing = 5.0
            }
            
            contentSizeObservation = collectionView?.observe(\.contentSize) {
                [weak self] obj, change in
                self?.preferredHeight = obj.collectionViewLayout.collectionViewContentSize.height
            }
            
        }
    }
    
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    var preferredHeight: CGFloat {
        get { return heightConstraint.constant }
        set {
            heightConstraint.constant = newValue
            delegate?.tagCollectionCell(self, preferredHeightDidChangeTo: newValue)
        }
    }
    
}


