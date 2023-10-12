# Exposure Download

![Swift Version](https://img.shields.io/badge/Swift-5.x-orange?style=flat-square)
![Platform](https://img.shields.io/badge/Platforms-iOS_tvOS-yellowgreen?style=flat-square)
![CocoaPods Compatible](https://img.shields.io/cocoapods/v/Alamofire.svg?style=flat-square)
![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat-square)
![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
  - [Downloading Assets](#downloading-assets)
  - [Identify Downloadable Assets](#identify-downloadable-assets)
  - [Playback of a Downloaded Asset](#playback-of-a-downloaded-asset)
  - [Deleting Downloaded Asset](#deleting-downloaded-asset)
  - [Fairplay Integration](#fairplay-integration)
  - [Error Handling](#error-handling)
- [Release Notes](#release-notes)
- [Upgrade Guides](#upgrade-guides)
- [Roadmap](#roadmap)
- [Contributing](#contributing)

## Features

- Download through *Exposure*
- Playback of Downloaded Assets

## Requirements

- iOS 11.0+ (FairPlay requires iOS 10.0+)
- Swift 5.0+
- Xcode 10.2+

Framework dependencies:
- [Download](https://github.com/EricssonBroadcastServices/iOSClientDownload)
- [Exposure](https://github.com/EricssonBroadcastServices/iOSClientExposure)
- Exact versions described in [Cartfile](https://github.com/EricssonBroadcastServices/iOSClientExposureDownload/blob/master/Cartfile)

## Installation

The Swift Package Manager is a tool for automating the distribution of Swift code and is integrated into the swift compiler. Once you have your Swift package set up, adding `iOSClientExposureDownload` as a dependency is as easy as adding it to the dependencies value of your Package.swift.

```swift
dependencies: [
    .package(url: "https://github.com/EricssonBroadcastServices/iOSClientExposureDownload", from: "3.5.0")
]
```

### CocoaPods

CocoaPods is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate `iOSClientExposureDownload` into your Xcode project using CocoaPods, specify it in your Podfile:

```ruby
pod 'iOSClientExposureDownload', '~>  3.5.0'
```

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependency graph without interfering with your Xcode project setup. CI integration through [fastlane](https://github.com/fastlane/fastlane) is also available.

Install Carthage through Homebrew by performing the following commands:

```bash
$ brew update
$ brew install carthage
```

Once Carthage has been installed, you need to create a Cartfile that specifies your dependencies. Please consult the [artifacts](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md) documentation for in-depth information about Cartfiles and the other artifacts created by Carthage.

```swift
github "EricssonBroadcastServices/iOSClientExposureDownload"
```

Running `carthage update` will fetch your dependencies and place them in /Carthage/Checkouts. You can then build the .framework files and drag them into your Xcode project or attach the fetched projects to your Xcode workspace.

Finally, make sure to add the .framework files to your target's General -> Embedded Binaries section.

## Usage

Client applications can use the `ExpoureDownload` by confirming `EnigmaDownloadManager` to any class:

```swift
class MyTestViewController: UIViewController, EnigmaDownloadManager {
    // After confirming, client applications can use the `enigmaDownloadManager` instance to perform any download-related tasks.
}
```

### Identify Downloadable Assets

All assets might not be downloadable even if a customer supports download. There can be a restriction on blocking downloads for a specific user. `ExposureDownload` provides an API (`isAvailableToDownload()`) to check if an `Asset` is available to download. Client applications can perform the download check by passing the `assetId` and the `sessionToken`.

```swift
enigmaDownloadManager.isAvailableToDownload(assetId: assetId, environment: environment, sessionToken: SessionToken) { _ in 
    // Handle Response (true / false)
}
```

### Identify What Can be Downloaded for a Specific Asset

When a user selects an actually downloadable asset, `ExposureDownload` provides an option to check what can be downloadable for that asset (audios, videos, subtitles).

```swift
enigmaDownloadManager.getDownloadableInfo(assetId: assetId, environment: environment, sessionToken: session) { downloadInfo in
    // Handle Response
    // downloadInfo.audios, downloadInfo.videos, downloadInfo.subtitles
}
```

### Downloading Assets

To download an `Asset`, client applications can create a `downloadTask` by passing the `assetId`. The task can be prepared and resumed to start downloading the asset. Tasks can be suspended and canceled.

```swift
let task = enigmaDownloadManager.download(assetId: assetId, using: session, in: environment)
task.prepare()
task.resume()
task.suspend()
task.cancel()
```

`downloadTask` publishes several events that the client applications can listen to.

```swift
task.onPrepared { _ in
    print("📱 Media Download prepared")
    // task.resume()
}
.onCanceled { task, url in
    print("📱 Media Download canceled", task.configuration.identifier, url)
}
.onSuspended { _ in
    print("📱 Media Download Suspended")
}
.onResumed { _ in
    print("📱 Media Download Resumed")
}
.onProgress { _, progress in
    print("📱 Percent", progress.current * 100, "%")
}
.onError { _, url, error in
    print("📱 Download error: \(error)")
}
.onCompleted { _, url in
    print("📱 Download completed: \(url)")
}
```

### Downloading Additional Media

To download additional media such as audios and subtitles, client applications can use the same `downloadTask`.

```swift
task.addAllAdditionalMedia() // will download all additional media
```

### Downloading Specific Media

To download a specific media, pass the bit rate to `downloadTask`.

```swift
task.use(bitrate: _)
```

### Check if Downloaded Asset has Expired

Client applications can check if a downloaded asset has expired using the `isExpired` method provided by the `enigmaDownloadManager`. This method allows client applications to determine whether a downloaded asset has expired. The method

If there is an internet connection , SDK will try to fetch the download asset's publicationEnd value from `downloadverified` and compare it with the `playTokenExpiration` & use the smallest value, Then compares the samllest with `Date()` (Today)
 to check if an asset is expired or not. 

```swift
enigmaDownloadManager.isExpired(assetId: asset.assetId, environment: environment, sessionToken: session) { expired, error in 
    if let error = error {
        // Handle the error, e.g., network issue or authentication problem
        print("Error: \(error.localizedDescription)")
    } else {
        // Handle the expiration status
        if expired {
            print("Asset has expired.")
            // Perform actions for an expired asset
        } else {
            print("Asset is still valid.")
            // Perform actions for a valid asset
        }
    }
}
```

Client developers can also fetch the `expiryTime` of a downloaded asset using `getExpiryTime(assetId: String, environment: Environment, sessionToken: SessionToken)`.

```swift
enigmaDownloadManager.getExpiryTime(assetId: asset.assetId, environment: environment, sessionToken: session) { expiryTime, error in 
    // expiryTime
}
```

### Renew License

If the license has expired, you can renew the licenses by using the following API:

```swift
let _ = enigmaDownloadManager.renewLicense(assetId: assetId, sessionToken: session, environment: environment) { offlineMediaAsset, error in 
    // print("Updated offline media asset \(offlineMediaAsset)")
}
```

### Playback of a Downloaded Asset

Client applications can get an `offlineMediaAsset` (downloaded asset) by using the `EnigmaDownloadManager`.

To get all downloads related to a given `assetId`:

```swift
let downloadedAsset = enigmaDownloadManager.getDownloadedAssets(assetId: assetId)
```

To get all downloads related to a given `userId`:

```swift
let downloadedAsset = enigmaDownloadManager.getDownloadedAssets(userId: userId)
```

Or client applications can get `AllDownloadedAssets` by using `getDownloadedAssets()`.

```swift
let allDownloadedAssets = enigmaDownloadManager.getDownloadedAssets()
```

Then developers can create an `OfflineMediaPlayable` and pass it to the player to play any downloaded asset. However, when playing downloaded MP3 files, AVPlayer sometimes doesn't work. In such cases, client application developers are encouraged to use AVAudioPlayer or AVAudioEngine to play offline MP3 files. Check the SDK Sample application for an example implementation (https://github.com/EricssonBroadcastServices/iOSClientSDKSampleApp).

`OfflineMediaPlayable` has the attribute `format` that will pass the format of the downloaded file.

```swift
let downloadedAsset = enigmaDownloadManager.getDownloadedAsset(assetId: assetId)

if let entitlement = downloadedAsset?.entitlement, let urlAsset = downloadedAsset?.urlAsset, let format = downloadedAsset?.format {

    if format == "MP3" || format == "mp3" {
        // Create `AVAudioPlayer` or `AVAudioFile` and pass to `AVAudioEngine`
    } else {
        let offlineMediaPlayable = OfflineMediaPlayable(assetId: assetId, entitlement: entitlement, url: urlAsset.url)
        
        // Play downloaded asset
        player.startPlayback(offlineMediaPlayable: offlineMediaPlayable)
    }
}
```

### Deleting Downloaded Asset

To delete a downloaded asset, developers can use `removeDownloadedAsset(assetId:)`.

```swift
let _ = enigmaDownloadManager.removeDownloadedAsset(assetId: assetId)
```

### State of a Downloaded Asset

Client applications can get the download state of an `offlineMediaAsset` (downloaded asset) by using the `getDownloadState()`.

```swift
let downloadedAsset = enigmaDownloadManager.getDownloadedAsset(assetId: assetId)
let downloadState = downloadedAsset.getDownloadState()

switch downloadState {
    case .completed:
        // Completed 
    case .cancel:
        // Canceled 
    case .notDownloaded:
        // Not downloaded 
    case .suspend:
        // Suspended 
    case .started:
        // Download has started 
    case .downloading:
        // In some cases, `offlineMediaAsset` can have the state of `downloading` even when there is no ongoing active download task. 
        // In this case, it is recommended to check the playable state of the `offlineMediaAsset`

        let _ = downloadedAsset.state { playableState in
            switch playableState {
                case .completed(entitlement: let entitlement, url: let url):
                    self.downloadState = .downloaded
                case .notPlayable(entitlement: let entitlement, url: _):
                    self.downloadState = .suspended
            }
        }
}
```

### Fairplay Integration

SDK provides an out-of-the-box implementation for downloading FairPlay protected assets. Client applications can create a `downloadTask` and start downloading. SDK will download the relevant FairPlay licenses and keys and will use them when you are trying to play a FairPlay protected downloaded asset using `ExposurePlayBack`.

## Release Notes

Release-specific changes can be found in the [CHANGELOG](https://github.com/EricssonBroadcastServices/iOSClientExposureDownload/blob/master/CHANGELOG.md).

## Upgrade Guides

The procedure to apply when upgrading from one version to another depends on what solution your client application has chosen to integrate `Exposure`. Major changes between releases will be documented with special [Upgrade Guides](https://github.com/EricssonBroadcastServices/iOSClientExposureDownload/blob/master/UPGRADE_GUIDE.md).

## Roadmap

No formalized roadmap has yet been established but an extensive backlog of possible items exist. The following represent an unordered *wish list* and is subject to change.

## Contributing
```
```
