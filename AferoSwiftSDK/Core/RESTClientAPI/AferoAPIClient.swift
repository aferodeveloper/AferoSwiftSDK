//
//  AferoAPIClient.swift
//  Pods
//
//  Created by Justin Middleton on 7/8/17.
//
//

import Foundation
import PromiseKit
import HTTPStatusCodes
import CoreLocation

/// A protocol specifying the minimum requirements for an API client which will
/// be extended to provide access to Afero REST Client API methods.

public protocol AferoAPIClientProto: class, DeviceAccountProfilesSource {
    
    var TAG: String { get }
    
    typealias AferoAPIClientProtoSuccess = ((URLSessionDataTask, Any?) -> Void)
    typealias AferoAPIClientProtoFailure = ((URLSessionDataTask?, Error) -> Void)
    
    /// Perform an `HTTP GET`.
    /// - parameter urlString: The fully-qualified URL string for the REST endpoint being invoked.
    /// - parameter parameters: Any parameters to include with the request.
    /// - parameter success: The closure to invoke upon successful `GET`.
    /// - parameter failure: The closure to invoke upon unsuccessful `GET`.
    func doGet(urlString: String, parameters: Any?, success: @escaping AferoAPIClientProtoSuccess, failure: @escaping AferoAPIClientProtoFailure) -> URLSessionDataTask?
    
    /// Perform an `HTTP PUT`.
    /// - parameter urlString: The fully-qualified URL string for the REST endpoint being invoked.
    /// - parameter parameters: Any parameters to include with the request.
    /// - parameter success: The closure to invoke upon successful `PUT`.
    /// - parameter failure: The closure to invoke upon unsuccessful `PUT`.
    func doPut(urlString: String, parameters: Any?, success: @escaping AferoAPIClientProtoSuccess, failure: @escaping AferoAPIClientProtoFailure) -> URLSessionDataTask?
    
    /// Perform an `HTTP POST`.
    /// - parameter urlString: The fully-qualified URL string for the REST endpoint being invoked.
    /// - parameter parameters: Any parameters to include with the request.
    /// - parameter success: The closure to invoke upon successful `POST`.
    /// - parameter failure: The closure to invoke upon unsuccessful `POST`.
    func doPost(urlString: String, parameters: Any?, success: @escaping AferoAPIClientProtoSuccess, failure: @escaping AferoAPIClientProtoFailure) -> URLSessionDataTask?
    
    /// Perform an `HTTP DELETE`.
    /// - parameter urlString: The fully-qualified URL string for the REST endpoint being invoked.
    /// - parameter parameters: Any parameters to include with the request.
    /// - parameter success: The closure to invoke upon successful `DELETE`.
    /// - parameter failure: The closure to invoke upon unsuccessful `DELETE`.
    func doDelete(urlString: String, parameters: Any?, success: @escaping AferoAPIClientProtoSuccess, failure: @escaping AferoAPIClientProtoFailure) -> URLSessionDataTask?
    
    /// Refresh the OAuth2 credential.
    /// - parameter passthroughError: An error, if any, to pass through to the
    ///                               `failure` closure upon unsuccessful refresh.
    /// - parameter success: The closure to execute upon success.
    /// - parameter failure: The closure to execute upon failure.
    /// - note: Implementors should pass `passthroughError`, if any, on to the `failure`
    ///         closure. If `passthroughError` is not provided, then the implementor
    ///         should forward its internal error.
    func doRefreshOAuth(passthroughError: Error?, success: @escaping ()->Void, failure: @escaping (Error)->Void)
    
    /// Perform signout. This should communicate signed-out status to all
    /// interested parties.
    /// - parameter error: The error, if any, that caused signout.
    
    func doSignOut(error: Error?, completion: @escaping ()->Void)
    
}

extension AferoAPIClientProto {
    
    var TAG: String { return "\(type(of: self))" }
}

// MARK: - OAuth Refresh/Retry -

extension AferoAPIClientProto {

    /// Attempt to refresh OAuth (delegating to the underlying
    /// client implementation), and delegate signout to the
    /// underlying implementation if unsuccessful.
    /// - parameter passhthroughError: The error that, if present,
    ///             will be passed through to the signout process.
    func refreshOAuth(passthroughError: Error? = nil) -> Promise<Void> {
        
        NSLog("Requesting oauth refresh")
        
        return Promise {
            
            [weak self] fulfill, reject in
            
            self?.doRefreshOAuth(
                passthroughError: passthroughError,
                success: { _ = fulfill() }) {
                    error in self?.doSignOut(error: error) {
                        reject(error)
                    }
            }
            
        }
    }
    
    typealias WrappableAPIPromise = Promise<(URLSessionDataTask, Any?)>
    
