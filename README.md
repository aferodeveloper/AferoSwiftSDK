---
author: Justin Middleton
title: "AferoSwiftSDK"
date: 2017-Jul-09 09:29:0
status: 1.0
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

  AFERO CONFIDENTIAL AND PROPRIETARY INFORMATION
  © Copyright 2017 Afero, Inc, All Rights Reserved.

  Any use and distribution of this software is subject to the terms
  of the License and Services Agreement between Afero, Inc. and licensee.

  SDK products contain certain trade secrets, patents, confidential and
  proprietary information of Afero.  Use, reproduction, disclosure
  and distribution by any means are prohibited, except pursuant to
  a written license from Afero. Use of copyright notice is
  precautionary and does not imply publication or disclosure.

  Restricted Rights Legend:
  Use, duplication, or disclosure by the Government is subject to
  restrictions as set forth in subparagraph (c)(1)(ii) of The
  Rights in Technical Data and Computer Software clause in DFARS
  252.227-7013 or subparagraphs (c)(1) and (2) of the Commercial
  Computer Software--Restricted Rights at 48 CFR 52.227-19, as
  applicable.


## Getting Started

### Configure your Podfile

```ruby
source 'git@github.com:aferodeveloper/Podspecs.git'
source 'https://github.com/CocoaPods/Specs.git'

pod `AferoSwiftSDK`
```

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
[AferoLab]: https://github.com/aferodeveloper/AferoSwiftSDK/tree/maint-1.0/Examples/AferoLab
[Softhub]: https://github.com/aferodeveloper/AferoSwiftSDK/blob/maint-1.0/Docs/Softhub.md
[SofthubMinder]:https://github.com/aferodeveloper/AferoSwiftSDK/blob/maint-1.0/Examples/AferoLab/AferoLab/SofthubMinder.swift
[push-notifications]: Docs/Push_Notifications.md
[rest-api-client]: Docs/RESTApiClient.md
[api-ref]: Docs/Reference/index.html

## Colophon

This document was created using a combination of  [Github-Flavored Markdown](https://github.github.com/gfm/),
[Mermaid](https://mermaidjs.github.io) for sequence diagrams, and
[PlantUML](http://plantuml.com) for UML.

Creation was done in [Atom](), with rendered output created using [markdown-preview-enhanced](https://github.com/shd101wyy/markdown-preview-enhanced).
