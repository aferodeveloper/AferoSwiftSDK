---
author: Justin Middleton
title: "Afero REST API Client"
date: 2017-Jul-09 09:29:0
status: 1.0
---

**AFERO CONFIDENTIAL AND PROPRIETARY INFORMATION**

© Copyright 2017 Afero, Inc, All Rights Reserved.

Any use and distribution of this software is subject to the terms
of the License and Services Agreement between Afero, Inc. and licensee.

SDK products contain certain trade secrets, patents, confidential and
proprietary information of Afero.  Use, reproduction, disclosure
and distribution by any means are prohibited, except pursuant to
a written license from Afero. Use of copyright notice is
precautionary and does not imply publication or disclosure.

**Restricted Rights Legend:**

Use, duplication, or disclosure by the Government is subject to
restrictions as set forth in subparagraph (c)(1)(ii) of The
Rights in Technical Data and Computer Software clause in DFARS
252.227-7013 or subparagraphs (c)(1) and (2) of the Commercial
Computer Software--Restricted Rights at 48 CFR 52.227-19, as
applicable.

# Afero REST API Client

Interaction with the Afero Cloud and Afero Devices involves two network touchpoints:

* The `DeviceEventStream` for realtime updates to connected device state, and
* The REST api for OAuth2 authentication, account creation and management,
  peripheral device management, and more.

This document describes functionality available via the Afero REST Client API,
as well as features available to developers to ease implementation.

# In This Document

