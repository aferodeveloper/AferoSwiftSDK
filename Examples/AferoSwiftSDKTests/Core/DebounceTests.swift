//
//  DebounceTests.swift
//  iTokui
//
//  Created by Martin Arnberg on 10/11/16.
//  Copyright © 2016 Kiban Labs, Inc. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Afero
import CocoaLumberjack


class DebounceSpec: QuickSpec {

    override func spec() {
        
        describe("Debounce") {
            
            it("Should trigger after delay") {
                var refCount = 0
                var triggerTime: NSNumber? = nil
                var startTime: NSNumber? = nil
                let semaphore = DispatchSemaphore(value: 0)

                
                let debouncedAction: ()->() = debounce(TimeInterval(0.2), queue: .main, action: {
                    refCount += 1
                    triggerTime = Date().millisSince1970
                })
                
                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.1) {
                    startTime = Date().millisSince1970
                    debouncedAction()
                    semaphore.signal()
                }
                
                guard case .success = semaphore.wait(timeout: .now() + 1.0) else {
                    fail("Failed to acquire sem")
                    return
                }
                
                expect(refCount).toEventually(equal(1),timeout: 1, pollInterval: 0.01)

                expect(startTime).toNot(beNil());
                expect(triggerTime).toNot(beNil());
                
                let actualDelay = Double(UInt64(truncating: triggerTime!) - UInt64(truncating: startTime!))
                expect(actualDelay).to(beCloseTo(209, within: 10)) // Accept delay 0 ~ 20 milliseconds, These are arbitrary numbers, should be 200
            }
            
            it("Should trigger once for multiple calls") {
                var refCount = 0
                let semaphore = DispatchSemaphore(value: 0)

                let debouncedAction: ()->() = debounce(TimeInterval(0.2), queue: .main, action: {
                    refCount += 1
                })

                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.1) {
                    debouncedAction()
                }

                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.2) {
                    debouncedAction()
                }
                
                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.3) {
                    debouncedAction()
                    semaphore.signal()
                }
                
                guard case .success = semaphore.wait(timeout: .now() + 1.0) else {
                    fail("Failed to acquire sem")
                    return
                }

                expect(refCount).toEventually(equal(1),timeout: 1, pollInterval: 0.01)
            }
            
        }
        
        describe("Fast Debounce") {

            it("Should trigger once imemediately when called") {
                var refCount = 0
                var triggerTime: NSNumber? = nil
                var startTime: NSNumber? = nil
                let semaphore = DispatchSemaphore(value: 0)

                let debouncedAction: ()->() = fastDebounce(TimeInterval(0.2), queue: .main, action: {
                    refCount += 1
                    triggerTime = Date().millisSince1970
                })
                
                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.1) {
                    startTime = Date().millisSince1970
                    debouncedAction()
                    semaphore.signal()
                }
                
                guard case .success = semaphore.wait(timeout: .now() + 1.0) else {
                    fail("Failed to acquire sem in 1.0 secs")
                    return
                }
                
                expect(refCount).toEventually(equal(1),timeout: 1, pollInterval: 0.01)
                expect(startTime).toNot(beNil());
                expect(triggerTime).toNot(beNil());
                
                let actualDelay = Double(UInt64(truncating: triggerTime!) - UInt64(truncating: startTime!))
                expect(actualDelay).to(beCloseTo(9, within: 10)) // Accept delay 0 ~ 20 milliseconds, These are arbitrary numbers, should be 0
            }
            
            it("Should trigger twice for multiple calls") {
                var refCount = 0
                let semaphore = DispatchSemaphore(value: 0)
                
                let debouncedAction: ()->() = fastDebounce(TimeInterval(0.2), queue: .main, action: {
                    refCount += 1
                })

                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.1) {
                    debouncedAction()
                }
                
                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.2) {
                    debouncedAction()
                }
                
                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.3) {
                    debouncedAction()
                    semaphore.signal()
                }
                
                guard case .success = semaphore.wait(timeout: .now() + 1.0) else {
                    fail("Failed to acquire sem in 1.0 secs.")
                    return
                }
                
                expect(refCount).toEventually(equal(2) ,timeout: 1, pollInterval: 0.01)
            }
        }
    }
}
