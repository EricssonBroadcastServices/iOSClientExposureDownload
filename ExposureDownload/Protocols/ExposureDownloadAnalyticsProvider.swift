//
//  ExposureDownloadAnalyticsProvider.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2017-11-27.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Exposure

public protocol ExposureDownloadAnalyticsProvider {
    
    /// Exposure environment used for the active session.
    ///
    /// - Important: should match the `environment` used to authenticate the user.
    var environment: Environment { get }
    
    /// Token identifying the active session.
    ///
    /// - Important: should match the `environment` used to authenticate the user.
    var sessionToken: SessionToken { get }
    
    
    /// Sent when the player is about to make an entitlement request
    ///
    /// - parameter tech: DownloadTask used to download the media
    /// - parameter assetId: *EMP* asset identifier
    func onEntitlementRequested(tech: ExposureDownloadTask, assetId: String)
    
    /// Sent when the entitlement has been granted, right after loading of media sources has been initiated.
    ///
    /// - parameter tech: DownloadTask responsible for downloading the media
    /// - parameter source: `PlaybackEntitlement` used to load the request,
    /// - parameter request: *EMP* asset identifier
    func onHandshakeStarted(tech: ExposureDownloadTask, source: PlaybackEntitlement, assetId: String)
    
    /// Downloading of media to device started
    ///
    /// - parameter task: DownloadTask responsible for downloading the media
    func downloadStartedEvent(task: ExposureDownloadTask)
    
    /// Downloading media was paused
    ///
    /// - parameter task: DownloadTask responsible for downloading the media
    func downloadPausedEvent(task: ExposureDownloadTask)
    
    /// Previously paused download task was resumed
    ///
    /// - parameter task: DownloadTask responsible for downloading the media
    func downloadResumedEvent(task: ExposureDownloadTask)
    
    /// Downloading cancelled
    ///
    /// - parameter task: DownloadTask responsible for downloading the media
    func downloadCancelledEvent(task: ExposureDownloadTask)
    
    /// Downloading of media to device stopped
    ///
    /// - parameter task: DownloadTask responsible for downloading the media
    func downloadStoppedEvent(task: ExposureDownloadTask)
    
    /// Downloading of media to device completed
    ///
    /// - parameter task: DownloadTask responsible for downloading the media
    func downloadCompletedEvent(task: ExposureDownloadTask)
    
    
    /// Triggered if the download process encounters an error during its lifetime
    ///
    /// - parameter ExposureDownloadTask: `ExposureDownloadTask` broadcasting the event
    /// - parameter error: `ExposureError` causing the event to fire
    func downloadErrorEvent(task: ExposureDownloadTask, error: ExposureDownloadTask.Error)
    
    /// Should prepare and configure the remaining parts of the Analytics environment.
    /// This step is required because we are dependant on the response from Exposure with regards to the playSessionId.
    ///
    /// Once this is called, a Dispatcher should be associated with the session.
    ///
    /// - parameter asset: *EMP* asset identifiers.
    /// - parameter entitlement: The entitlement this session concerns
    /// - parameter heartbeatsProvider: Will deliver heartbeats metadata during the session
    func finalizePreparation(assetId: String, with entitlement: PlaybackEntitlement, heartbeatsProvider: @escaping () -> AnalyticsEvent?)
}
