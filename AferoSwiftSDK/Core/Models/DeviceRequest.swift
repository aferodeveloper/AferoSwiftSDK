//
//  DeviceRequest.swift
//  iTokui
//
//  Created by Justin Middleton on 2/9/17.
//  Copyright © 2017 Kiban Labs, Inc. All rights reserved.
//

import Foundation
import HTTPStatusCodes

import CocoaLumberjack

/// Structures related to the batch device actions API.
/// See http://wiki.afero.io/display/CD/Batch+Attribute+Requests .

public struct DeviceBatchAction {
    
    /// Emitted when an entire batch request, or one of its
    /// constituent individual requests, fails.
    
    public enum Error: Swift.Error {
        
        /// The reason for either a complete, or partial/constituent failure
        /// of  device action request.
        
        public enum Reason {
            
            /// The device is not online, so there's no way
            /// to satisfy the request to set the attribute.
            /// Associated with `HTTPStatusCode.failedDependency (424)`
            
            case deviceOffline(underlyingError: Swift.Error?)
            
            /// The device is currently linking. In other words,
            /// it's "almost" online, and if linking is successful
            /// (4-10 seconds observed), then it's possible the
            /// associated request could be retried.
            /// Associated with `HTTPStatusCode.locked (423)`
            
            case deviceIsLinking(underlyingError: Swift.Error?)
            
            /// An individual request body was invalid. This is a
            /// fatal error and likely indicates a serialization
            /// incompatibilty or a programming error in the caller.
            /// Associated with `HTTPStatusCode.badRequest (400)`
            
            case invalidRequest(underlyingError: Swift.Error?)
            
            /// An individual request was forbidden. This can happen
            /// if the requesting account doesn't have access to
            /// the attribute the request intended to modify.
            /// Associated with `HTTPStatusCode.forbidden (403)`
            /// - note: As of this writing (02Mar2017), the service does not
            ///         enforce attribute-level permissions,
            ///         so this should not be seen.
            
            case forbidden(underlyingError: Swift.Error?)
            
            /// The current account is no longer authorized. This should
            /// never be seen in the body of a response to a
            /// successful batch request, as the original batch
            /// request would 401 us. Including here for the
            /// sake of completeness.
            /// Associated with `HTTPStatusCode.unauthorized (401)`

            case unauthorized(underlyingError: Swift.Error?)
            
            /// Something else happened that doesn't translate to one
            /// of our reasons. See the code and error.
            case other(underlyingError: Swift.Error?)
            
            /// Initialize this instance optionally with the given `HTTPStatusCode` value, and optionally
            /// underlying `Error`.
            ///
            /// - parameter statusCode: The `HTTPStatusCode` to use. If not provided, then
            ///                         retrieval of the code will be attempted from `underlyingError`.
            /// - parameter underlyingError: The underlying error that indicated this `Reason`.
            ///                              Also a secondary source for `HTTPStatusCode`.
            
            init(statusCode: HTTPStatusCode? = nil, underlyingError: Swift.Error? = nil) {
                
                guard let statusCode = statusCode ?? underlyingError?.httpStatusCodeValue else {
                    self = .other(underlyingError: underlyingError)
                    return
                }
                
                switch statusCode {
                case .failedDependency:
                    self = .deviceOffline(underlyingError: underlyingError)
                case .locked:
                    self = .deviceIsLinking(underlyingError: underlyingError)
                case .badRequest:
                    self = .invalidRequest(underlyingError: underlyingError)
                case .forbidden:
                    self = .forbidden(underlyingError: underlyingError)
                case .unauthorized:
                    self = .unauthorized(underlyingError: underlyingError)
                default:
                    self = .other(underlyingError: underlyingError)
                }
                
            }
            
            /// The underlying error, if any, associated with this instance.
            
            var underlyingError: Swift.Error? {
                switch self {
                case .deviceOffline(let e):    return e
                case .deviceIsLinking(let e):  return e
                case .invalidRequest(let e):   return e
                case .forbidden(let e):        return e
                case .unauthorized(let e):     return e
                case .other(let e):            return e
                }
            }
            
