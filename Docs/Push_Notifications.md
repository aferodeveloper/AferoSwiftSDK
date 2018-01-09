---
author: Justin Middleton
title: "Afero Push Notifications"
date: 2017-Jun-26 16:52:37 PDT
status: 1.0
---

# Afero Push Notifications


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

## In This Document

* [Introduction](#introduction)
* [Configure Your App](#configure-your-app)
  * [Configure to Receive Notifications](#configure-to-receive-notifications)
  * [Register Notification Details with Afero](#register-notification-details-with-afero)
  * [Afero Runtime Configuration](#afero-runtime-configuration)
* [Device Rules](#device-rules)
    * [Creating a Rule](#creating-a-rule)
    * [Advanced: Multiple Criteria, Relative Operations](#advanced-multiple-criteria-relative-operations)
    * [Fetching Existing Rules](#fetching-existing-rules)
    * [Modifying Existing Rules](#modifying-existing-rules)
* [Appendix 1: Account Rule Endpoints](#appendix-1-account-rule-endpoints)
* [Appendix 2: Full `DeviceRule` Schema](#appendix-2-full-devicerule-schema)
* [Appendix 3: Supported `extendedData` Fields](#appendix-3-supported-extendeddata-fields)

## Introduction

The Afero Cloud supports sending push notifications via Apple APNS and Google
Cloud Messenger (GCM). In addition to configuring your app for push notifications
with your OS vendor (not covered here), there are a number of steps you must take
to enable Afero to send push notifications to your apps.

> **NOTE**
>
> At present, only Production APNS is supported by the Afero cloud; Sandbox APNS
> is **not** currently supported.

## Configure Your App

Enabling notifications on our app comprises four steps:

1. [Configure your app to receive notifications from your platform vendor](#configure-to-receive-notifications).
2. [Register notification details with Afero](#register-notification-details-with-afero).
3. [Provide Afero with the necessary tokens](#afero-runtime-configuration).
4. Configure the [Device Rules](#device-rules) that determine what notifications
   will be set, and under what conditions.

### Configure to Receive Notifications

Before Afero can route notifications to your app, you'll need to configure your
app's project to receive remote notifications from your service of choice. Afero
supports [Apple APNS][apns-guide] and [Google Cloud Messaging][gcm-guide].

| Provider | Required Info |
| - | - |
| [Apple APNS][apns-guide] | Bundle ID, APNS Cert[^2]|
| [Google Cloud Messaging][gcm-guide] | GCM Project Number, Server API Key |

[^1]: [APNS Programming Guide][apns-guide]

[^2]: Note: [APNS provider auth tokens][apns-provider-auth-token] are not currently supported.

[^3]: [Google Cloud Messaging Guide][gcm-guide]

[apns-guide]: https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/HandlingRemoteNotifications.html#//apple_ref/doc/uid/TP40008194-CH6-SW1
[apns-provider-auth-token]: https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CommunicatingwithAPNs.html
[gcm-guide]: https://developers.google.com/cloud-messaging/android/client
[fcm-guide]: https://firebase.google.com/docs/cloud-messaging/


### Register Notification Details with Afero

> **_NOTE_**
>
> Push notification registration is currently in limited release with approved
> partners. All info should be provided via Jira tickets.

### Afero Runtime Configuration

Once your app has been registered with the Afero Cloud, you'll need to communicate
your app's remote notification token to the Afero Cloud whenever that token is
created or changed. It's your app's responsibility to prompt for permission and
register for notification according to your app's platform guidelines [^1][^3].

Upon successful acquisition of a notification token from your provider, your
app provides the token to Afero using the `mobileDevices`
endpoint.

#### Fields

| Name | Description | Example | Valid Values |
| - | - | - | - |
| `platform` | Your app's platform | `IOS` | `IOS`, `ANDROID` |
| `mobileDeviceId` | A UUID, generated and persisted by your app | `714936D4-31E6-42DA-8691-95632E235140` | Any UUID |
| `pushId` | The token provided by your platform. | | Plain text token. **Binary values must be Base64-encoded.** |
| `extendedData`[^4] | A dict which must contain at least your app ID | {"app_identifier": "io.afero.iTokui"} |

[^4]: [Extended Data Reference](#appendix-3-supported-extendedData-fields)

#### Request

`POST https://api.afero.io/v1/users/{userId}/mobileDevices`

```json
{
    "platform": "IOS",
    "mobileDeviceId": "714936D4-31E6-42DA-8691-95632E235140",
    "extendedData": {
        "app_identifier": "io.afero.iTokui",
    }
}
```

# Device Rules

Afero push notifications are based upon Afero `DeviceRule`s. A `DeviceRule` is a
service-side object that expresses *"When Attribute N of Device X enters
State S, perform these actions"*. `DeviceRule`s are very flexible and support
many options; for push notifications, we're only concerned with
the fields that define what device state will trigger the rule,
and the notification flags.

## Creating a Rule

In the first example, we're going to create a rule to send the notification
with the text, *"Power is on"* for a device with id `123456789`.

### Fields

| Field | JSON Key | Value | Notes |
| - | :-: | - | - |
| **Notification Text** | `label` | *Power is on* | |
| **AccountId** | *None, used in URI* | XXYYZZ | The id of the account the device is associated with |
| **Device ID** | `deviceFilterCriteria[n].deviceId` | 0123456789 | The id of the device which will trigger notifications |
| **Power Attribute** ID | `deviceFilterCriteria[n].attribute.id` | 100 | The id of the attribute to check for notification trigger |
| **Attribute Value for Power On** | `deviceFilterCriteria[n].attribute.value` | "1" | The value of the attribute that will trigger the notification |
| **Operation** | `deviceFilterCriteria[n].operation` | `EQUALS` | To match, the value must `EQUAL` "1". |
| **Account Notification ID** | `accountNotificationId` | `85c796b4-c08c-4bcd-bb9f-2f5fa850e5f9` | The ID of the notification type to use (see below) |

Of particular note is the `accountNotificationId` field. This field identifies a
notification type in the Afero backend. To indicate that this rule should send
a push notification, the given `id` must be assigned to the rule.

> **Swift Note:** The Account Notification ID can be accessed as a constant
> in the SDK as `AccountNotification.standard.id`.

### JSON

```json
{
"enabled": true,
"label": "Power is on",
"deviceFilterCriteria": [
  {
    "attribute": {
      "id": 100,
      "value": "1"
    },
    "operation": "EQUALS",
    "deviceId": "0123456789",
    "trigger": true
  }
],
"deviceActions": [ ],
"userNotifications": [ ],
"accountNotificationId": "85c796b4-c08c-4bcd-bb9f-2f5fa850e5f9"
}
```

Now that this rule has been formulated, it can be `POST`'ed to the Afero Client API:

`POST https://api.afero.io/v1/accounts/XXYYZZ/rules`

## Advanced: Multiple Criteria, Relative Operations

It's possible to create a `DeviceRule` with multiple `deviceFilterCriteria`;
these criteria are `AND`'ed together.

It's also possible to assign operations other than `EQUALS`,
to express relative constraints. The `operation` field supports the following
values:

| Operation Value | Meaning |
| - | - |
| `EQUALS` | The device's attribute value must equal the value given in the criterion for the rule to match. |
| `GREATER_THAN` | The device's attribute value must be greater than the value given in the criterion for the rule to match. |
| `LESS_THAN` | The device's attribute value must be less than the value given in the criterion for the rule to match. |

> **Swift Note:** Valid operations are available via the `DeviceFilterCriterion.Operation` `enum`.

For example, to create a `DeviceRule` that sends a notification for the above
device when both the power is on and the temperature is > 30°C, one could
create the following:

### Fields

| Field | Value | Notes |
| - | - | - |
| **Notification Text** | *Power is on* | |
| **AccountId** | XXYYZZ | The id of the account the device is associated with |
| **Device ID** | 0123456789 | The id of the device which will trigger notifications |
| **Power Attribute ID** | 100 | The id of the attribute to check for notification trigger |
| **Power Operation** | `EQUALS` | To match, the value must `EQUAL` "1". |
| **Attribute Value for Power On** | "1" | The value of the attribute that will trigger the notification |
| **Temperature (°C) Attribute Id** | 101 | The id of the device's current temperature attribute, in degrees Celsius |
| **Temperature Operation** | `GREATER_THAN` | Attribute id 101 must be > than the given value |
| **Temperature Value** | "30" | 30°C |
| **Account Notification ID** | `85c796b4-c08c-4bcd-bb9f-2f5fa850e5f9` | The ID of the notification type to use (see below) |

### JSON

```json
{
"enabled": true,
"label": "Power is on",
"deviceFilterCriteria": [
  {
    "attribute": {
      "id": 100,
      "value": "1"
    },
    "operation": "EQUALS",
    "deviceId": "0123456789",
    "trigger": true
  },
  {
    "attribute": {
      "id": 101,
      "value": "30"
    },
    "operation": "GREATER_THAN",
    "deviceId": "0123456789",
    "trigger": true
  }
],
"deviceActions": [ ],
"userNotifications": [ ],
"accountNotificationId": "85c796b4-c08c-4bcd-bb9f-2f5fa850e5f9"
}
```

## Fetching Existing Rules

The rules for a given `accountId` can be fetched by sending a `GET` request to
the Afero Cloud:

`GET https://api.afero.io/v1/accounts/XXYYZZ/rules`

This will return an array of `DeviceRule` objects that are, if any,
associated with the account. In addition to the fields listed below, the
returned objects will have `ruleId` and `accountId` fields.

## Modifying Existing Rules

Rules that have been fetched from the Afero Cloud can be modified using
`PUT` requests. To modify a rule on account `XXYYZZ` with `ruleId` `AABBCC`,
one would issue the following request, specifying the `ruleId` in the URL:

`PUT https://api.afero.io/v1/accounts/XXYYZZ/rules/AABBCC`

# Appendix 1: Account Rule Endpoints

> **NOTE** Response and request bodies shown below comprise the entirety of supported
> `DeviceRule` fields. Only the fields noted above are necessary for sending notifications.

## Fetch Rules

`GET https://api.afero.io/v1/accounts/{accountId}/rules`

| HTTP Status Code | Reason
| - | - |
| 200 | OK |
| 201 | |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |

Response Body: see **Appendix 2: Full DeviceRule Schema**.

## Create a Rule

`POST https://api.afero.io/v1/accounts/{accountId}/rules`

| HTTP Status Code | Reason
| - | - |
| 200 | OK |
| 201 | |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |

### Request Body

```json
{
  "label": "",
  "deviceFilterCriteria": [
    {
      "attribute": {
        "id": 0,
        "data": "",
        "value": ""
      },
      "operation": "",
      "deviceId": "",
      "trigger": false
    }
  ],
  "timeFilterCriteria": [
    {
      "type": ""
    }
  ],
  "scheduleId": "",
  "deviceActions": [
    {
      "deviceId": "",
      "attributes": [
        {
          "id": 0,
          "data": "",
          "value": ""
        }
      ],
      "durationSeconds": 0,
      "scheduleId": ""
    }
  ],
  "userNotifications": [
    {
      "userId": "",
      "notificationId": ""
    }
  ],
  "accountNotificationId": "",
  "runOnce": false
}
```

### Response Body

See **Appendix 2: Full DeviceRule Schema**

## Modify a Rule

`PUT /v1/accounts/{accountId}/rules/{ruleId}`

| HTTP Status Code | Reason
| - | - |
| 200 | OK |
| 201 | |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |

### Request Body

```json
{
  "enabled": false,
  "label": "",
  "deviceFilterCriteria": [
    {
      "attribute": {
        "id": 0,
        "data": "",
        "value": ""
      },
      "operation": "",
      "deviceId": "",
      "trigger": false
    }
  ],
  "timeFilterCriteria": [
    {
      "type": ""
    }
  ],
  "scheduleId": "",
  "deviceActions": [
    {
      "deviceId": "",
      "attributes": [
        {
          "id": 0,
          "data": "",
          "value": ""
        }
      ],
      "durationSeconds": 0,
      "scheduleId": ""
    }
  ],
  "userNotifications": [
    {
      "userId": "",
      "notificationId": ""
    }
  ],
  "accountNotificationId": "",
  "runOnce": false
}
```

### Response Body

See **Appendix 2: Full DeviceRule Schema**

# Appendix 2: Full `DeviceRule` Schema
 ```json
 [
  {
    "ruleId": "",
    "accountId": "",
    "enabled": false,
    "label": "",
    "deviceFilterCriteria": [
      {
        "attribute": {
          "id": 0,
          "data": "",
          "value": ""
        },
        "operation": "",
        "deviceId": "",
        "trigger": false
      }
    ],
    "timeFilterCriteria": [
      {
        "type": ""
      }
    ],
    "scheduleId": "",
    "schedule": {
      "scheduleId": "",
      "accountId": "",
      "dayOfWeek": [
        ""
      ],
      "time": {
        "timeZone": "",
        "seconds": 0,
        "hour": 0,
        "minute": 0
      },
      "status": "",
      "nextRun": 0,
      "createdTimestamp": 0,
      "updatedTimestamp": 0,
      "triggeredRuleId": ""
    },
    "deviceActions": [
      {
        "deviceId": "",
        "attributes": [
          {
            "id": 0,
            "data": "",
            "value": ""
          }
        ],
        "durationSeconds": 0,
        "scheduleId": ""
      }
    ],
    "createdTimestamp": 0,
    "userNotifications": [
      {
        "userId": "",
        "notificationId": ""
      }
    ],
    "accountNotificationId": ""
  }
]
```

# Appendix 3: Supported `extendedData` Fields

| Field | Required? | Description | Type | Example / Valid Values |
| - | :-: | - | :-: | - |
| `app_identifier` | X | Your app's bundleId or appId | String | `io.afero.iTokui` |

> **TODO**: Other fields to be added.
