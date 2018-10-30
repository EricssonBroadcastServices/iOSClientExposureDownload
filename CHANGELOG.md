# CHANGELOG

* `0.93.0` Release - [0.93.0](#0930)
* `0.80.0` Release - [0.80.0](#0800)
* `0.79.0` Release - [0.79.0](#0790)
* `0.78.0` Release - [0.78.0](#0780)
* `0.77.x` Releases - [0.77.0](#0770)

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