            public var httpStatusCode: HTTPStatusCode? {
                switch self {
                case .deviceOffline: return .failedDependency
                case .deviceIsLinking: return .locked
                case .invalidRequest: return .badRequest
                case .unauthorized: return .unauthorized
                case .forbidden: return .forbidden
                case .other: return underlyingError?.httpStatusCodeValue
                }
            }

        }
        
        /// The request failed at the API level; none of the
        /// constituent requests were attempted, for the `reason`
        /// given.
        case apiFailure(requests: [Request], reason: Reason)
        
        /// There were one or more failures on constituent
        /// requests. See the `results` value for details.
        case constituentRequestFailure(results: Results)
        
        /// There was some other error that didn't map
        /// to known `Reason` cases. See `underlyingError`
        /// for details.
        case other(underlyingError: Swift.Error)
        
        // MARK: Override <Error> Extensions (see `Extensions.swift`)
        
        public var reason: Reason? {
            if case let .apiFailure(_, r) = self { return r }
            return nil
        }
        
        public var underlyingError: Swift.Error? {
            if case let .other(e) = self { return e }
            if case let .apiFailure(_, reason) = self { return reason.underlyingError }
            return nil
        }
        
        public var httpResponseBody: Any? {
            return underlyingError?.httpResponseBody
        }
        
        public var httpUrlResponse: HTTPURLResponse? {
            return underlyingError?.httpUrlResponse
        }
        
        public var httpStatusCode: Int? {
            return reason?.httpStatusCode?.rawValue ?? underlyingError?.httpStatusCode
        }
        
        public var httpStatusCodeValue: HTTPStatusCode? {
            return reason?.httpStatusCode ?? underlyingError?.httpStatusCodeValue
        }

    }

    /// A structure that contains requests and responses from a batch operation.
    /// Use the `pairs` property to iterate through correlated values.
    
    public struct Results: CustomDebugStringConvertible {
        
        public var debugDescription: String {
            return "<DeviceBatchAction.Results> \n" + requestResponsePairs.map {
                "    \($0): \($1)"
            }.joined(separator: "\n")
        }
    
        /// The requests associated with this instance
        private(set) public var requests: [Request]
        
        /// The responses associated with this instance
        private(set) public var responses: [Response]
        
        public init(requests: [Request], responses: [Response]) {
            self.requests = requests
            self.responses = responses
        }
        
        public typealias RequestResponseSequence = Zip2Sequence<[Request], [Response]>
        
        /// A sequence of correlated `(Request, Response)` for this object

        public var requestResponsePairs: LazySequence<RequestResponseSequence> {
            return zip(requests, responses).lazy
        }
        
        /// `(Request, Response)` pairs that were written successfully

        public var successPairs: LazyFilterSequence<RequestResponseSequence> {
            return requestResponsePairs.filter {
                request, response in
                switch response {
                case .success:
                    return true
                default:
                    return false
                }
            }
        }
        
        /// `(Request, Response)` pairs that explicitly failed. There
        /// will only be one of these

        public var failurePairs: LazyFilterSequence<RequestResponseSequence> {
            return requestResponsePairs.filter {
                request, response in
                switch response {
                case .failure: return true
                default: return false
                }
            }
        }
        
        /// `(Request, Response)` pairs that weren't attempted.
        
        public var notAttemptedDueToPriorFailurePairs: LazyFilterSequence<RequestResponseSequence> {
            return requestResponsePairs.filter {
                request, response in
                switch response {
                case .notAttemptedDueToPriorFailure: return true
                default: return false
                }
            }
        }
        
        /// `(Request, Response)` pairs that either failed
        /// or were not attempted. In other words, everything
        /// that wasn't an explicit success.
        
        public var notSuccessfulPairs: LazyFilterSequence<RequestResponseSequence> {
            return requestResponsePairs.filter {
                request, response in
                switch response {
                case .success: return false
                default: return true
                }
            }
        }
        
