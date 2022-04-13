# CHANGELOG

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
