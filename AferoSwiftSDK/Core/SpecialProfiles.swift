//
//  SpecialProfiles.swift
//  iTokui
//
//  Created by Justin Middleton on 2/19/16.
//  Copyright © 2016 Kiban Labs, Inc. All rights reserved.
//

import Foundation

extension DeviceProfile {
    
    var enumeratedDeviceType: DeviceType? {
        guard let deviceTypeId = deviceTypeId else { return nil }
        return DeviceType(id: deviceTypeId)
    }
    
    enum DeviceType: CustomStringConvertible, ExpressibleByStringLiteral {

        typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
        typealias UnicodeScalarLiteralType = StringLiteralType
        
        case generic(id: String)
        case bento
        
        var id: String {
            
            switch self {
            case .generic(let id): return id
            case .bento: return "01396150-04ff-4873-8fe5-ac1210e36505"
            }
        }
        
        init(id: String) {

            switch id {
            case DeviceType.bento.id: self = .bento
            default: self = .generic(id: id)
            }
            
        }
        
        init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
            self.init(id: value)
        }
        
        init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
            self.init(id: value)
        }
        
        init(stringLiteral value: StringLiteralType) {
            self.init(id: value)
        }
        
        var description: String {
            return id
        }
        
    }
}