        /// Whether or not the batch operation this instance represents
        /// completed successfully. In other words, if `notSuccessful`
        /// is empty.
        
        public var completedSuccessfully: Bool {
            for _ in notSuccessfulPairs {
                return false
            }
            return true
        }
        
        public func wasSuccessfulFor(attributeId: Int) -> Bool {
            return successPairs.contains {
                if
                    case let .attributeWrite(id, _) = $0.0,
                    id == attributeId {
                        return true
                }
                return false
            }
        }
        
        public var requestIds: [Int] {
            return responses.flatMap { $0.requestId }
        }
    }
    
    /// An enumeration representing a component of a batch operation
    /// against an Afero device. See http://wiki.afero.io/display/CD/Batch+Attribute+Requests
    ///
    /// * attributeRead: Request a read of an attribute (result will be sent through Conclave)
    /// * attributeWrite: Write an attribute value to a device
    
    public enum Request: CustomDebugStringConvertible, Equatable {
        
        public var debugDescription: String {
            let ret = "<DevicRequest."
            switch self {
            case let .attributeRead(id): return ret + "attributeRead> (id: \(id))"
            case let .attributeWrite(id, value): return ret + "attributeWrite> (id: \(id) value: \(value))"
            case let .notifyViewing(interval): return ret + "notifyViewing> (interval: \(interval))"
            }
        }
        
        /// Request a read of an attribute (result will be sent through Conclave)
        case attributeRead(attributeId: Int)
        
        /// Write an attribute value to a device
        case attributeWrite(attributeId: Int, value: String)
        
        /// Notify that a local UI client is viewing the device, for N seconds.
        case notifyViewing(interval: TimeInterval)
        
        /// Initialize with an attibuteValue, as a `.attributeWrite(Int, String)` case
        public init?(attributeId: Int, value: AttributeValue) {
            guard let stringValue = value.stringValue else { return nil }
            self = .attributeWrite(attributeId: attributeId, value: stringValue)
        }
        
        /// Initialize with an attributeId only, implied to be an `.attributeRead(Int)` case.
        public init(attributeId: Int) {
            self = .attributeRead(attributeId: attributeId)
        }
        
        public static func == (lhs: Request, rhs: Request) -> Bool {
            switch (lhs, rhs) {
                
            case let (.attributeRead(lid), .attributeRead(rid)):
                return lid == rid
                
            case let (.attributeWrite(lid, lval), .attributeWrite(rid, rval)):
                return lid == rid && lval == rval
                
            case let (.notifyViewing(li), .notifyViewing(ri)):
                return li == ri
                
            default: return false
            }
        }
        
        
    }
    
    /// An enumeration representing a response to a `DeviceRequest` batch operation.
    /// Successes are indicated with requestIds corresponding to requests queued
    /// in Conclave. See http://wiki.afero.io/display/CD/Batch+Attribute+Requests for details.
    ///
    /// * `success(requestId: Int, statusCode: Int, timestampMs: NSNumber)`: The
    ///   request with the given `requestId` was a success, with the given `statusCode`,
    ///   queued to Conclave at the UTC time indicated by `timestamp`.
    /// * `failure(statusCode: Int)`: The corresponding request failed with the given `statusCode`
    /// * `notAttemptedDueToPriorFailure`: The corresponding request was not attempted due to a prior failure.
    
    public enum Response: CustomDebugStringConvertible {
        
        public var debugDescription: String {
            let prefix = "<DeviceResponse."
            switch self {
            case let .success(requestId, statusCode, timestampMs):
                return prefix + "success>(requestId: \(String(reflecting: requestId)) statusCode: \(String(reflecting: statusCode)) timestampMms: \(String(reflecting: timestampMs))"
                
            case let .failure(statusCode):
                return prefix + "failure>(statusCode: \(statusCode)"
                
            case .notAttemptedDueToPriorFailure:
                return prefix + "notAttemptedDueToPriorFailure>"
            }
        }
        