* [Implementation Options](#implementation-options)
   * [Using the AFNetworking-based Client](#using-the-afnetworking-based-client)
   * [Integrating With an Existing Client](#integrating-with-an-existing-client)
* [OAuth2 Authentication and Refresh](#oauth2-authentication-and-refresh)
   * [Authentication](#authentication)
   * [Refresh](#refresh)
* [AferoAPIClientProto Extensions](#aferoapiclientproto-extensions)
   * [Account Creation and Management](#account-creation-and-management)
   * [Device Association and Disassociation](#device-association-and-disassociation)

# Implementation Options

The Afero SDK provides a few options for implementation of a REST api:

1. Developers can choose a readymade solution based upon `AFNetworking 3.1`
   that provides an implementation for OAuth2 authentication and refresh.
2. Developers who already have an HTTP client or do not wish to use `AFNetworking`
   may integrate with their preferred client by implementing a simple protocol,
   `AferoAPIClientProto`. Doing so provides all the benefits of (1), but Developers
   are required to implement their own OAuth authentication, refresh, and token
   storage logic.

> **NOTE**
>
> While it is possible to write an API Client from scratch that does not conform to
> `AferoAPIClientProto`, there are APIs in the SDK which require a class with
> such conformance.

## Using the AFNetworking-based Client

To use the `AFNetworking` client provided in the SDK, developers simply have
to to reference the appropriate subspec in their `Podfile`:

```ruby
pod 'AferoSwiftSDK/AFNetworking'    
```

This will automatically pull in in the core `AferoSwiftSDK` code, so no other
subspec references are required.

## Integrating With an Existing Client

If you have an existing HTTP client library you would like to use, the core
`AferoSwiftSDK` implementation vends a protocol, [`AferoAPIClientProto`][AferoAPIClientProto], conformance
to which you can add to your client. Doing so will provide the same rich set of
methods for interacting with the Afero Cloud as is available in the `AFNetworking`-based
client.

To include the SDK in your project without importing the provided `AFNetworking`-based
client, simply reference the main pod in your `Podfile`:

```ruby
pod 'AferoSwiftSDK'
```

[AferoAPIClientProto]: Reference/AferoAPIClientProto.html

# OAuth2 Authentication and Refresh

The Afero Cloud uses OAuth2 for authentication. All provided API calls attempt
to refresh tokens OAuth2 credentials prior to failing, whenever a call fails
due to a `401 Unauthorized` HTTP response from the Afero cloud. Refresh logic
is delegated to the individual client implementation.

## Authentication

The provided [`AFNetworkingAferoAPIClient`](#appendix-1-afnetworkingaferoapiclient)
provides the following methods related to authentication:

* `signIn(username: String, password: String, scope: String = default) -> Promise<Void>`
* `signOut(_ error: Error? = default) -> Promise<Void>`

See [Appendix 1: AFNetworkingAferoAPIClient](#appendix-1-afnetworkingaferoapiclient) for details.

## Refresh

The provided [`AFNetworkingAferoAPIClient`](#appendix-1-afnetworkingaferoapiclient)
provides refresh and automatic sign-out logic automatically.

When implementing `AferoAPIClientProto` on an existing class, two methods are of
interest:

```swift
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
```    

`doRefreshOAuth(_:_:_:)` is called whenever a `401` is received as a response from the
Afero cloud. It is expected that implementors will perform refresh and persist
their new credentials in a threadsafe manner prior to calling `success()`.

`doSignOut(_:_:)` is called automatically when `doRefreshOAuthOauth(_:_:_:)` fails.
This is your client's chance to purge existing OAuth2 credentials and signal the
rest of your app that it is no longer signed in.

See [Appendix 2: AferoAPIClientProto](#appendix-2-aferoapiclientproto) for details.

# AferoAPIClientProto Extensions

Through extentions to `AferoAPIClientProto`, a rich set of high-level methods is
exposed for interacting with the Afero Cloud Client API. These calls
return [Promises][PromiseKit][^1] which resolve to their results. For more information
regarding [Promises][PromiseKit], see https://github.com/mxcl/PromiseKit.

[^1]: [PromiseKit]: Promises for Swift and Objective-C

[PromiseKit]: https://github.com/mxcl/PromiseKit

# Account Creation and Management

## Create an Account

```swift
/// Create an account.
/// - parameter credentialID: The user ID (i.e. email)
/// - parameter password: The user's password
/// - parameter firstName: User firstname
/// - parameter lastName: User lastname
/// - parameter credentialType: The type of credential to use; defaults to "email"
/// - parameter verified: Whether or not the account should be created with a
///             verified stated. Defaults to false.
/// - parameter accountType: Defaults to "CUSTOMER"
/// - parameter accountDescription: Defaults to "Primary Account"
/// - returns: A `Promse<Any>` with the deserialized JSON results.

public func createAccount(_ credentialId: String, password: String, firstName: String, lastName: String, credentialType: String = default, verified: Bool = default, accountType: String = default, accountDescription: String = default) -> Promise<Any?>
```

> **NOTE**
>
> Account verification is not currently enforced.

## Update an Account's Description

```swift
/// Set an account's description.
/// - parameter accountId: The id of the account being modified
/// - parameter description: The new description of the account
public func setAccountDescription(_ accountId: String, description: String) -> Promise<Void>
```

## Reset Password

```swift
/// Request a password reset for the given `credentialId` (email).
/// An email with password reset instructions will be sent to the
/// provided email.
///
/// - parameter credentialId: The email address associated with the account.
/// - returns: A `Promise<Void>` indicating success or failure.
public func resetPassword(_ credentialId: String) -> Promise<Void>
```

## Fetch Account Info

```swift
/// Fetch a users's account info.
public func fetchAccountInfo() -> Promise<UserAccount.User>
```

## Update mobile device info

> **IMPORTANT**
>
> `mobileDeviceId` is an identifier for the the device on which
> your app is running. It is used both to obtain authorization to communicate with
> realtime Afero Cloud device state updates, iand to manage service-based
> information related to state of the mobile device on the Afero cloud, such as
> push notification routing.
>
> `mobileDeviceId` should be a UUID generated and persisted
> specifically for this purpose. It **must not** be any identifier
> provided by the platform for any other purpose, such as
> `UDID` or advertising identifier.

```swift
/// Send device environment info to the service, return a promise.
///
/// - parameter userId: The id of the signed-in user. Can be obtained
///                     via `UserAccount.User.userId`
/// - parameter mobileDeviceId: The app-generated `UUID` for this device.
/// - parameter apnsToken: A valid APNS token, if any.
/// - returns: A `Promise<Void>`
///
///  **Important**
///
/// `mobileDeviceId` is an identifier for the the device on which
/// your app is running. It is used both to obtain authorization to communicate with
/// realtime Afero Cloud device state updates, iand to manage service-based
/// information related to state of the mobile device on the Afero cloud, such as
/// push notification routing.
///
/// `mobileDeviceId` should be a UUID generated and persisted
/// specifically for this purpose. It **must not** be any identifier
/// provided by the platform for any other purpose, such as
/// `UDID` or advertising identifier.

public func updateDeviceInfo(userId: String, mobileDeviceId: String, apnsToken: Data? = default) -> Promise<Void>

```
## Disassociate mobile device info

> **IMPORTANT**
>
> `mobileDeviceId` is an identifier for the the device on which
> your app is running. It is used both to obtain authorization to communicate with
> realtime Afero Cloud device state updates, and to manage service-based
> information related to state of the mobile device on the Afero cloud, such as
> push notification routing.
>
> `mobileDeviceId` should be a UUID generated and persisted
> specifically for this purpose. It **must not** be any identifier
> provided by the platform for any other purpose, such as
> `UDID` or advertising identifier.

```swift
/// Clear the service's record of this device's association with the given user.
///
/// - parameter userId: The `userId` (NOT `accountId`) for the disassociation.
/// - parameter mobileDeviceId: The app-generated `UUID` for this device.
/// - warning: This will include nuking the association between this device
///             and its APNS token on the service, among other things.
///
///  **Important**
///
/// `mobileDeviceId` is an identifier for the the device on which
/// your app is running. It is used both to obtain authorization to communicate with
/// realtime Afero Cloud device state updates, iand to manage service-based
/// information related to state of the mobile device on the Afero cloud, such as
/// push notification routing.
///
/// `mobileDeviceId` should be a UUID generated and persisted
/// specifically for this purpose. It **must not** be any identifier
/// provided by the platform for any other purpose, such as
/// `UDID` or advertising identifier.

public func disassociateMobileDeviceData(userId: String, mobileDeviceId: String, attemptOAuthRefresh: Bool = default) -> Promise<Void>
```

# Appendix 1: `AFNetworkingAferoAPIClient`

`AFNetworkingAferoAPIClient` provides a default implementation of `AferoAPIClientProto`.


```swift

public AFNetworkingAferoAPIClient: AferoAPIClientProto {

    static public let shared: AFNetworkingAferoAPIClient

    /// Attempt to obtain a valid OAUTH2 token from the service.
    /// - parameter username: The "username" (currently email address) to use to
    ///                       authenticate to the service.
    /// - parameter password: The password to use for authentication
    /// - parameter scope: Should always be `account` (the default)
    /// - returns: A Promise<Void> which fulfills once the OAUTH2 token has been
    ///            successfully retrieved and stored,
    ///            and rejects on any failure.
    public func signIn(username: String, password: String, scope: String = default) -> Promise<Void>

    /// Clear all OAuth2 credentials
    public func signOut(_ error: Error? = default) -> Promise<Void>
}

```

# Appendix 2: `AferoAPIClientProto`

```swift
/// A protocol specifying the minimum requirements for an API client which will
/// be extended to provide access to Afero REST Client API methods.

public protocol AferoAPIClientProto: class, DeviceBatchActionRequestable, DeviceAccountProfilesSource {

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
```
