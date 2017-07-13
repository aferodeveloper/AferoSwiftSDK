---
author: Justin Middleton
title: "Examples/README"
date: 2017-Jun-26 16:52:37 PDT
status: 1.0
---

# Examples

## AferoLab

AferoLab is a simple app that demonstrates connecting to the Afero Cloud,
and basic device interaction. In order to run AferoLab, you'll have to
first configure your OAuth2 Client ID and Secret.

### OAuth2 Client Configuration

First, place the APIClientConfig file:
```shell
cd AferoLab/AferoLab
cp APIClientConfig-EXAMPLE.plist APIClientConfig.plist
open APIClientConfig.plist
```

Second, open the file and add your client config:

![Image of APIClientConfig being edited](Docs/api-client-config.png)

Third, save the file, and run the app.