        /// The request with the given `requestId` was a success, with the given `statusCode`,
        /// queued to Conclave at the UTC time indicated by `timestamp`.
        case success(requestId: Int?, statusCode: HTTPStatusCode?, timestampMs: NSNumber?)
        
        /// The correspoinding request failed with the given `statusCode`
        case failure(reason: DeviceBatchAction.Error.Reason)
        
        /// The corresponding request was not attempted due to a prior failure.
        case notAttemptedDueToPriorFailure
        
        /// The raw UTC timestamp in milliseconds that the request was added to the
        /// Conclave queue for writing to the device.
        public var timestampMs: NSNumber? {
            if case let .success(_, _, ret) = self { return ret }
            return nil
        }
        
        /// An NSDate representation of `timestampMs`.
        public var timestamp: Date? {
            guard let timestampMs = timestampMs else { return nil }
            return Date.dateWithMillisSince1970(timestampMs)
        }
        
        /// The id of the `DeviceRequest` that corresponds to this response.
        public var requestId: Int? {
            if case let .success(ret, _, _) = self { return ret }
            return nil
        }
        
        /// The enumerated, symbolic HTTP status code, if available (not present
        /// in `.notAttemptedDueToPriorFailure` cases.
        public var httpStatusCode: HTTPStatusCode? {
            switch self {
            case let .success(_, ret, _): return ret
            case let .failure(r):       return r.httpStatusCode
            default:                      return nil
            }
        }
        
    }

}

extension DeviceBatchAction.Request: AferoJSONCoding {
    
    enum CodingKeys: String, CodingKey {
        case type
        case attributeId = "attrId"
        case value
        case interval = "seconds"
    }
    
    enum CodingTypeValues: String, CodingKey {
        case attributeWrite = "attribute_write"
        case attributeRead = "attribute_read"
        case notifyViewing = "notify_viewing"
    }
    
    public var JSONDict: AferoJSONCodedType? {
        
        var ret: [CodingKeys: Any] = [:]
        
        switch self {
            
        case let .attributeWrite(attributeId, value):
            ret[.type] = CodingTypeValues.attributeWrite.stringValue
            ret[.attributeId] = attributeId
            ret[.value] = value
            
        case let .attributeRead(attributeId):
            ret[.type] = CodingTypeValues.attributeRead.stringValue
            ret[.attributeId] = attributeId
            
        case let .notifyViewing(interval):
            ret[.type] = CodingTypeValues.notifyViewing.stringValue
            ret[.interval] = interval
        }
        
        return ret.stringKeyed
    }
    
    public init?(json: AferoJSONCodedType?) {
        
        guard let jsonDict = json as? [String: Any] else {
            DDLogWarn("Unable to cast \(String(reflecting: json)) to [String: Any]; bailing.")
            return nil
        }
        
        guard
            let requestTypeName = jsonDict[CodingKeys.type.stringValue] as? String,
            let requestType = CodingTypeValues(rawValue: requestTypeName) else {
                DDLogError("Unable to extract rquest type from \(jsonDict.debugDescription); bailing.")
                return nil
        }
        
        switch requestType {
            
        case .attributeWrite:
            guard
                let attrId = jsonDict[CodingKeys.attributeId.stringValue] as? Int,
                let value = jsonDict[CodingKeys.value.stringValue] as? String else {
                DDLogError("Attempt to create attributeWrite with nil attrId or nil value.")
                return nil
            }
            
            self = .attributeWrite(attributeId: attrId, value: value)
            
        case .attributeRead:
            guard
                let attrId = jsonDict[CodingKeys.attributeId.stringValue] as? Int else {
                    DDLogError("Attempt to create attributeRead with nil attrId.")
                    return nil
            }
            self = .attributeRead(attributeId: attrId)
            
        case .notifyViewing:
            guard let intervalDouble = jsonDict[CodingKeys.interval.stringValue] as? NSNumber else {
                DDLogError("Attempt to create notifyViewing with nil interval.")
                return nil
            }
            self = .notifyViewing(interval: TimeInterval(intervalDouble))
            
        }
        
    }
}

