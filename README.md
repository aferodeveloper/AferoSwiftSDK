---
author: Cora Middleton
title: "AferoSwiftSDK"
date: 2023-April-20
status: 1.5.2
---

# AferoSwiftSDK

An SDK for interacting with the Afero service and peripheral platform.

<!-- @import "[TOC]" {cmd:"toc", depthFrom:2, depthTo:6, orderedList:true} -->
<!-- code_chunk_output -->

* [AferoSwiftSDK](#aferoswiftsdk)
	* [LICENSE](#license)
	* [Getting Started](#getting-started)
	* [Additional Documents](#additional-documents)

<!-- /code_chunk_output -->

## LICENSE

Copyright 2023 Afero, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Required Environment
### XCode 14
AferoSwiftSDK supports Swift versions 5+, and Xcode versions 13 and 14, and iOS 11.0+.
### GitHub
AferoSwiftSDK is hosted in source format on GitHub; partners are provided read-only access. In addition, for compatibility with CocoaPods installation, the user must configure their GitHub account for password-less authentication at the command line. GitHub provides a number of methods for accomplishing this, including [SSH Keys](https://help.github.com/en/articles/adding-a-new-ssh-key-to-your-github-account) and [Personal Access Tokens](https://help.github.com/en/articles/creating-a-personal-access-token-for-the-command-line).
### Cocoapods
**AferoSwiftSDK** and **AferoIOSSofthub** are provided as CocoaPods, and have been tested with CocoaPods version 1.11.3 and earlier.

## Getting Started
### Configure your Podfile
Before developing with **AferoSwiftSDK**, a workspace's Podfile must be configured to integrate it:
```ruby
# Reference the Afero SDK
    source 'git@github.com:aferodeveloper/Podspecs.git'

    # Explicitly reference the master CocoaPods repo.
    source 'https://github.com/CocoaPods/Specs.git'

    platform :ios, '9.3'
    use_frameworks!

    ...

    pod 'AferoSwiftSDK/AFNetworking', '1.2.2' 
```
### Update/Install Pods
Once configured, the developer may run pod update, which will integrate **AferoSwiftSDK** and any prerequisite packages into their project.
### Import Afero
Once integrated, **AferoSwiftSDK** introduces the Afero module into a workspace. Each file which requires access to **AferoSwiftSDK** symbols will need to import the module, as such:
```
    //
    //  ViewController.swift
    //  MyApp
    //
    //  Created by Joe Britt on 3/17/19.
    //  Copyright © 2019 Afero, Inc. All rights reserved.
    // 
    import UIKit
    import Afero // Minimum requirement

    // Optional (but often necessary)
    import ReactiveSwift // Necessary for referring to Reactive symbols (signals, sinks)
    import PromiseKit // Necessary for referring to Promises (Futures)
```
### Example App
Included with **AferoSwiftSDK** is the **AferoLab** example app, in //AferoSwiftSDK/Examples. The app provides an Afero client that allows a user to:
  * Create accounts, sign in, sign out, and change/reset passwords.
  * List, add, and remove devices.
  * Interact with device attributes.
  * Run the Afero Softhub.
  * Configure Wi-Fi on Wi-Fi-capable devices. 

## See Also

| Title/Link | Description |
| - | - |
| [Softhub] | Afero Softhub Usage |
| [REST API Client][rest-api-client] | Describes interaction with the Afero Cloud REST API. |
| [Push Notifications][push-notifications] | Documents use of DeviceRules to implement push notifications for Afero device state changes. |
| [SofthubMinder] | Example code for managing softhub state *vis á vis*  UIApplication lifecycle. |

[aferodeveloper]: https://github.com/aferodeveloper
[AferoIOSSofthub]: https://github.com/aferodeveloper/AferoIOSSofthub
[AferoSwiftSDK]: https://github.com/aferodeveloper/AferoSwiftSDK
[AferoLab]: https://github.com/aferodeveloper/AferoSwiftSDK/tree/master/Examples/AferoLab
[Softhub]: https://github.com/aferodeveloper/AferoSwiftSDK/blob/master/Docs/Softhub.md
[SofthubMinder]:https://github.com/aferodeveloper/AferoSwiftSDK/blob/master/Examples/AferoLab/AferoLab/SofthubMinder.swift
[push-notifications]: Docs/Push_Notifications.md
[rest-api-client]: Docs/RESTApiClient.md
[api-ref]: Docs/Reference/index.html

## Colophon

This document was created using a combination of  [Github-Flavored Markdown](https://github.github.com/gfm/),
[Mermaid](https://mermaidjs.github.io) for sequence diagrams, and
[PlantUML](http://plantuml.com) for UML.

Creation was done in [Atom](), with rendered output created using [markdown-preview-enhanced](https://github.com/shd101wyy/markdown-preview-enhanced).
