# CHANGELOG

* `2.2.20` Release - [2.2.20](#2220)
* `2.2.10` Release - [2.2.10](#2210)
* `2.2.00` Release - [2.2.00](#2200)
* `0.93.0` Release - [0.93.0](#0930)
* `0.80.0` Release - [0.80.0](#0800)
* `0.79.0` Release - [0.79.0](#0790)
* `0.78.0` Release - [0.78.0](#0780)
* `0.77.x` Releases - [0.77.0](#0770)

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
