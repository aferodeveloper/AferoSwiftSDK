//
//  String+Util.swift
//  Pods
//
//  Created by Justin Middleton on 7/7/17.
//
//

import Foundation

extension String {
    
    // MARK: URL transforms
    
    var hostAllowedEncodedString: String? {
        return addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
    }
    
    var pathAllowedURLEncodedString: String? {
        return addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
    }
    
    var fragmentAllowedURLEncodedString: String? {
        return addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
    }
    
    var passwordAllowedURLEncodedString: String? {
        return addingPercentEncoding(withAllowedCharacters: .urlPasswordAllowed)
    }
    
    var queryAllowedURLEncodedString: String? {
        return addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
    
    var alphanumericURLEncodedString: String? {
        return addingPercentEncoding(withAllowedCharacters: .alphanumerics)
    }

}
