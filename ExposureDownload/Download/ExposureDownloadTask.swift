//
//  ExposureDownloadTask.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2017-10-13.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import AVFoundation
import Download
import Exposure

extension ExposureDownloadTask {
    public enum Error: Swift.Error {
        case taskError(reason: TaskError)
        
        /// Errors related to *Fairplay* `DRM` validation.
        case fairplay(reason: FairplayError)
        
        /// Errors originating from Exposure
        case exposure(reason: ExposureError)
    }
}

extension ExposureDownloadTask.Error {
    public var message: String {
        switch self {
        case .taskError(reason: let error): return error.message
        case .fairplay(reason: let reason): return reason.message
        case .exposure(reason: let error): return error.message
        }
    }
}

extension ExposureDownloadTask.Error {
    /// Returns detailed information about the error
    public var info: String? {
        switch self {
        case .taskError(reason: let error): return error.info
        case .fairplay(reason: let reason): return reason.info
        case .exposure(reason: let error): return error.info
        }
    }
}

extension ExposureDownloadTask.Error {
    public var code: Int {
        switch self {
        case .taskError(reason: let error): return error.code
        case .fairplay(reason: let reason): return reason.code
        case .exposure(reason: let error): return error.code
        }
    }
}

extension ExposureDownloadTask.Error {
    public var domain: String { return String(describing: type(of: self))+"Domain" }
}

extension ExposureDownloadTask.Error {
    /// Errors associated with *Fairplay* can be categorized, broadly, into two types:
    /// * Fairplay server related *DRM* errors.
    /// * Application related.
    ///
    /// Server related issues most likely stem from an invalid or broken backend configuration. Application issues range from parsing errors, unexpected server response or networking issues.
    public enum FairplayError {
        // MARK: Application Certificate
        /// Networking issues caused the application to fail while verifying the *Fairplay* DRM.
        case networking(error: Error)
        
        /// No `URL` available to fetch the *Application Certificate*. This is a configuration issue.
        case missingApplicationCertificateUrl
        
        /// The *Application Certificate* response contained an unexpected or invalid data format.
        ///
        /// `FairplayRequester` failed to decode the raw data, most likely due to a missmatch between expected and supplied data format.
        case applicationCertificateDataFormatInvalid
        
        /// *Certificate Server* responded with an error message.
        ///
        /// Details are expressed by `code` and `message`
        case applicationCertificateServer(code: Int, message: String)
        
        /// There was an error while parsing the *Application Certificate*. This is considered a general error
        case applicationCertificateParsing
        
        /// `AVAssetResourceLoadingRequest` failed to prepare the *Fairplay* related content identifier. This should normaly be encoded in the resouce loader's `urlRequest.url.host`.
        case invalidContentIdentifier
        
        // MARK: Server Playback Context
        /// An `error` occured while the `AVAssetResourceLoadingRequest` was trying to obtain the *Server Playback Context*, `SPC`, key request data for a specific combination of application and content.
        ///
        /// ```swift
        /// do {
        ///     try resourceLoadingRequest.streamingContentKeyRequestData(forApp: certificate, contentIdentifier: contentIdentifier, options: resourceLoadingRequestOptions)
        /// }
        /// catch {
        ///     // serverPlaybackContext error
        /// }
        /// ```
        ///
        /// For more information, please consult Apple's documentation.
        case serverPlaybackContext(error: Error)
        
        // MARK: Content Key Context
        /// `FairplayRequester` could not fetch a *Content Key Context*, `CKC`, since the *license acquisition url* was missing.
        case missingContentKeyContextUrl
        
        /// `CKC`, *content key context*, request data could not be generated because the identifying `playToken` was missing.
        case missingPlaytoken
        
        /// The *Content Key Context* response data contained an unexpected or invalid data format.
        ///
        /// `FairplayRequester` failed to decode the raw data, most likely due to a missmatch between expected and supplied data format.
        case contentKeyContextDataFormatInvalid
        
        /// *Content Key Context* server responded with an error message.
        ///
        /// Details are expressed by `code` and `message`
        case contentKeyContextServer(code: Int, message: String)
        
        /// There was an error while parsing the *Content Key Context*. This is considered a general error
        case contentKeyContextParsing
        