    /// Wrapper for HTTP calls to handle more, which automatically attempts token refresh on a 401.
    
    func wrap(attemptingOAuthRefresh: Bool = true, body: @escaping () -> WrappableAPIPromise) -> WrappableAPIPromise {
        
        func attempt() -> WrappableAPIPromise {
            
            return body().recover {
                (err: Error) -> WrappableAPIPromise in
                guard let errCode = (err as NSError).httpStatusCodeValue else { throw(err) }
                
                if errCode == .unauthorized {
                    
                    NSLog("Got 401ed; attempting refresh.")
                    
                    if !attemptingOAuthRefresh { throw err }
                    
                    return self.refreshOAuth(passthroughError: err).then {
                        credential -> WrappableAPIPromise in
                        NSLog("Refresh successful; retrying request.")
                        return body()
                    }
                }
                
                throw(err)
            }
        }
        
        return attempt()
    }
    
}

// MARK: - Method Primitives -

extension AferoAPIClientProto {
    
    public typealias Parameters = [String: Any]
    public typealias ResponseBody = AferoJSONObject
    
}

// MARK: - POST Primitives -

public extension AferoAPIClientProto {
    
    func POST<U: AferoJSONCoding>(_ path: String, objects: [U]! = [], expansions: [String]? = nil, additionalParams: [String: String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> Promise<Any?> {
        return POST(path, parameters: objects.map { $0.JSONDict! }, expansions: expansions, additionalParams: additionalParams, attemptOAuthRefresh: attemptOAuthRefresh, errorDomain: errorDomain).then {
            _, result in return result
        }
    }
    
    func POST<U: AferoJSONCoding>(_ path: String, objects: [U]! = [], expansions: [String]? = nil, additionalParams: [String: String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> Promise<[String: Any]> {
        
        return POST(path, parameters: objects.map { $0.JSONDict! }, expansions: expansions, additionalParams: additionalParams, attemptOAuthRefresh: attemptOAuthRefresh, errorDomain: errorDomain).then {
            (_, result) throws -> [String: Any] in
            guard let ret = result as? [String: Any] else {
                throw(NSError(code: .unexpectedResultType, localizedDescription: "Unexpected Result."))
            }
            return ret
        }
    }
    
    func POST<T: AferoJSONCoding, U: AferoJSONCoding>(_ path: String, objects: [U]! = [], expansions: [String]? = nil, additionalParams: [String: String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> Promise<T?> {
        return POST(path, parameters: objects.map { $0.JSONDict! }, expansions: expansions, additionalParams: additionalParams, attemptOAuthRefresh: attemptOAuthRefresh, errorDomain: errorDomain).then {
            (task, result) throws -> T? in
            return try marshall(result)
        }
    }
    
    func POST<T: AferoJSONCoding, U: AferoJSONCoding>(_ path: String, object: U, expansions: [String]? = nil, additionalParams: [String: String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> Promise<T?> {
        return POST(path, parameters: object.JSONDict, expansions: expansions, additionalParams: additionalParams, attemptOAuthRefresh: attemptOAuthRefresh, errorDomain: errorDomain)
    }
    
    func POST<T: AferoJSONCoding>(_ path: String, parameters: Any! = nil, expansions: [String]? = nil, additionalParams: [String: String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> Promise<T> {
        
        return POST(path, parameters: parameters, expansions: expansions, additionalParams: additionalParams, attemptOAuthRefresh: attemptOAuthRefresh, errorDomain: errorDomain).then {
            (maybeResult: T?) throws -> T in guard let result = maybeResult else {
                throw(NSError(code: APIErrorCode.unexpectedResultType, localizedDescription: "Unable to unwrap expected non-nil value."))
            }
            return result
        }
    }
    
    func POST<T: AferoJSONCoding, U: AferoJSONCoding>(_ path: String, object: U, expansions: [String]? = nil, additionalParams: [String: String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> Promise<T> {
        return POST(path, parameters: object.JSONDict, expansions: expansions, additionalParams: additionalParams, attemptOAuthRefresh: attemptOAuthRefresh, errorDomain: errorDomain)
    }
    
    func POST<T: AferoJSONCoding, U: AferoJSONCoding>(_ path: String, objects: [U]! = [], expansions: [String]? = nil, additionalParams: [String: String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> Promise<[T]?> {
        return POST(path, parameters: objects.map { $0.JSONDict! }, expansions: expansions, additionalParams: additionalParams, attemptOAuthRefresh: attemptOAuthRefresh, errorDomain: errorDomain).then {
            (task, result) -> [T]? in
            return try marshall(result)
        }
    }
    
    /// POST to path, and return the non-optional marshalled results.
    ///
    /// - parameter path: The path (relative to the service host) to GET.
    ///
    /// - parameter parameters: Any parameters to pass along (will be appended as GET params)
    ///
    /// - parameter attemptOAuthRefresh: If true (the default), OAUTH refresh will be attempted prior to signing out upon a 401.
    ///
    /// - parameter errorDomain: The optional error domain to use when loggin/reporting errors.
    ///                          Defaults to the function name.
    ///
    /// - returns: A `Promise<[T]>`
    /// - note: Returned promise resolves with with an `NSError` if the result is nil.
    
    func POST<T: AferoJSONCoding>(_ path: String, parameters: Any! = nil, expansions: [String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> Promise<[T]> {
        
        return POST(path, parameters: parameters, expansions: expansions, attemptOAuthRefresh: attemptOAuthRefresh, errorDomain: errorDomain).then {
            (maybeResult: [T]?) throws -> [T] in guard let result = maybeResult else {
                throw(NSError(code: APIErrorCode.unexpectedResultType, localizedDescription: "Unable to unwrap expected non-nil value."))
            }
            return result
        }
    }
    
    
    func POST(_ path: String, parameters: Any! = Parameters(), expansions: [String]? = nil, additionalParams: [String: String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> Promise<[String: Any]> {
        
        return POST(path, parameters: parameters, expansions: expansions, additionalParams: additionalParams, attemptOAuthRefresh: attemptOAuthRefresh, errorDomain: errorDomain).then {
            (task, result) throws -> [String: Any] in
            guard let ret = result as? [String: Any] else {
                throw(NSError(code: .unexpectedResultType, localizedDescription: "Unexpected Result."))
            }
            return ret
        }
    }
    
    func POST(_ path: String, parameters: Any! = Parameters(), expansions: [String]? = nil, additionalParams: [String: String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> Promise<Any?> {
        return POST(path, parameters: parameters, expansions: expansions, additionalParams: additionalParams, attemptOAuthRefresh: attemptOAuthRefresh, errorDomain: errorDomain).then {
            (task, result) -> Any? in return result
        }
    }
    
    func POST(_ path: String, parameters: Any! = Parameters(), expansions: [String]? = nil, additionalParams: [String: String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> Promise<Void> {
        return POST(path, parameters: parameters, expansions: expansions, additionalParams: additionalParams, attemptOAuthRefresh: attemptOAuthRefresh, errorDomain: errorDomain).then {
            _, _ in return
        }
    }
    
    func POST<T: AferoJSONCoding>(_ path: String, parameters: Any! = Parameters(), expansions: [String]? = nil, additionalParams: [String: String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> Promise<T?> {
        return POST(path, parameters: parameters, expansions: expansions, additionalParams: additionalParams, attemptOAuthRefresh: attemptOAuthRefresh, errorDomain: errorDomain).then {
            (task, result) -> T? in
            return try marshall(result)
        }
    }
    
    func POST<T: AferoJSONCoding>(_ path: String, parameters: Any! = Parameters(), expansions: [String]? = nil, additionalParams: [String: String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> Promise<[T]?> {
        return POST(path, parameters: parameters, expansions: expansions, additionalParams: additionalParams, attemptOAuthRefresh: attemptOAuthRefresh, errorDomain: errorDomain).then {
            (task, result) -> [T]? in
            return try marshall(result)
        }
    }
    
    /// POST a path.
    ///
    /// - parameter path: The path (relative to the service host) to GET.
    ///
    /// - parameter expansions: fields to expand, if any, in the response.
    ///
    /// - parameter additionalParams: Additional parameters to be added to the URL.
    ///
    /// - parameter attemptOAuthRefresh: If true (the default), OAUTH refresh will be attempted prior to signing out upon a 401.
    ///
    /// - parameter parameters: Any parameters to pass along (will be appended as GET params)
    ///
    /// - parameter expansions: fields to expand, if any, in the response.
    
    internal func POST(_ path: String, parameters: Any! = Parameters(), expansions: [String]? = nil, additionalParams: [String: String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> WrappableAPIPromise
    {
        let localPath = withExpansions(path, expansions: expansions, additionalParams: additionalParams)
        
        return wrap(attemptingOAuthRefresh: attemptOAuthRefresh) {
            
            return Promise {
                
                fulfill, reject in
                
                _ = self.doPost(
                    urlString: localPath,
                    parameters: parameters,
                    success: { (task, result) -> Void in
                        asyncGlobalDefault {
                            fulfill((task, result))
                        }
                }) { (task, error) -> Void in
                    asyncGlobalDefault {
                        reject(error)
                    }
                } // failure
            } // promise
        } // wrap
    }
    
}

// MARK: - GET Primitives -

public extension AferoAPIClientProto {
    
    /// GET a path, and throw away the results..
    ///
    /// - parameter path: The path (relative to the service host) to GET.
    ///
    /// - parameter parameters: Any parameters to pass along (will be appended as GET params)
    ///
    /// - parameter attemptOAuthRefresh: If true (the default), OAUTH refresh will be attempted prior to signing out upon a 401.
    ///
    /// - parameter errorDomain: The optional error domain to use when loggin/reporting errors.
    ///                          Defaults to the function name.
    ///
    /// - returns: A `Promise<Void>`
    
    func GET(_ path: String, parameters: Any! = nil, expansions: [String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> Promise<Void> {
        return GET(path, parameters: parameters, expansions: expansions, attemptOAuthRefresh: attemptOAuthRefresh, errorDomain: errorDomain).then { _, _ in return }
    }
    
    /// GET a path, and return the marshalled results (tolerating nil)
    ///
    /// - parameter path: The path (relative to the service host) to GET.
    ///
    /// - parameter parameters: Any parameters to pass along (will be appended as GET params)
    ///
    /// - parameter attemptOAuthRefresh: If true (the default), OAUTH refresh will be attempted prior to signing out upon a 401.
    ///
    /// - parameter errorDomain: The optional error domain to use when loggin/reporting errors.
    ///                          Defaults to the function name.
    ///
    /// - returns: A `Promise<T?>`
    
    func GET<T: AferoJSONCoding>(_ path: String, parameters: Any! = nil, expansions: [String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> Promise<T?> {
        return GET(path, parameters: parameters, expansions: expansions, attemptOAuthRefresh: attemptOAuthRefresh, errorDomain: errorDomain).then {
            _, result in return try marshall(result)
        }
    }
    
    /// GET a path, and return the non-optional marshalled results.
    ///
    /// - parameter path: The path (relative to the service host) to GET.
    ///
    /// - parameter parameters: Any parameters to pass along (will be appended as GET params)
    ///
    /// - parameter attemptOAuthRefresh: If true (the default), OAUTH refresh will be attempted prior to signing out upon a 401.
    ///
    /// - parameter errorDomain: The optional error domain to use when loggin/reporting errors.
    ///                          Defaults to the function name.
    ///
    /// - returns: A `Promise<T>`
    /// - note: Returned promise resolves with with an `NSError` if the result is nil.
    
    func GET<T: AferoJSONCoding>(_ path: String, parameters: Any! = nil, expansions: [String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> Promise<T> {
        
        return GET(path, parameters: parameters, expansions: expansions, attemptOAuthRefresh: attemptOAuthRefresh, errorDomain: errorDomain).then {
            (maybeResult: T?) throws -> T in guard let result = maybeResult else {
                throw(NSError(code: APIErrorCode.unexpectedResultType, localizedDescription: "Unable to unwrap expected non-nil value."))
            }
            return result
        }
    }
    
    /// GET a path, and return the optional marshalled results.
    ///
    /// - parameter path: The path (relative to the service host) to GET.
    ///
    /// - parameter parameters: Any parameters to pass along (will be appended as GET params)
    ///
    /// - parameter attemptOAuthRefresh: If true (the default), OAUTH refresh will be attempted prior to signing out upon a 401.
    ///
    /// - parameter errorDomain: The optional error domain to use when loggin/reporting errors.
    ///                          Defaults to the function name.
    ///
    /// - returns: A `Promise<[T]?>`
    
    func GET<T: AferoJSONCoding>(_ path: String, parameters: Any! = nil, expansions: [String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> Promise<[T]?> {
        return GET(path, parameters: parameters, expansions: expansions, attemptOAuthRefresh: attemptOAuthRefresh, errorDomain: errorDomain).then {
            _, result in return try marshall(result)
        }
    }
    
    /// GET a path, and return the non-optional marshalled results.
    ///
    /// - parameter path: The path (relative to the service host) to GET.
    ///
    /// - parameter parameters: Any parameters to pass along (will be appended as GET params)
    ///
    /// - parameter attemptOAuthRefresh: If true (the default), OAUTH refresh will be attempted prior to signing out upon a 401.
    ///
    /// - parameter errorDomain: The optional error domain to use when loggin/reporting errors.
    ///                          Defaults to the function name.
    ///
    /// - returns: A `Promise<[T]>`
    /// - note: Returned promise resolves with with an `NSError` if the result is nil.
    
    func GET<T: AferoJSONCoding>(_ path: String, parameters: Any! = nil, expansions: [String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> Promise<[T]> {
        
        return GET(path, parameters: parameters, expansions: expansions, attemptOAuthRefresh: attemptOAuthRefresh, errorDomain: errorDomain).then {
            (maybeResult: [T]?) throws -> [T] in guard let result = maybeResult else {
                throw(NSError(code: APIErrorCode.unexpectedResultType, localizedDescription: "Unable to unwrap expected non-nil value."))
            }
            return result
        }
    }

    /// GET a path, and return the non-optional marshalled results.
    ///
    /// - parameter path: The path (relative to the service host) to GET.
    ///
    /// - parameter parameters: Any parameters to pass along (will be appended as GET params)
    ///
    /// - parameter attemptOAuthRefresh: If true (the default), OAUTH refresh will be attempted prior to signing out upon a 401.
    ///
    /// - parameter errorDomain: The optional error domain to use when loggin/reporting errors.
    ///                          Defaults to the function name.
    ///
    /// - returns: A `Promise<[T]>`
    /// - note: Returned promise resolves with with an `NSError` if the result is nil.
    
    func GET(_ path: String, parameters: Any! = nil, expansions: [String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> Promise<[[String: Any]]> {
        
        return GET(path, parameters: parameters, expansions: expansions, attemptOAuthRefresh: attemptOAuthRefresh, errorDomain: errorDomain).then {
            (maybeResult: Any?) throws -> [[String: Any]] in guard let result = maybeResult as? [[String: Any]] else {
                throw(NSError(code: APIErrorCode.unexpectedResultType, localizedDescription: "Unable to unwrap expected non-nil value."))
            }
            return result
        }
    }

    /// GET a path, and return the optional raw results.
    ///
    /// - parameter path: The path (relative to the service host) to GET.
    ///
    /// - parameter parameters: Any parameters to pass along (will be appended as GET params)
    ///
    /// - parameter attemptOAuthRefresh: If true (the default), OAUTH refresh will be attempted prior to signing out upon a 401.
    ///
    /// - parameter errorDomain: The optional error domain to use when loggin/reporting errors.
    ///                          Defaults to the function name.
    ///
    /// - returns: A `Promise<Any?>`
    
    
    func GET(_ path: String, parameters: Any! = nil, expansions: [String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> Promise<Any?> {
        return GET(path, parameters: parameters, expansions: expansions, attemptOAuthRefresh: attemptOAuthRefresh, errorDomain: errorDomain).then {
            _, result in return result
        }
    }
    
    /// GET a path, and return the non-optional raw results.
    ///
    /// - parameter path: The path (relative to the service host) to GET.
    ///
    /// - parameter parameters: Any parameters to pass along (will be appended as GET params)
    ///
    /// - parameter attemptOAuthRefresh: If true (the default), OAUTH refresh will be attempted prior to signing out upon a 401.
    ///
    /// - parameter errorDomain: The optional error domain to use when loggin/reporting errors.
    ///                          Defaults to the function name.
    ///
    /// - returns: A `Promise<Any>`
    /// - note: Returned promise resolves with with an `NSError` if the result is nil.
    
    func GET(_ path: String, parameters: Any! = nil, expansions: [String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> Promise<Any> {
        
        return GET(path, parameters: parameters, expansions: expansions, attemptOAuthRefresh: attemptOAuthRefresh, errorDomain: errorDomain).then {
            (maybeResult: Any?) throws -> Any in guard let result = maybeResult else {
                throw(NSError(code: APIErrorCode.unexpectedResultType, localizedDescription: "Unable to unwrap expected non-nil value."))
            }
            return result
        }
    }
    
    /// GET a path.
    ///
    /// - parameter path: The path (relative to the service host) to GET.
    ///
    /// - parameter parameters: Any parameters to pass along (will be appended as GET params)
    ///
    /// - parameter expansions: fields to expand, if any, in the response.
    ///
    /// - parameter attemptOAuthRefresh: If true (the default), OAUTH refresh will be attempted prior to signing out upon a 401.
    
    internal func GET(_ path: String, parameters: Any! = nil, expansions: [String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> WrappableAPIPromise
    {
        
        let localPath = withExpansions(path, expansions: expansions)
        
        return wrap(attemptingOAuthRefresh: attemptOAuthRefresh) {
            
            return Promise {
                
                fulfill, reject in
                
                _ = self.doGet(
                    urlString: localPath,
                    parameters: parameters,
                    success: { (task, result) -> Void in
                        asyncGlobalDefault {
                            fulfill((task, result))
                        }
                }) { (task, error) -> Void in
                    asyncGlobalDefault {
                        reject(error)
                    }
                } // failure
            } // Promise
        } // wrap
        
    }
    
}

// MARK: - DELETE Primitives -

public extension AferoAPIClientProto {
    
    func DELETE(_ path: String, parameters: Any! = nil, expansions: [String]? = nil, additionalParams: [String: String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> Promise<Void> {
        return DELETE(path, parameters: parameters, expansions: expansions, additionalParams: additionalParams, attemptOAuthRefresh: attemptOAuthRefresh, errorDomain: errorDomain).then {
            _, _ in return
        }
    }
    
    internal func DELETE(_ path: String, parameters: Any! = nil, expansions: [String]? = nil, additionalParams: [String: String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> WrappableAPIPromise
    {
        let localPath = withExpansions(path, expansions: expansions, additionalParams: additionalParams)
        
        return wrap(attemptingOAuthRefresh: attemptOAuthRefresh) {
            
            return Promise {
                fulfill, reject in
                
                _ = self.doDelete(
                    urlString: localPath,
                    parameters: parameters,
                    success: { (task, result) -> Void in
                        asyncGlobalDefault {
                            fulfill((task, result))
                        }
                }) { (task, error) -> Void in
                    asyncGlobalDefault {
                        reject(error)
                    }
                } // failure
            } // Promise
        } // wrap
        
    }
    
    
}

// MARK: - PUT Primitives -

public extension AferoAPIClientProto {
    
    /// PUT a path.
    ///
    /// - parameter path: The path (relative to the service host) to GET.
    ///
    /// - parameter parameters: Any parameters to pass along
    ///
    /// - parameter expansions: fields to expand, if any, in the response.
    ///
    /// - parameter additionalParams: Additional parameters to be added to the URL.
    ///
    /// - parameter attemptOAuthRefresh: If true (the default), OAUTH refresh will be attempted prior to signing out upon a 401.
    
    func PUT<T: AferoJSONCoding>(_ path: String, parameters: Any! = nil, expansions: [String]? = nil, additionalParams: [String: String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> Promise<T?> {
        return PUT(path, parameters: parameters, expansions: expansions, additionalParams: additionalParams, attemptOAuthRefresh: attemptOAuthRefresh, errorDomain: errorDomain).then {
            _, result in return try marshall(result)
        }
    }
    
    func PUT<T: AferoJSONCoding, U: AferoJSONCoding>(_ path: String, object: U, expansions: [String]? = nil, additionalParams: [String: String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> Promise<T?> {
        return PUT(path, parameters: object.JSONDict, expansions: expansions, additionalParams: additionalParams, attemptOAuthRefresh: attemptOAuthRefresh, errorDomain: errorDomain)
    }
    
    func PUT<T: AferoJSONCoding>(_ path: String, parameters: Any! = nil, expansions: [String]? = nil, additionalParams: [String: String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> Promise<T> {
        
        return PUT(path, parameters: parameters, expansions: expansions, additionalParams: additionalParams, attemptOAuthRefresh: attemptOAuthRefresh, errorDomain: errorDomain).then {
            (maybeResult: T?) throws -> T in guard let result = maybeResult else {
                throw(NSError(code: APIErrorCode.unexpectedResultType, localizedDescription: "Unable to unwrap expected non-nil value."))
            }
            return result
        }
    }
    
    func PUT<T: AferoJSONCoding, U: AferoJSONCoding>(_ path: String, object: U, expansions: [String]? = nil, additionalParams: [String: String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> Promise<T> {
        return PUT(path, parameters: object.JSONDict, expansions: expansions, additionalParams: additionalParams, attemptOAuthRefresh: attemptOAuthRefresh, errorDomain: errorDomain)
    }
    
    /// PUT a path.
    ///
    /// - parameter path: The path (relative to the service host) to GET.
    ///
    /// - parameter parameters: Any parameters to pass along
    ///
    /// - parameter expansions: fields to expand, if any, in the response.
    ///
    /// - parameter additionalParams: Additional parameters to be added to the URL.
    ///
    /// - parameter attemptOAuthRefresh: If true (the default), OAUTH refresh will be attempted prior to signing out upon a 401.
    
    func PUT<T: AferoJSONCoding>(_ path: String, parameters: Any! = nil, expansions: [String]? = nil, additionalParams: [String: String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> Promise<[T]?> {
        return PUT(path, parameters: parameters, expansions: expansions, additionalParams: additionalParams, attemptOAuthRefresh: attemptOAuthRefresh, errorDomain: errorDomain).then {
            _, result in return try marshall(result)
        }
    }
    
    /// PUT to path, and return the non-optional marshalled results.
    ///
    /// - parameter path: The path (relative to the service host) to GET.
    ///
    /// - parameter parameters: Any parameters to pass along (will be appended as GET params)
    ///
    /// - parameter attemptOAuthRefresh: If true (the default), OAUTH refresh will be attempted prior to signing out upon a 401.
    ///
    /// - parameter errorDomain: The optional error domain to use when loggin/reporting errors.
    ///                          Defaults to the function name.
    ///
    /// - returns: A `Promise<[T]>`
    /// - note: Returned promise resolves with with an `NSError` if the result is nil.
    
    func PUT<T: AferoJSONCoding>(_ path: String, parameters: Any! = nil, expansions: [String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> Promise<[T]> {
        
        return PUT(path, parameters: parameters, expansions: expansions, attemptOAuthRefresh: attemptOAuthRefresh, errorDomain: errorDomain).then {
            (maybeResult: [T]?) throws -> [T] in guard let result = maybeResult else {
                throw(NSError(code: APIErrorCode.unexpectedResultType, localizedDescription: "Unable to unwrap expected non-nil value."))
            }
            return result
        }
    }
    
    func PUT(_ path: String, parameters: Any! = Parameters(), expansions: [String]? = nil, additionalParams: [String: String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> Promise<[String: Any]> {
        
        return PUT(path, parameters: parameters, expansions: expansions, additionalParams: additionalParams, attemptOAuthRefresh: attemptOAuthRefresh, errorDomain: errorDomain).then {
            (task, result) throws -> [String: Any] in
            guard let ret = result as? [String: Any] else {
                throw(NSError(code: .unexpectedResultType, localizedDescription: "Unexpected Result."))
            }
            return ret
        }
    }
    
    func PUT(_ path: String, parameters: Any! = Parameters(), expansions: [String]? = nil, additionalParams: [String: String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> Promise<Any?> {
        return PUT(path, parameters: parameters, expansions: expansions, additionalParams: additionalParams, attemptOAuthRefresh: attemptOAuthRefresh, errorDomain: errorDomain).then {
            (task, result) -> Any? in return result
        }
    }
    
    func PUT<U: AferoJSONCoding>(_ path: String, object: U, expansions: [String]? = nil, additionalParams: [String: String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> Promise<Void> {
        return PUT(path, parameters: object.JSONDict, expansions: expansions, additionalParams: additionalParams, attemptOAuthRefresh: attemptOAuthRefresh, errorDomain: errorDomain)
    }
    
    func PUT(_ path: String, parameters: Any! = Parameters(), expansions: [String]? = nil, additionalParams: [String: String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> Promise<Void> {
        return PUT(path, parameters: parameters, expansions: expansions, additionalParams: additionalParams, attemptOAuthRefresh: attemptOAuthRefresh, errorDomain: errorDomain).then { _, _ in return }
    }
    
    /// PUT a path.
    ///
    ///  - parameter path: The path (relative to the service host) to GET.
    ///
    /// - parameter parameters: Any parameters to pass along
    ///
    /// - parameter expansions: fields to expand, if any, in the response.
    ///
    /// - parameter additionalParams: Additional parameters to be added to the URL.
    ///
    /// - parameter attemptOAuthRefresh: If true (the default), OAUTH refresh will be attempted prior to signing out upon a 401.
    
    internal func PUT(_ path: String, parameters: Any! = nil, expansions: [String]? = nil, additionalParams: [String: String]? = nil, attemptOAuthRefresh: Bool = true, errorDomain: String = #function) -> WrappableAPIPromise
    {
        let localPath = withExpansions(path, expansions: expansions, additionalParams: additionalParams)
        
        return wrap(attemptingOAuthRefresh: attemptOAuthRefresh) {
            
            return Promise {
                
                fulfill, reject in
                
                _ = self.doPut(
                    urlString: localPath,
                    parameters: parameters,
                    success: { (task, result) -> Void in
                        asyncGlobalDefault {
                            fulfill((task, result))
                        }
                }) { (task, error) -> Void in
                    asyncGlobalDefault {
                        reject(error)
                    }
                }
            }
        }
    }
    
}

// MARK: - New - style marshalling

private func marshall<T: AferoJSONCoding>(_ result: Any?) throws -> [T]? {
    
    guard let result = result else { return nil }
    
    guard let ret: [T] = |<(result as? [AferoJSONCodedType]) else {
        throw "Unexpected result: \(result)"
    }
    return ret
}

private func marshall<T: AferoJSONCoding>(_ result: Any?) throws -> T? {
    
    guard let result = result else { return nil }
    
    guard let ret: T = |<result else {
        throw "Unexpected result: \(result)"
    }
    return ret
}

// MARK: - Utilities

/// Given a path component of a URL, append provided expansions if any.
func withExpansions(_ path: String, expansions: [String]?, additionalParams: [String: String]? = [:]) -> String {
    
    var lpath = path
    
    var additionalPathParams: [String] = []
    
    if let expansionsString = expansions?.joined(separator: ",").queryAllowedURLEncodedString {
        additionalPathParams.append("expansions" + "=" + expansionsString)
    }
    
    if let additionalParams = additionalParams {
        for (k, v) in additionalParams {
            guard let key = k.pathAllowedURLEncodedString, let value = v.pathAllowedURLEncodedString else { continue }
            additionalPathParams.append(key + "=" + value)
        }
    }
    
    let additionalParamString = additionalPathParams.joined(separator: "&")
    
    if additionalParamString.isEmpty {
        return lpath
    }
    
    if let _ = lpath.index(of: "?") {
        lpath += "&" + additionalParamString
    } else {
        lpath += "?" + additionalParamString
    }
    
    return lpath
}

extension URLRequest {
    
    public var verboseDescription: String {
        
        #if INTERNAL
            
            let URLDescription = url?.debugDescription ?? "<none>"
            let methodDescription = httpMethod?.debugDescription ?? "<none>"
            let headerDescription = allHTTPHeaderFields?.debugDescription ?? "<none>"
            let bodyDescription = httpBody?.stringValue ?? httpBody?.debugDescription ?? ""
            
            return "    URL: \(URLDescription)\n    METHOD: \(methodDescription)\n    HEADERS: \(headerDescription)\n    BODY:\n<begin body>\(bodyDescription)<end body>\n"
            
        #else
            
            return debugDescription
            
        #endif
    }
}

extension URLResponse {
    
    public var verboseDescription: String {
        
        #if INTERNAL
            let URLDescription = url?.debugDescription ?? "<none>"
            let textEncodingName = self.textEncodingName ?? "<none>"
            return "    URL: \(URLDescription)\n    MIMEType: \(mimeType ?? "<nil>")\n    Text encoding: \(textEncodingName)"
        #else
            return debugDescription
        #endif
    }
    
}

extension HTTPURLResponse {
    
    override public var verboseDescription: String {
        
        #if INTERNAL
            let headerDescription = allHeaderFields.debugDescription
            let statusCodeDesc = HTTPURLResponse.localizedString(forStatusCode: statusCode)
            return super.verboseDescription + "\n    STATUS: \(statusCode) (\(statusCodeDesc)\n    HEADERS: \(headerDescription)"
        #else
            return debugDescription
        #endif
    }
    
}

extension URLSessionTask {
    
    override open var debugDescription: String {
        get {
            
            var requestDescription = "<nil>"
            if let maybeReqDesc = originalRequest?.verboseDescription {
                requestDescription = maybeReqDesc
            }
            
            var responseDescription = "<nil>"
            if let maybeRespDesc = response?.verboseDescription {
                responseDescription = maybeRespDesc
            }
            
            return super.debugDescription
                + "\n\(requestDescription)"
                + "\n\(responseDescription)"
        }
    }
}

enum APIErrorCode: Int {
    case unexpectedResultType = 100
    case notLoggedIn = 101
    case encodingFailure = 102 // Unable to percent encode string
    case badParameterError = 103
}

/**
 AFNetworking doesn't give us the response object by itself in the case of an error;
 the response is attached *to* the error. Add a convenient getter to the parsed data.
 */

extension NSError {
    
    convenience init(code: APIErrorCode, localizedDescription: String? = nil, underlyingError: NSError? = nil) {
        
        var userInfo: [String: Any] = [:]
        
        if let localizedDescription = localizedDescription {
            userInfo[NSLocalizedDescriptionKey] = localizedDescription
        }
        if let underlyingError = underlyingError {
            userInfo[NSUnderlyingErrorKey] = underlyingError
        }
        
        self.init(domain: "AferoAPIClient", code: code.rawValue, userInfo: userInfo)
    }
    
    static func UnexpectedResult(localizedDescription: String? = nil, underlyingError: NSError? = nil) -> NSError {
        return NSError(code: .unexpectedResultType, localizedDescription: localizedDescription, underlyingError: underlyingError)
    }
    
    static func NotLoggedIn(localizedDescription: String? = nil, underlyingError: NSError? = nil) -> NSError {
        return NSError(code: .notLoggedIn, localizedDescription: localizedDescription, underlyingError: underlyingError)
    }
    
    static func EncodingFailure(localizedDescription: String? = nil, underlyingError: NSError? = nil) -> NSError {
        return NSError(code: .encodingFailure, localizedDescription: localizedDescription, underlyingError: underlyingError)
    }
    
    static func BadParameter(localizedDescription: String? = nil, underlyingError: NSError? = nil) -> NSError {
        return NSError(code: .badParameterError, localizedDescription: localizedDescription, underlyingError: underlyingError)
    }
    
    
}

