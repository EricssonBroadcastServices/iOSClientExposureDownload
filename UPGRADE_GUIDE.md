# Upgrade Guide

## Adopting 0.76.0

#### Architecture
`Exposure` module has been refactored with the playback and download related functionality extracted into new modules, `ExposurePlayback` and `ExposureDownload`.

`Exposure` module now acts exclusively as an integration point for the *ExposureLayer*