        /// *Content Key Context* server did not respond with an error not a valid `CKC`. This is considered a general error
        case missingContentKeyContext
        
        /// `FairplayRequester` could not complete the resource loading request because its associated `AVAssetResourceLoadingDataRequest` was `nil`. This indicates no data was being requested.
        case missingDataRequest
        
        // MARK: General
        /// Unable to set *contentType* to `AVStreamingKeyDeliveryPersistentContentKeyType` since no content information is requested for the `AVAssetResourceLoadingRequest`.
        case contentInformationRequestMissing
    }
}

extension ExposureDownloadTask.Error.FairplayError {
    public var message: String {
        switch self {
        // Application Certificate
        case .missingApplicationCertificateUrl: return "MISSING_APPLICATION_CERTIFICATE_URL"
        case .networking(error: _): return "FAIRPLAY_NETWORKING_ERROR"
        case .applicationCertificateDataFormatInvalid: return "APPLICATION_CERTIFICATE_DATA_FORMAT_INVALID"
        case .applicationCertificateServer(code: _, message: _): return "APPLICATION_CERTIFICATE_SERVER_ERROR"
        case .applicationCertificateParsing: return "APPLICATION_CERTIFICATE_PARSING_ERROR"
        case .invalidContentIdentifier: return "INVALID_CONTENT_IDENTIFIER"
            
        // Server Playback Context
        case .serverPlaybackContext(error: _): return "SERVER_PLAYBACK_CONTEXT_ERROR"
            
        // Content Key Context
        case .missingContentKeyContextUrl: return "MISSING_CONTENT_KEY_CONTEXT_URL"
        case .missingPlaytoken: return "MISSING_PLAYTOKEN"
        case .contentKeyContextDataFormatInvalid: return "CONTENT_KEY_CONTEXT_DATA_FORMAT_INVALID"
        case .contentKeyContextServer(code: _, message: _): return "CONTENT_KEY_CONTEXT_SERVER_ERROR"
        case .contentKeyContextParsing: return "CONTENT_KEY_CONTEXT_PARSING_ERROR"
        case .missingContentKeyContext: return "MISSING_CONTENT_KEY_CONTEXT"
        case .missingDataRequest: return "MISSING_DATA_REQUEST"
        case .contentInformationRequestMissing: return "CONTENT_INFORMATION_REQUEST_MISSING"
        }
    }
}

extension ExposureDownloadTask.Error.FairplayError {
    /// Returns detailed information about the error
    public var info: String? {
        switch self {
        // Application Certificate
        case .missingApplicationCertificateUrl: return "Application Certificate Url not found"
        case .networking(error: let error): return "Network error while fetching Application Certificate: \(error.localizedDescription)"
        case .applicationCertificateDataFormatInvalid: return "Certificate Data was not encodable using base64"
        case .applicationCertificateServer(code: let code, message: let message): return "Application Certificate server returned error: \(code) with message: \(message)"
        case .applicationCertificateParsing: return "Application Certificate server response lacks parsable data"
        case .invalidContentIdentifier: return "Invalid Content Identifier"
            
        // Server Playback Context
        case .serverPlaybackContext(error: let error): return "Server Playback Context: \(error.localizedDescription)"
            
        // Content Key Context
        case .missingContentKeyContextUrl: return "Content Key Context Url not found"
        case .missingPlaytoken: return "Content Key Context call requires a playtoken"
        case .contentKeyContextDataFormatInvalid: return "Content Key Context was not encodable using base64"
        case .contentKeyContextServer(code: let code, message: let message): return "Content Key Context server returned error: \(code) with message: \(message)"
        case .contentKeyContextParsing: return "Content Key Context server response lacks parsable data"
        case .missingContentKeyContext: return "Content Key Context missing from response"
        case .missingDataRequest: return "Data Request missing"
        case .contentInformationRequestMissing: return "Unable to set contentType on contentInformationRequest"
        }
    }
}

