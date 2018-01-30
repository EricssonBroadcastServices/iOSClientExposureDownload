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

public final class ExposureDownloadTask: TaskType {
    internal var entitlementRequest: ExposureRequest<PlaybackEntitlement>?
    
    /// The `PlaybackEntitlement` granted for this download request.
    fileprivate(set) public var entitlement: PlaybackEntitlement?
    
    internal(set) public var task: AVAssetDownloadTask?
    public var configuration: Configuration
    public var responseData: ResponseData
    public var fairplayRequester: DownloadFairplayRequester?
    public let eventPublishTransmitter = Download.EventPublishTransmitter<ExposureDownloadTask>()
    public var analyticsProvider: ExposureDownloadAnalyticsProvider
    
    public let sessionManager: SessionManager<ExposureDownloadTask>
    
    
    
    public lazy var delegate: Download.TaskDelegate = { [unowned self] in
        return Download.TaskDelegate(task: self)
    }()
    
    internal init(assetId: String, sessionManager: SessionManager<ExposureDownloadTask>, analyticsProvider: ExposureDownloadAnalyticsProvider) {
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
    internal var onEntitlementResponse: (ExposureDownloadTask, PlaybackEntitlement) -> Void = { _,_ in }
    internal var onEntitlementRequestCancelled: (ExposureDownloadTask) -> Void = { _,_ in }
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
    
    fileprivate func restoreOrCreate(for entitlement: PlaybackEntitlement, forceNew: Bool, callback: @escaping () -> Void = { _ in }) {
        fairplayRequester = ExposureDownloadFairplayRequester(entitlement: entitlement, assetId: configuration.identifier)
        
        configuration.url = entitlement.mediaLocator
        
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
                            weakSelf.analyticsProvider.downloadErrorEvent(task:weakSelf, error: error)
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
                    weakSelf.analyticsProvider.downloadErrorEvent(task: weakSelf, error: $0.error!)
                    return
                }
                
                weakSelf.analyticsProvider.onHandshakeStarted(tech: weakSelf, source: entitlement, assetId: assetId)
                weakSelf.analyticsProvider.finalizePreparation(assetId: assetId, with: entitlement, heartbeatsProvider: weakSelf)
                
                
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
    public typealias DownloadEventError = ExposureError
    
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
    
    public func onError(callback: @escaping (ExposureDownloadTask, URL?, ExposureError) -> Void) -> ExposureDownloadTask {
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
    public func onEntitlementResponse(callback: @escaping (ExposureDownloadTask, PlaybackEntitlement) -> Void) -> ExposureDownloadTask {
        onEntitlementResponse = callback
        return self
    }
    
    @discardableResult
    public func onEntitlementRequestCancelled(callback: @escaping (ExposureDownloadTask) -> Void) -> ExposureDownloadTask {
        onEntitlementRequestCancelled = callback
        return self
    }
}
