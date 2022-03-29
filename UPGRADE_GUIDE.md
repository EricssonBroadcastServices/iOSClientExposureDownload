# Upgrade Guide

## 3.0.000
Project is now distributed via Swift package manager , Cocoapods & Carthage.
Unit tests have been moved to SPM tests & dependencies will be used as packages.
Module name has been renamed from `ExposureDownload` to `iOSClientExposureDownload`. 



## Adopting 0.77.0

#### Architecture
`Exposure` module has been refactored with the playback and download related functionality extracted into new modules, `ExposurePlayback` and `ExposureDownload`.

`Exposure` module now acts exclusively as an integration point for the *ExposureLayer*