extension ExposureDownloadTask.Error.FairplayError {
    /// Defines the `domain` specific code for the underlying error.
    public var code: Int {
        switch self {
        case .applicationCertificateDataFormatInvalid: return 301
        case .applicationCertificateParsing: return 302
        case .applicationCertificateServer(code: _, message: _): return 303
        case .contentKeyContextDataFormatInvalid: return 304
        case .contentKeyContextParsing: return 305
        case .contentKeyContextServer(code: _, message: _): return 306
        case .invalidContentIdentifier: return 307
        case .missingApplicationCertificateUrl: return 308
        case .missingContentKeyContext: return 309
        case .missingContentKeyContextUrl: return 310
        case .missingDataRequest: return 311
        case .missingPlaytoken: return 312
        case .networking(error: _): return 313
        case .serverPlaybackContext(error: _): return 314
        case .contentInformationRequestMissing: return 315
        }
    }
}

public final class ExposureDownloadTask: TaskType {
    
    internal var entitlementRequest: ExposureRequest<PlayBackEntitlementV2>?
    
    /// The `PlaybackEntitlement` granted for this download request.
    fileprivate(set) public var entitlement: PlayBackEntitlementV2?
    
    internal(set) public var task: AVAssetDownloadTask?
    public var configuration: Configuration
    public var responseData: ResponseData
    public var fairplayRequester: FairplayRequester?
    public let eventPublishTransmitter = Download.EventPublishTransmitter<ExposureDownloadTask>()
    public var analyticsProvider: ExposureDownloadAnalyticsProvider
    
    public let sessionManager: Download.SessionManager<ExposureDownloadTask>
    
    
    
    public lazy var delegate: Download.TaskDelegate = { [unowned self] in
        return Download.TaskDelegate(task: self)
    }()
    
    internal init(assetId: String, sessionManager: Download.SessionManager<ExposureDownloadTask>, analyticsProvider: ExposureDownloadAnalyticsProvider) {
        self.configuration = Configuration(identifier: assetId)
        self.responseData = ResponseData()
        
        self.sessionManager = sessionManager
        self.playRequest = PlayRequest()
        
        self.analyticsProvider = analyticsProvider
    }
    
    // DRMRequest
    public var playRequest: PlayRequest
    
    // MARK: Entitlement
    internal var onEntitlementRequestStarted: (ExposureDownloadTask) -> Void = { _ in }
    internal var onEntitlementResponse: (ExposureDownloadTask, PlayBackEntitlementV2) -> Void = { _,_ in }
    internal var onEntitlementRequestCancelled: (ExposureDownloadTask) -> Void = { _ in }
}

extension ExposureDownloadTask: DRMRequest { }


extension ExposureDownloadTask {
    fileprivate func prepareFrom(offlineMediaAsset: OfflineMediaAsset, lazily: Bool, callback: @escaping () -> Void) {
        print("📍 Preparing ExposureDownloadTask from OfflineMediaAsset: \(offlineMediaAsset.assetId), lazily: \(lazily)")
        offlineMediaAsset.state{ [weak self] state in
            guard let weakSelf = self else { return }
            switch state {
            case .completed(entitlement: let entitlement, url: let url):
                weakSelf.onEntitlementResponse(weakSelf, entitlement)
                weakSelf.entitlement = entitlement
                // TODO: Ask for AdditionalMediaSelections?
                weakSelf.eventPublishTransmitter.onCompleted(weakSelf, url)
                weakSelf.analyticsProvider.downloadCompletedEvent(task: weakSelf)
                callback()
            case .notPlayable(entitlement: let entitlement, url: _):
                if let entitlement = entitlement {
                    weakSelf.restoreOrCreate(for: entitlement, forceNew: lazily, callback: callback)
                }
                else {
                    weakSelf.startEntitlementRequest(assetId: weakSelf.configuration.identifier, lazily: lazily, callback: callback)
                }
            }
        }
    }
    
