//
//  DeviceActions.swift
//  Pods
//
//  Created by Justin Middleton on 9/14/17.
//
//

import Foundation
import PromiseKit

// MARK: DeviceBatchActionRequestable

public typealias WriteAttributeOnDone = (DeviceBatchAction.Results?, Error?) -> Void
public typealias SetTimeZoneResult = (deviceId: String, tz: TimeZone, isUserOverride: Bool)
public typealias SetTimeZoneOnDone = (SetTimeZoneResult?, Error?)->Void

public protocol DeviceBatchActionRequestable: class {
    
    func post(actions: [DeviceBatchAction.Request], forDeviceId deviceId: String, withAccountId accountId: String, onDone: @escaping WriteAttributeOnDone)
    
    func setTimeZone(as timeZone: TimeZone, isUserOverride: Bool, for deviceId: String, in accountId: String, onDone: @escaping SetTimeZoneOnDone)
    
}
