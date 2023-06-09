# CHANGELOG

* `3.3.0` Release - [3.3.0](#330)
* `3.2.6` Release - [3.2.6](#326)
* `3.2.50` Release - [3.2.500](#32500)
* `3.2.40` Release - [3.2.400](#32400)
* `3.2.30` Release - [3.2.300](#32300)
* `3.2.20` Release - [3.2.200](#32200)
* `3.2.10` Release - [3.2.100](#32100)
* `3.2.00` Release - [3.2.000](#32000)
* `3.1.10` Release - [3.1.100](#31100)
* `3.1.00` Release - [3.1.000](#31000)
* `3.0.20` Release - [3.0.200](#30200)
* `3.0.10` Release - [3.0.100](#30100)
* `3.0.00` Release - [3.0.000](#30000)
* `2.3.00` Release - [2.3.000](#23000)
* `2.2.60` Release - [2.2.600](#22600)
* `2.2.50` Release - [2.2.500](#22500)
* `2.2.40` Release - [2.2.400](#22400)
* `2.2.30` Release - [2.2.300](#22300)
* `2.2.20` Release - [2.2.200](#22200)
* `2.2.10` Release - [2.2.100](#22100)
* `2.2.00` Release - [2.2.000](#22000)
* `0.93.0` Release - [0.93.00](#09300)
* `0.80.0` Release - [0.80.00](#08000)
* `0.79.0` Release - [0.79.00](#07900)
* `0.78.0` Release - [0.78.00](#07800)
* `0.77.x` Releases - [0.77.0](#0770)


## 3.3.0
#### Bug fixes & Changes
* `EMP-20054` Bug fix : Entitlement become nil after renewal of licences. 
* `EMP-20054` Added a new API for renew licences of licences & depricated the old API. Use new API `enigmaDownloadManager.renewLicense(assetId: assetId, sessionToken: session, environment: environment) { offlineMediaAsset, error in ... }`

## 3.2.6
#### Changes
* Update dependencies 

## 3.2.500
#### Bug fix
* `EMP-19916` Use milliseconds when comparing `playTokenExpiration` and current `Date()` to pass if an offline asset is expired or not.


## 3.2.400
#### Changes
* `EMP-19778` pass `AVAssetDownloadTaskMediaSelectionPrefersMultichannelKey` to `false` to avoid downloading multichannel renditions.

## 3.2.300
#### Features
* `EMP-18996` pass `format` of the downloaded file (`OfflineMediaAsset`)

## 3.2.200
#### Features
* `EMP-19059` Add `presentationSize` to be passed from client apps when selecting download streams

## 3.2.000
#### Features
* `EMP-18649` Add a method to get downloadedAssets by `userId` : `enigmaDownloadManager.getDownloadedAssets(userId: _ )`

## 3.1.100
#### Bug fixes
* `EMP-18319` Bug fix :  Player freeze when seek on offline assets 

## 3.1.000
#### Changes
* Update `isAvailableToDownload` to use session token & remove `availabilitykeys` usage

## 3.0.200
#### Changes
* `EMP-17993` Fix broken Carthage project for iOSClientExpsoureDownload

## 3.0.100
#### Changes
* Update dependecy `iOSClientExposure`


## 3.0.000
#### Features
* `EMP-17893` Add support to SPM & Cocoapods

## 2.3.000
#### Changes
* Update `ExposureDownload` to use latest version of `iOSClientExposure`

## 2.2.600
#### Bug Fixes
* `EMP-1580` Migrate the SDK download task from `AVAssetDownloadTask` to `AVAggregateAssetDownloadTask`

## 2.2.500
#### Changes
* `EMP-15755` Added download state to local media records & offlineMedia Assets
* `EMP-15755` Clean local records when a download was cancelled

## 2.2.400
#### Changes
* `EMP-15234` Download sdk should not call `Delete` exposure Endpoint when deleting a downloaded asset 

## 2.2.300
#### Changes
* `EMP-15210` Notify DownloadBookKeeper when a download is complete or when a DRM license is refreshed
* `EMP-15210` Notify DownloadBookKeeper when user deleted a downloaded media. 


## 2.2.200
#### Bug Fixes
* Add `-weak_framework AVfoundation` to fix Xcode compile errors

## 2.2.100
#### Features
* `EMP-14806` Update support for downloading additional media : audio & subtitles

#### Changes
* `EMP-14806`  Updated to Swift 5
* `EMP-14806`  Now the Exposure download module support iOS 11 & up versions 

## 2.2.000
#### Features
* `EMP-14376` Update support for downloads 


## 0.93.0

#### Changes
* submodules no longer added through ssh

## 0.80.0

#### Features
* `EMP-11121` Introduced specialized logic, `AirplayHandler` to manage Airplay scenarios.

#### Changes
* `EMP-11156` Standardized error messages and introduced an `info` variable

## 0.79.0

#### Bugfixes
* Heartbeats marked as ignored for retry dispatch on failure

## 0.78.0

#### Features
* Standalone networking

#### Changes
* `HeartbeatsProvider` as a closure instead of a protocol

## 0.77.0

#### Changes
* Extracted *playback* and *download* functionality. `Exposure` now deals exclusivley with metadata from the *Exposure Layer*.