    fileprivate func restoreOrCreate(for entitlement: PlayBackEntitlementV2, forceNew: Bool, callback: @escaping () -> Void = { }) {
        fairplayRequester = ExposureDownloadFairplayRequester(entitlement: entitlement, assetId: configuration.identifier)
        
        configuration.url = entitlement.formats?.first?.mediaLocator
        
        sessionManager.restoreTask(with: configuration.identifier) { [weak self] restoredTask in
            guard let weakSelf = self else { return }
            if let restoredTask = restoredTask {
                weakSelf.configureResourceLoader(for: restoredTask)
                
                weakSelf.task = restoredTask
                weakSelf.sessionManager.delegate[restoredTask] = weakSelf
                
                weakSelf.handle(restoredTask: restoredTask)
            }
            else {
                if forceNew {
                    print("✅ No AVAssetDownloadTask prepared, creating new for: \(weakSelf.configuration.identifier)")
                    // Create a fresh task
                    let options = weakSelf.configuration.requiredBitrate != nil ? [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: weakSelf.configuration.requiredBitrate!] : nil
                    weakSelf.createAndConfigureTask(with: options, using: weakSelf.configuration) { urlTask, error in
                        if let error = error {
                            weakSelf.eventPublishTransmitter.onError(weakSelf, weakSelf.responseData.destination, error)
                            weakSelf.analyticsProvider.downloadErrorEvent(task: weakSelf, error: ExposureDownloadTask.Error.taskError(reason: error))
                            return
                        }
                        
                        if let urlTask = urlTask {
                            weakSelf.task = urlTask
                            weakSelf.sessionManager.delegate[urlTask] = weakSelf
                            print("👍 DownloadTask prepared")
                            weakSelf.eventPublishTransmitter.onPrepared(weakSelf)
                            weakSelf.analyticsProvider.downloadStartedEvent(task: weakSelf)
                        }
                        callback()
                    }
                }
            }
        }
    }
    
    fileprivate func startEntitlementRequest(assetId: String, lazily: Bool, callback: @escaping () -> Void) {
        // Prepare the next event
        analyticsProvider.onEntitlementRequested(tech: self, assetId: assetId)
        
        entitlementRequest = Entitlement(environment: analyticsProvider.environment,
                                         sessionToken: analyticsProvider.sessionToken)
            .download(assetId: assetId)
            .use(drm: playRequest.drm)
            .use(format: playRequest.format)
            .request()
            .validate()
            .response{ [weak self] in
                guard let weakSelf = self else { return }
                guard let entitlement = $0.value else {
                    weakSelf.eventPublishTransmitter.onError(weakSelf, nil, $0.error!)
                    weakSelf.analyticsProvider.downloadErrorEvent(task: weakSelf, error: ExposureDownloadTask.Error.exposure(reason: $0.error!))
                    return
                }
                
                weakSelf.analyticsProvider.onHandshakeStarted(tech: weakSelf, source: entitlement, assetId: assetId)
                weakSelf.analyticsProvider.finalizePreparation(assetId: assetId, with: entitlement) {
                    return Playback.Heartbeat(timestamp: Date().millisecondsSince1970)
                }
                
                
                weakSelf.entitlementRequest = nil
                weakSelf.entitlement = entitlement
                weakSelf.onEntitlementResponse(weakSelf, entitlement)
                
                weakSelf.sessionManager.save(assetId: assetId, entitlement: entitlement, url: nil)
                
                weakSelf.restoreOrCreate(for: entitlement, forceNew: !lazily, callback: callback)
        }
    }
}

extension ExposureDownloadTask {
    /// - parameter lazily: `true` will delay creation of new tasks until the user calls `resume()`. `false` will force create the task if none exists.
    @discardableResult
    public func prepare(lazily: Bool = true) -> ExposureDownloadTask {
        guard let task = task else {
            if let currentAsset = sessionManager.offline(assetId: configuration.identifier) {
                prepareFrom(offlineMediaAsset: currentAsset, lazily: lazily) {
                    
                }
            }
            else {
                startEntitlementRequest(assetId: configuration.identifier, lazily: lazily) {
                    
                }
            }
            return self
        }
        handle(restoredTask: task)
        return self
    }
    
    
    public func resume() {
        guard let downloadTask = task else {
            guard let entitlementRequest = entitlementRequest else {
                startEntitlementRequest(assetId: configuration.identifier, lazily: false) { [weak self] in
                    guard let `self` = self else { return }
                    `self`.task?.resume()
                    `self`.eventPublishTransmitter.onResumed(`self`)
                    `self`.analyticsProvider.downloadResumedEvent(task: `self`)
                }
                return
            }
            entitlementRequest.resume()
            eventPublishTransmitter.onResumed(self) // TODO: Remove pause/resume functionality for entitlementreq
            analyticsProvider.downloadResumedEvent(task: self)
            return
        }
        downloadTask.resume()
        eventPublishTransmitter.onResumed(self)
        analyticsProvider.downloadResumedEvent(task: self)
    }
    
