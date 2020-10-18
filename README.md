# SendMan

[![Version](https://img.shields.io/cocoapods/v/SendMan.svg?style=flat)](https://cocoapods.org/pods/SendMan)
[![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/sendmanio/sendman-ios-sdk/master/LICENSE.md)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg)](https://github.com/Carthage/Carthage)

---

SendMan is a push notification management service for mobile apps. This SDK allows integrating your native iOS apps with SendMan. 

## Installation

SendMan is available through [CocoaPods](https://cocoapods.org) or [Carthage](https://github.com/Carthage/Carthage). 

### CocoaPods

In order to install it through CocoaPods, simply add the following line to your Podfile:

```ruby
pod 'SendMan', '~> 1.0.1'
```

### Carthage

In order to install it through Carthage, add the following line to your Cartfile, and install it as you would any other Carthage dependency:
```
github "sendmanio/sendman-ios-sdk" ~> 1.0.1
```

## Integration

### Prerequisites

* SendMan supports iOS >= 10.0 as the deployment target.
* Your app must be configured with the following capabilities:
    * Push Notifications
    * Background Modes: Remote Notifications

### Steps

1. **Initializing the SDK** (Get your app key and secret from the [API keys](https://console.sendman.io/applications/current/keys) screen) 

    ``` Swift
    // Step 1: App-level identification: Initialize our SDK.
    SendMan.setAppConfig(SMConfig(key: YOUR_APP_KEY, andSecret: YOUR_APP_SECRET)!)

    // Step 2: User-level identification: Identify your users with the unique ID your application uses to identify users.
    SendMan.setUserId("some-unique-id")
    ```

    If your users do not have unique IDs, use this syntax for us to automatically handle those users for you:


    ``` Swift
    SendMan.setAppConfig(SMConfig(key: YOUR_APP_KEY, andSecret: YOUR_APP_SECRET, autoGenerateUsers: true)!)
    ```

2. **Registering for push notifications with iOS**

    ``` Swift
    SendMan.register()
    ```

For a detailed integration guide (including integrating using Objective-C, tracking user interaction with notifications and storing custom user properties), head to [our docs](https://docs.sendman.io/mobile-integration/ios).

## Author

SendMan, hello@sendman.io

## License

SendMan is available under the MIT license. See the LICENSE file for more info.
