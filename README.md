[![Swift](https://img.shields.io/badge/Swift-5.x-orange?style=flat-square)](https://img.shields.io/badge/Swift-5.3_5.4_5.5-Orange?style=flat-square)
[![Platforms](https://img.shields.io/badge/Platforms-iOS_tvOS-yellowgreen?style=flat-square)](https://img.shields.io/badge/Platforms-macOS_iOS_tvOS_watchOS_Linux_Windows-Green?style=flat-square)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/Alamofire.svg?style=flat-square)](https://img.shields.io/cocoapods/v/Alamofire.svg)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat-square)](https://github.com/Carthage/Carthage)
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)


# Exposure Download

* [Features](#features)
* [License](https://github.com/EricssonBroadcastServices/iOSClientExposureDownload/blob/master/LICENSE)
* [Requirements](#requirements)
* [Installation](#installation)

* Usage
    - [Downloading Assets](#downloading-assets)
    - [Identify Downloadable Assets](#identify-downloadable-assets)
    - [Playback of a downloaded Asset](#playback-of-a-downloaded-asset)
    - [Deleting downloaded Asset](#deleting-downloaded-asset)
    - [Fairplay Integration](#fairplay-integration)
    - [Error Handling](#error-handling)
* [Release Notes](#release-notes)
* [Upgrade Guides](#upgrade-guides)
* [Roadmap](#roadmap)
* [Contributing](#contributing)

## Features

- [x] Download through *Exposure*
- [x] Playback of Downloaded Assets

## Requirements

* `iOS` 11.0+ (`FairPlay` requires `iOS` 10.0+)
* `Swift` 5.0+
* `Xcode` 10.2+

* Framework dependencies
    - [`Download`](https://github.com/EricssonBroadcastServices/iOSClientDownload)
    - [`Exposure`](https://github.com/EricssonBroadcastServices/iOSClientExposure)
    - Exact versions described in [Cartfile](https://github.com/EricssonBroadcastServices/iOSClientExposureDownload/blob/master/Cartfile)

## Installation

The Swift Package Manager is a tool for automating the distribution of Swift code and is integrated into the swift compiler.
Once you have your Swift package set up, adding `iOSClientExposureDownload` as a dependency is as easy as adding it to the dependencies value of your Package.swift.

```sh
dependencies: [
    .package(url: "https://github.com/EricssonBroadcastServices/iOSClientExposureDownload", from: "3.0.0")
]
```

### CocoaPods
CocoaPods is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate `iOSClientExposureDownload` into your Xcode project using CocoaPods, specify it in your Podfile:

```sh
pod 'iOSClientExposureDownload', '~>  3.0.0'

### Carthage
[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependency graph without interfering with your `Xcode` project setup. `CI` integration through [fastlane](https://github.com/fastlane/fastlane) is also available.

Install *Carthage* through [Homebrew](https://brew.sh) by performing the following commands:

```sh
$ brew update
$ brew install carthage
```

Once *Carthage* has been installed, you need to create a `Cartfile` which specifies your dependencies. Please consult the [artifacts](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md) documentation for in-depth information about `Cartfile`s and the other artifacts created by *Carthage*.

```sh
github "EricssonBroadcastServices/iOSClientExposureDownload"
```

Running `carthage update` will fetch your dependencies and place them in `/Carthage/Checkouts`. You either build the `.framework`s and drag them in your `Xcode` or attach the fetched projects to your `Xcode workspace`.

Finally, make sure you add the `.framework`s to your targets *General -> Embedded Binaries* section.

## Usage

Client applications can use the `ExpoureDownload` by  confirming `EnigmaDownloadManager` to any class 

```Swift
class MyTestViewController: UIViewController, EnigmaDownloadManager {
    // After confirming client applications can use `enigmaDownloadManager` instance to perform any download related tasks.
}
```

### Identify Downloadable Assets

All assets might not be downloadable even if a customer supports download. There can be restriction of blocking downloads for a specific user.
`ExposureDownload` provides an API (`isAvailableToDownload()`) to check if an `Asset` is available to download. But developers have to fetch `UserAvailabilityKeys` to pass , if they haven't already fetch those keys. 

`Exposure`  provides an API to get the availability keys related the currently logged in user.

```Swift
 GetAvailabilityKeys(environment: environment, sessionToken: session)
    .request()
    .validate()
    .response { 
        // Handle Response 
    }
```

Then client applications can perform the download check by passing the `assetId` & the `UserAvailabilityKeys`. 

```Swift
    enigmaDownloadManager.isAvailableToDownload(assetId: assetId, environment: environment, availabilityKeys: availabilityKeys ) { _ in 
        // Handle Response ( true / false )
}
```

### Identify what can be downloaded for a specific asset

When a user select an actually downloadable asset `ExposureDownload` provides an option to check what can be downloadable for that asset. ( `audios` , `videos` , `subtitles` )
```Swift
    enigmaDownloadManager.getDownloadableInfo(assetId: assetId, environment: environment, sessionToken: session) { downloadInfo in
        /// Handle Response 
        /// downloadInfo.audios , downloadInfo.videos,  downloadInfo.subtitles
    }
```

### Downloading Assets

To download an `Asset` client applications can create a `downloadTask` by passing the `assetId` .   Task can be `prepare` & `resume` to start downloading the asset.
`task.suspend()` will temporary suspend the downloading task. Suspended task can be `resume`.  
`task.cancel()`  will cancel the task. 

```Swift
    let task = enigmaDownloadManager.download(assetId: assetId, using: session, in: environment)
    task.prepare()
    task.resume()
    task.suspend()
    task.cancel()
    
```

`downloadTask` publishes several events that the client applications can listen to. 

```Swift 

    task.onPrepared { _ in
        print("📱 Media Download prepared ")
        // task.resume()
    }
    .onCanceled { task, url in
        print("📱 Media Download canceled",task.configuration.identifier,url)
    }
    
    .onSuspended { _ in
        print("📱 Media Download Suspended")
    }
    .onResumed { _ in
        print("📱 Media Download Resumed")
        
    }
    .onProgress { _, progress in
        print("📱 Percent", progress.current*100,"%")
    }
    .onError {_, url, error in
        print("📱 Download error: \(error)")
    }
    .onCompleted { _, url in
        print("📱 Download completed: \(url)")
    }
```

### Downloading Additional Media

To download Additional Media such as audios & subtitles client applications can use the same   `downloadTask`. 
```Swift 

    task.addAllAdditionalMedia() // will download all aditional media 

    // .addAudios(hlsNames: ["French", "German"])
    // .addSubtitles(hlsNames: ["French"])
```

### Refresh licence
Client applications can use `enigmaDownloadManager` check if the license for a download asset has expired by passing the `assetId`

```Swift
    enigmaDownloadManager.isExpired(assetId: asset.assetId) // true / false 
```

If the license has expired , you need to use the `downloadTask` to refresh the licenses.

```Swift
    task.refreshLicence()
    task.onError {_, url, error in
        print("📱 RefreshLicence Task failed with an error: \(error)",url ?? "")
    }
    .onCompleted { _, url in
        print("📱 RefreshLicence Task completed: \(url)")
    }
```


### Playback of a downloaded Asset

Client applications can get an `offlineMediaAsset` ( downloaded asset ) by using the `EnigmaDownloadManager`. 

```Swift
    let downloadedAsset = enigmaDownloadManager.getDownloadedAsset(assetId: assetId)
```

Or client applications can get `AllDownloadedAssets` by using `getDownloadedAssets()`

```Swift
    let allDownloadedAssets = enigmaDownloadManager.getDownloadedAssets()
```


Then developers can create a  `OfflineMediaPlayable` & pass it to the player to play any downloaded asset. 

```Swift
    let downloadedAsset = enigmaDownloadManager.getDownloadedAsset(assetId: assetId)
    
    if let entitlement = downloadedAsset?.entitlement, let urlAsset = downloadedAsset?.urlAsset {
    
        let offlineMediaPlayable = OfflineMediaPlayable(assetId: assetId, entitlement: entitlement, url: urlAsset.url)
        
        // Play downloaded asset
        player.startPlayback(offlineMediaPlayable: offlineMediaPlayable)
        
    }
````


### Deleting downloaded Asset

To delete a downloaded asset, developer can use `removeDownloadedAsset(assetId:)`

```Swift
    let _ = enigmaDownloadManager.removeDownloadedAsset(assetId: assetId)
```


### Fairplay Integration

SDK provides an out of the box implementation for downloading FairPlay protected assets. Client applications can create a `downloadTask` & start downloading. SDK will download the relevent FairPlay licences & keys and will use them when you are trying to play a FairPlay protected downloaded asset using  [`ExposurePlayBack`]


## Release Notes
Release specific changes can be found in the [CHANGELOG](https://github.com/EricssonBroadcastServices/iOSClientExposureDownload/blob/master/CHANGELOG.md).

## Upgrade Guides
The procedure to apply when upgrading from one version to another depends on what solution your client application has chosen to integrate `Exposure`.

Major changes between releases will be documented with special [Upgrade Guides](https://github.com/EricssonBroadcastServices/iOSClientExposureDownload/blob/master/UPGRADE_GUIDE.md).

### Carthage
Updating your dependencies is done by running  `carthage update` with the relevant *options*, such as `--use-submodules`, depending on your project setup. For more information regarding dependency management with `Carthage` please consult their [documentation](https://github.com/Carthage/Carthage/blob/master/README.md) or run `carthage help`.

## Roadmap
No formalised roadmap has yet been established but an extensive backlog of possible items exist. The following represent an unordered *wish list* and is subject to change.

## Contributing
