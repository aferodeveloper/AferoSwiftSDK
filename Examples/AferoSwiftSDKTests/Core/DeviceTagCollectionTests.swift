//
//  DeviceTagCollectionTests.swift
//  AferoTests
//
//  Created by Justin Middleton on 11/16/17.
//  Copyright © 2017 Afero, Inc. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import Afero

class DeviceTagCollectionSpec: QuickSpec {
    
    override func spec() {
        
        describe("Initialization") {
            
            it("should initializize") {
                let c = DeviceTagCollection()
                expect(c.tags.count) == 0
                expect(c.isEmpty).to(beTrue())
            }
        }
    }
    
}