    public func suspend() {
        if let downloadTask = task {
            downloadTask.suspend()
            eventPublishTransmitter.onSuspended(self)
            analyticsProvider.downloadPausedEvent(task: self)
        }
        else if let entitlementRequest = entitlementRequest {
            entitlementRequest.suspend()
            eventPublishTransmitter.onSuspended(self) // TODO: Remove pause/resume functionality for entitlementreq
            analyticsProvider.downloadPausedEvent(task: self)
        }
    }
    
    public func cancel() {
        if let downloadTask = task {
            downloadTask.cancel()
        }
        else if let entitlementRequest = entitlementRequest {
            entitlementRequest.cancel()
            onEntitlementRequestCancelled(self)
        }
    }
    
    public func use(bitrate: Int64?) -> Self {
        self.configuration.requiredBitrate = bitrate
        return self
    }
    
    public enum State {
        case notStarted
        case running
        case suspended
        case canceling
        case completed
    }
    
    public var state: State {
        guard let state = task?.state else { return .notStarted }
        switch state {
        case .running: return .running
        case .suspended: return .suspended
        case .canceling: return .canceling
        case .completed: return .completed
        }
    }
}

extension ExposureDownloadTask: Download.EventPublisher {
    public typealias DownloadEventError = TaskError
    
    public func onResumed(callback: @escaping (ExposureDownloadTask) -> Void) -> ExposureDownloadTask {
        eventPublishTransmitter.onResumed = { task in
            callback(task)
        }
        return self
    }
    
    public func onSuspended(callback: @escaping (ExposureDownloadTask) -> Void) -> ExposureDownloadTask {
        eventPublishTransmitter.onSuspended = { task in
            callback(task)
        }
        return self
    }
    
    public func onCanceled(callback: @escaping (ExposureDownloadTask, URL) -> Void) -> ExposureDownloadTask {
        eventPublishTransmitter.onCanceled = { [weak self] task, url in
            guard let `self` = self else { return }
            `self`.analyticsProvider.downloadCancelledEvent(task: task)
            `self`.analyticsProvider.downloadStoppedEvent(task: task)
            callback(task,url)
        }
        return self
    }
    
//    public func onStarted(callback:
    
    public func onCompleted(callback: @escaping (ExposureDownloadTask, URL) -> Void) -> ExposureDownloadTask {
        eventPublishTransmitter.onCompleted = { [weak self] task, url in
            guard let `self` = self else { return }
            `self`.sessionManager.save(assetId: `self`.configuration.identifier, entitlement: `self`.entitlement, url: url)
            `self`.analyticsProvider.downloadCompletedEvent(task: task)
            callback(task,url)
        }
        return self
    }
    
    public func onError(callback: @escaping (ExposureDownloadTask, URL?, Swift.Error) -> Void) -> ExposureDownloadTask {
        eventPublishTransmitter.onError = { [weak self] task, url, error in
            guard let `self` = self else { return }
            `self`.sessionManager.save(assetId: `self`.configuration.identifier, entitlement: `self`.entitlement, url: url)
            callback(task,url, error)
        }
        return self
    }
}

extension ExposureDownloadTask {
    @discardableResult
    public func onEntitlementRequestStarted(callback: @escaping (ExposureDownloadTask) -> Void) -> ExposureDownloadTask {
        onEntitlementRequestStarted = callback
        return self
    }
    
    @discardableResult
    public func onEntitlementResponse(callback: @escaping (ExposureDownloadTask, PlayBackEntitlementV2) -> Void) -> ExposureDownloadTask {
        onEntitlementResponse = callback
        return self
    }
    
    @discardableResult
    public func onEntitlementRequestCancelled(callback: @escaping (ExposureDownloadTask) -> Void) -> ExposureDownloadTask {
        onEntitlementRequestCancelled = callback
        return self
    }
}