extension DeviceBatchAction.Response: AferoJSONCoding {
    
    private static var SuccessName: String { return "SUCCESS" }
    private static var FailureName: String { return "FAILURE" }
    private static var NotAttemptedName: String { return "NOT_ATTEMPTED" }
    
    private static var CoderKeyStatus: String { return "status" }
    private static var CoderKeyRequestId: String { return "requestId" }
    private static var CoderKeyStatusCode: String { return "statusCode" }
    private static var CoderKeyTimestampMs: String { return "timestampMs" }
    
    public var JSONDict: AferoJSONCodedType? {
        switch self {
            
        case let .success(requestId, statusCode, timestampMs):

            var ret: [String: Any] = [
                type(of: self).CoderKeyStatus: type(of: self).SuccessName,
            ]
            
            if let requestId = requestId {
                ret[type(of: self).CoderKeyRequestId] = requestId
            }
            
            if let statusCode = statusCode {
                ret[type(of: self).CoderKeyStatusCode] = statusCode
            }
            
            if let timestampMs = timestampMs {
                ret[type(of: self).CoderKeyTimestampMs] = timestampMs
            }
            
            return ret
            
        case let .failure(reason):
            
            var ret: [String: Any] = [
                type(of: self).CoderKeyStatus: type(of: self).FailureName,
            ]
            
            if let statusCode = reason.httpStatusCode?.rawValue {
                ret[type(of: self).CoderKeyStatusCode] = statusCode
            }
            
            return ret
            
        case .notAttemptedDueToPriorFailure:
            return [
                type(of: self).NotAttemptedName,
            ]
        }
    }
    
    public init?(json: AferoJSONCodedType?) {
        
        guard let jsonDict = json as? [String: Any] else {
            DDLogWarn("Unable to cast \(String(reflecting: json)) to [String: Any]; bailing.")
            return nil
        }
        
        guard let statusName = jsonDict[type(of: self).CoderKeyStatus] as? String else {
            DDLogError("Unable to extract status from \(jsonDict); bailing.")
            return nil
        }
        
        var statusCode: HTTPStatusCode? = nil
        if let rawValue = jsonDict[type(of: self).CoderKeyStatusCode] as? Int {
            statusCode = HTTPStatusCode(rawValue: rawValue)
        }
        
        switch statusName {
            
        case type(of: self).SuccessName:

            self = .success(
                requestId: jsonDict[type(of: self).CoderKeyRequestId] as? Int,
                statusCode: statusCode,
                timestampMs: jsonDict[type(of: self).CoderKeyTimestampMs] as? NSNumber
            )
            
        case type(of: self).FailureName:

            self = .failure(reason: DeviceBatchAction.Error.Reason(statusCode: statusCode))
            
        case type(of: self).NotAttemptedName:
            self = .notAttemptedDueToPriorFailure
            
        default:
            DDLogError("Unrecognized statusName \(statusName); bailing.")
            return nil
            
        }
        
    }
}

public extension Sequence where Iterator.Element == AttributeInstance {
    
    /// Return an array of attributeWrite requests for this sequence
    
    var batchActionRequests: [DeviceBatchAction.Request]? {
        let ret = try? map {
            (instance: AttributeInstance) -> DeviceBatchAction.Request in
            guard let stringValue = instance.value.stringValue else {
                throw "Unable to convert \(instance) to stringValue; skipping"
            }
            return DeviceBatchAction.Request.attributeWrite(attributeId: instance.id, value: stringValue)
        }
        return ret
    }
    
}

public extension Sequence where Iterator.Element == DeviceBatchAction.Request {
    
    public var successfulUnpostedResults: DeviceBatchAction.Results {
        return DeviceBatchAction.Results(requests: Array(self), responses: map { _ -> DeviceBatchAction.Response in return .success(requestId: nil, statusCode: nil, timestampMs: 0) })
    }
}
