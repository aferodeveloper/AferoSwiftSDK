//
//  AccountInfoZeroStateView.swift
//  AferoLab
//
//  Created by Justin Middleton on 3/18/17.
//  Copyright © 2017 Afero, Inc. All rights reserved.
//

import UIKit
import PromiseKit

class AccountInfoZeroStateView: UIView {
    
    @IBOutlet weak var imageView: UIImageView!
    
    func hideImage(animated: Bool = true, delay: TimeInterval = 0.0) -> Promise<Void> {
        
        if imageView.isHidden { return Promise { fulfill, _ in fulfill() } }
        
        return Promise {

            fulfill, _ in

            let changes: ()->Void = {
                self.imageView.alpha = 0
                self.imageView.layer.setAffineTransform(CGAffineTransform(scaleX: 1.1, y: 1.1))
            }
            
            let completion: (Bool)->Void = {
                _ in
                self.imageView.isHidden = true
                fulfill()
            }
            
            
            if animated {
                UIView.animate(withDuration: 0.125, delay: delay, options: .curveEaseOut, animations: changes, completion: completion)
                return
            }
            
            changes()
            completion(true)
        }
    }
    
    func showImage(animated: Bool = true, delay: TimeInterval = 0.0) -> Promise<Void> {
        
        if !imageView.isHidden { return Promise { fulfill, _ in fulfill() } }
        
        return Promise {
            fulfill, _ in
            
            let changes: ()->Void = {
                self.imageView.alpha = 1.0
                self.imageView.layer.setAffineTransform(.identity)
            }
            
            let completion: (Bool)->Void = {
                _ in
                self.imageView.isHidden = false
                fulfill()
            }

            if animated {
                UIView.animate(withDuration: 0.125, delay: delay, options: .curveEaseOut, animations: changes, completion: completion)
                return
            }
            
            changes()
            completion(true)
        }
    }
    
}

protocol UIViewLoading {}
extension UIView : UIViewLoading {}

extension UIViewLoading where Self : UIView {
    
    // note that this method returns an instance of type `Self`, rather than UIView
    static func loadFromNib() -> Self {
        let nibName = NSStringFromClass(classForCoder()).components(separatedBy: ".").last!
        let bundle = Bundle(for: classForCoder())
        let ret = bundle.loadNibNamed(nibName, owner: self, options: nil)?.first as! Self
        return ret
    }
    
}
