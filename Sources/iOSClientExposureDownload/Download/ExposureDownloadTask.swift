//
//  ExposureDownloadTask.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2017-10-13.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import AVFoundation
import iOSClientDownload
import iOSClientExposure

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

public final class ExposureDownloadTask: NSObject, ContentKeyManager, TaskType, AVAssetResourceLoaderDelegate {
    
    internal var entitlementRequest: ExposureRequest<PlayBackEntitlementV2>?
    
    /// The `PlaybackEntitlement` granted for this download request.
    fileprivate(set) public var entitlement: PlayBackEntitlementV2?
    
    internal(set) public var task: AVAggregateAssetDownloadTask?
    public var configuration: Configuration
    public var responseData: ResponseData
    public var fairplayRequester: FairplayRequester?
    public let eventPublishTransmitter = iOSClientDownload.EventPublishTransmitter<ExposureDownloadTask>()
    
    public let sessionManager: iOSClientDownload.SessionManager<ExposureDownloadTask>
    public let sessionToken: SessionToken
    public let environment: Environment
    
    internal let resourceLoadingRequestQueue = DispatchQueue(label: "com.emp.exposure.offline.fairplay.requests")
    internal let resourceLoadingRequestOptions: [String : AnyObject]? = [AVAssetResourceLoadingRequestStreamingContentKeyRequestRequiresPersistentKey: true as AnyObject]
    
    
    public lazy var delegate: iOSClientDownload.TaskDelegate = { [unowned self] in
        return iOSClientDownload.TaskDelegate(task: self)
        }()
    
    internal init(assetId: String, sessionManager: iOSClientDownload.SessionManager<ExposureDownloadTask> , sessionToken: SessionToken, environment: Environment) {
        self.configuration = Configuration(identifier: assetId)
        self.responseData = ResponseData()
        
        self.sessionManager = sessionManager
        self.playRequest = PlayRequest()
        
        self.sessionToken = sessionToken
        self.environment = environment
        
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
        offlineMediaAsset.state{state in
            switch state {
            case .completed(entitlement: let entitlement, url: let url):
                self.onEntitlementResponse(self, entitlement)
                self.entitlement = entitlement
                // TODO: Ask for AdditionalMediaSelections?
                self.eventPublishTransmitter.onCompleted(self, url)
                callback()
            case .notPlayable(entitlement: let entitlement, url: _):
                if let entitlement = entitlement {
                    self.restoreOrCreate(for: entitlement, forceNew: lazily, callback: callback)
                }
                else {
                    self.startEntitlementRequest(assetId: self.configuration.identifier, lazily: lazily, callback: callback)
                }
            }
        }
    }
    
    fileprivate func restoreOrCreate(for entitlement: PlayBackEntitlementV2, forceNew: Bool, callback: @escaping () -> Void = { }) {
        fairplayRequester = ExposureDownloadFairplayRequester(entitlement: entitlement, assetId: configuration.identifier)
        
        configuration.url = entitlement.formats?.first?.mediaLocator
        
        sessionManager.restoreTask(with: configuration.identifier) { restoredTask in
            
            if let restoredTask = restoredTask {
                self.configureResourceLoader(for: restoredTask)
                
                self.task = restoredTask
                self.sessionManager.delegate[restoredTask] = self
                
                self.handle(restoredTask: restoredTask)
            }
            else {
 
                if forceNew {
                    print("✅ No AVAssetDownloadTask prepared, creating new for: \(self.configuration.identifier)")
                    // Create a fresh task
                    
                    var options = [String: Any]()
                    
                    // Use both bitrate & presentationSize if available
                    if let requiredbitRate = self.configuration.requiredBitrate {
                        if #available(iOS 14.0, *) {
                            options = [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: requiredbitRate]
                            if let presentationSize = self.configuration.presentationSize {
                                options = [AVAssetDownloadTaskMinimumRequiredPresentationSizeKey: presentationSize]
                            }
                            
                        } else {
                            options = [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: requiredbitRate]
                        }
                    }

                    self.createAndConfigureTask(with: options, using: self.configuration) { urlTask, error in
                        if let error = error {
                            self.eventPublishTransmitter.onError(self, self.responseData.destination, error)
                            return
                        }
                        
                        if let urlTask = urlTask {
                            self.task = urlTask
                            self.sessionManager.delegate[urlTask] = self
                            print("👍 DownloadTask prepared")
                            self.eventPublishTransmitter.onPrepared(self)
                        }
                        callback()
                    }
                }
            }
        }
    }
    
    fileprivate func startEntitlementRequest(assetId: String, lazily: Bool, callback: @escaping () -> Void) {
        // Prepare the next event
        entitlementRequest = Entitlement(environment:environment,
                                         sessionToken: sessionToken)
            .download(assetId: assetId)
            .request()
            .validate()
            .response{
                guard let entitlement = $0.value else {
                    
                    self.eventPublishTransmitter.onError(self, nil, $0.error!)
                    
                    return
                }
                
                self.entitlementRequest = nil
                self.entitlement = entitlement
                self.onEntitlementResponse(self, entitlement)
                
                self.sessionManager.save(assetId: assetId, accountId: self.sessionToken.accountId, userId: self.sessionToken.userId, entitlement: entitlement, url: nil, downloadState: .started)
                
                self.restoreOrCreate(for: entitlement, forceNew: !lazily, callback: callback)
        }
    }
    
    
    /// Validate the download
    /// - Parameters:
    ///   - assetId: asset id
    ///   - completionHandler: completionHandler
    fileprivate func validateEntitlementRequest(assetId: String, completionHandler: @escaping (PlayBackEntitlementV2?, ExposureError?) -> Void) {
        
        entitlementRequest = Entitlement(environment:environment,
                                         sessionToken: sessionToken)
            .validate(downloadId: self.configuration.identifier)
            .request()
            .validate()
            .response {
                guard let entitlement = $0.value else {
                    self.eventPublishTransmitter.onError(self, nil, $0.error!)
                    completionHandler(nil, $0.error)
                    return
                }
                completionHandler(entitlement, nil )
        }
    }
    
    
    /// create the RefreshLicenceTask
    /// - Parameters:
    ///   - assetId: asset id
    ///   - lazily: lazily
    ///   - callback: call back
    fileprivate func createRefreshLicenceTask(assetId: String, lazily: Bool, callback: @escaping () -> Void) {
        validateEntitlementRequest(assetId: assetId) { entitlement, error in
            if let error = error {
                self.eventPublishTransmitter.onError(self, nil, error)
            }
            
            guard let url = entitlement?.formats?.first?.mediaLocator  else {
                self.eventPublishTransmitter.onError(self, nil, ExposureDownloadTask.Error.fairplay(reason: .missingPlaytoken))
                return
            }
            
            self.configuration.url = url
            
            self.sessionManager.restoreTask(with: self.configuration.identifier) { restoredTask in

                let options = self.configuration.requiredBitrate != nil ? [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: self.configuration.requiredBitrate!] : nil
                
                if let url = self.configuration.url {
                    let asset = AVURLAsset(url: url)
                    
                    asset.resourceLoader.preloadsEligibleContentKeys = true
                    asset.resourceLoader.setDelegate(self, queue: DispatchQueue.main)
                    
                    
                    guard let task = self.sessionManager.session.aggregateAssetDownloadTask(with: asset, mediaSelections: asset.allMediaSelections, assetTitle: self.configuration.identifier, assetArtworkData: self.configuration.artwork, options: options) else {
                            // This method may return nil if the AVAssetDownloadURLSession has been invalidated.
                            print("Error downloadSessionInvalidated")
                        return
                    }
                    
                    task.taskDescription = self.configuration.identifier
    
                    let queue = DispatchQueue(label: self.configuration.identifier + "-offlineFairplayLoader")
                    task.urlAsset
                        .resourceLoader
                        .setDelegate(self, queue: queue)
                    
                    self.sessionManager.delegate[task] = self
                    self.eventPublishTransmitter.onPrepared(self)
                }
                
                print("✅ No AVAssetDownloadTask prepared, creating new for: \(self.configuration.identifier)")
            }
        }
        
        
    }
    
    private func createAndConfigureTaskForUpdate(with options: [String: Any]?, using configuration: Configuration, callback: (AVAggregateAssetDownloadTask?, TaskError?) -> Void) {
        guard let url = configuration.url else {
            callback(nil, TaskError.targetUrlNotFound)
            return
        }
        
        
        guard let task = self.sessionManager.session.aggregateAssetDownloadTask(with: AVURLAsset(url: url), mediaSelections: [], assetTitle: self.configuration.identifier, assetArtworkData: self.configuration.artwork, options: options) else {
                // This method may return nil if the AVAssetDownloadURLSession has been invalidated.
                callback(nil, TaskError.downloadSessionInvalidated)
                return
        }
        
        task.taskDescription = configuration.identifier
        configureResourceLoader(for: task)
        callback(task,nil)
    }
    
    
    
    /// Update the licence for the downloaded asset id
    /// - Parameter resourceLoadingRequest: resourceLoadingRequest
    func updateCertificate(resourceLoadingRequest: AVAssetResourceLoadingRequest) {
        
        guard let url = resourceLoadingRequest.request.url,
            let assetIDString = url.host,
            let contentIdentifier = assetIDString.data(using: String.Encoding.utf8) else {
                resourceLoadingRequest.finishLoading(with: ExposureDownloadTask.Error.fairplay(reason: .invalidContentIdentifier))
                return
        }
        
        self.validateEntitlementRequest(assetId: self.configuration.identifier) { entitlement, error in
            if let error = error {
                self.eventPublishTransmitter.onError(self, nil, error )
            }
            
            guard let certificateurl = entitlement?.formats?.first?.fairplay.first?.certificateUrl else {
                print("certificateUrl in the entitlement is missing")
                resourceLoadingRequest.finishLoading(with: ExposureDownloadTask.Error.fairplay(reason: .missingApplicationCertificateUrl))
                self.eventPublishTransmitter.onError(self, nil,ExposureDownloadTask.Error.fairplay(reason: .missingApplicationCertificateUrl))
                return
            }
            
            guard let certificateUrl = URL(string: certificateurl) else  {
                print("Failed converting certificateUrl string to URL")
                resourceLoadingRequest.finishLoading(with: ExposureDownloadTask.Error.fairplay(reason: .missingApplicationCertificateUrl))
                self.eventPublishTransmitter.onError(self, nil,ExposureDownloadTask.Error.fairplay(reason: .missingApplicationCertificateUrl))
                return
                
            }
            
            self.fetchApplicationCertificate(certificateUrl: certificateUrl) { [unowned self] certificate, certificateError in
                if let certificateError = certificateError {
                    resourceLoadingRequest.finishLoading(with: certificateError)
                    self.eventPublishTransmitter.onError(self, nil,certificateError)
                    return
                }
                
                if let certificate = certificate {
                    do {
                        let spcData = try resourceLoadingRequest.streamingContentKeyRequestData(forApp: certificate, contentIdentifier: contentIdentifier, options: self.resourceLoadingRequestOptions)
                        
                        guard let playToken = entitlement?.playToken, let licenseServerUrl = entitlement?.formats?.first?.fairplay.first?.licenseServerUrl else {
                            self.eventPublishTransmitter.onError(self, nil,ExposureDownloadTask.Error.fairplay(reason: .missingPlaytoken))
                            return
                        }
                        
                        guard let licenseUrl = URL(string: licenseServerUrl) else {
                            print("Failed converting licenseUrl string to URL")
                            self.eventPublishTransmitter.onError(self, nil, ExposureDownloadTask.Error.fairplay(reason: .missingApplicationCertificateUrl))
                            return
                            
                        }
                        
                        
                        self.fetchContentKeyContext(licenseUrl: licenseUrl, playToken: playToken, spc: spcData) { ckcBase64, ckcError in
                            if let ckcError = ckcError {
                                
                                print("CKC Error ", ckcError.localizedDescription)
                                
                                resourceLoadingRequest.finishLoading(with: ckcError)
                                self.eventPublishTransmitter.onError(self, nil, ckcError)
                                return
                            }
                            
                            guard let dataRequest = resourceLoadingRequest.dataRequest else {
                                print("dataRequest Error",ExposureDownloadTask.Error.fairplay(reason: .missingDataRequest).message)
                                resourceLoadingRequest.finishLoading(with: ExposureDownloadTask.Error.fairplay(reason: .missingDataRequest))
                                self.eventPublishTransmitter.onError(self, nil, ExposureDownloadTask.Error.fairplay(reason: .missingDataRequest))
                                return
                            }
                            
                            guard let ckcBase64 = ckcBase64 else {
                                print("ckcBase64 Error",ExposureDownloadTask.Error.fairplay(reason: .missingContentKeyContext).message)
                                resourceLoadingRequest.finishLoading(with: ExposureDownloadTask.Error.fairplay(reason: .missingContentKeyContext))
                                self.eventPublishTransmitter.onError(self, nil, ExposureDownloadTask.Error.fairplay(reason: .missingContentKeyContext))
                                return
                            }
                            
                            do {
                                resourceLoadingRequest.contentInformationRequest?.contentType = AVStreamingKeyDeliveryPersistentContentKeyType
                                
                                let (contentKey, contentKeyUrl) = try self.onSuccessfulRetrieval(assetId: self.configuration.identifier, of: ckcBase64, for: resourceLoadingRequest)
                                dataRequest.respond(with: contentKey)
                                resourceLoadingRequest.finishLoading()
                                // sendDownloadRenewed(assetId: assetIDString)
                                
                                self.eventPublishTransmitter.onLicenceRenewed(self, contentKeyUrl)
                                
                                
                            } catch {
                                print("Catch Errior elf?.onSuccessfulRetrieval" , error )
                                resourceLoadingRequest.finishLoading(with: error)
                                self.eventPublishTransmitter.onError(self, nil, error)
                            }
                            
                        }
                        
                    }
                    catch {
                        //                    -42656 Lease duration has expired.
                        //                    -42668 The CKC passed in for processing is not valid.
                        //                    -42672 A certificate is not supplied when creating SPC.
                        //                    -42673 assetId is not supplied when creating an SPC.
                        //                    -42674 Version list is not supplied when creating an SPC.
                        //                    -42675 The assetID supplied to SPC creation is not valid.
                        //                    -42676 An error occurred during SPC creation.
                        //                    -42679 The certificate supplied for SPC creation is not valid.
                        //                    -42681 The version list supplied to SPC creation is not valid.
                        //                    -42783 The certificate supplied for SPC is not valid and is possibly revoked.
                        print("SPC - ",error.localizedDescription)
                        resourceLoadingRequest.finishLoading(with: ExposureDownloadTask.Error.fairplay(reason: .serverPlaybackContext(error: error)))
                        self.eventPublishTransmitter.onError(self, nil, ExposureDownloadTask.Error.fairplay(reason: .serverPlaybackContext(error: error)))
                        return
                    }
                }
            }
            
        }
    }
    
    
    func onSuccessfulRetrieval(assetId: String, of ckc: Data, for resourceLoadingRequest: AVAssetResourceLoadingRequest) throws -> (Data, URL) {
        let persistedKeyURL = try contentKeyUrl(for: assetId)
        let persistedCKC = try resourceLoadingRequest.persistentContentKey(fromKeyVendorResponse: ckc, options: nil)
        try persistedCKC.write(to: persistedKeyURL, options: Data.WritingOptions.atomicWrite)
        print("renewed license saved at :  ", persistedKeyURL)
        return (persistedCKC, persistedKeyURL)
    }
    
    internal func canHandle(resourceLoadingRequest: AVAssetResourceLoadingRequest) ->Bool {
        resourceLoadingRequestQueue.async { [weak self] in
            self?.updateCertificate(resourceLoadingRequest: resourceLoadingRequest)
        }
        return true
    }
    
    
    
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        print("shouldWaitForLoadingOfRequestedResource")
        return canHandle(resourceLoadingRequest: loadingRequest)
    }
    
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest) -> Bool {
        print("shouldWaitForRenewalOfRequestedResource")
        return canHandle(resourceLoadingRequest: renewalRequest)
    }
}

extension ExposureDownloadTask {
    /// - parameter lazily: `true` will delay creation of new tasks until the user calls `resume()`. `false` will force create the task if none exists.
    @discardableResult
    public func prepare(lazily: Bool = true) -> ExposureDownloadTask {
        guard let task = task else {
            
            if let currentAsset = sessionManager.getDownloadedAsset(assetId: configuration.identifier) {
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
                }
                return
            }
            entitlementRequest.resume()
            eventPublishTransmitter.onResumed(self) // TODO: Remove pause/resume functionality for entitlementreq
            return
        }
        downloadTask.resume()
        eventPublishTransmitter.onResumed(self)
    }
    
    public func suspend() {
        if let downloadTask = task {
            downloadTask.suspend()
            eventPublishTransmitter.onSuspended(self)
        }
        else if let entitlementRequest = entitlementRequest {
            entitlementRequest.suspend()
            eventPublishTransmitter.onSuspended(self) // TODO: Remove pause/resume functionality for entitlementreq
        }
        
        
        /// Update the download state: suspend in local media record
        let localRecord = self.sessionManager.getDownloadedAsset(assetId: configuration.identifier)
        self.sessionManager.save(assetId: configuration.identifier, accountId: localRecord?.accountId, userId: localRecord?.userId, entitlement: localRecord?.entitlement, url: localRecord?.urlAsset?.url ?? nil, downloadState: .suspend)
        
       
    }
    
    public func cancel() {
        if let downloadTask = task {
            downloadTask.cancel()
        }
        else if let entitlementRequest = entitlementRequest {
            entitlementRequest.cancel()
            onEntitlementRequestCancelled(self)
        }
        
        /// Update the download state: cancel in local media record
        let localRecord = self.sessionManager.getDownloadedAsset(assetId: configuration.identifier)
        self.sessionManager.save(assetId: configuration.identifier, accountId: localRecord?.accountId, userId: localRecord?.userId, entitlement: localRecord?.entitlement, url: localRecord?.urlAsset?.url ?? nil, downloadState: .cancel)
    }
    
    
    /// Download the video track with specific bitrate
    /// - Parameters:
    ///   - bitrate: bitrate: bitrate
    ///   - resolution: resolution: resolution of the stream
    /// - Returns: self
    public func use(bitrate: Int64?, presentationSize: CGSize? = nil ) -> Self {
        self.configuration.requiredBitrate = bitrate
        self.configuration.presentationSize = presentationSize
        return self
    }
    
    
    /// Download specific subtitles
    /// - Parameter hlsNames: hlsNames
    /// - Returns: self
    public func addSubtitles(hlsNames: [String] ) -> Self {
        self.configuration.subtitles = hlsNames
        return self
    }
    
    
    /// Download specific audios
    /// - Parameter hlsNames: hlsNames
    /// - Returns: self
    public func addAudios(hlsNames: [String] ) -> Self {
        self.configuration.audios = hlsNames
        return self
    }
    
    
    /// Download All Audios & subtitles
    /// - Returns: self
    public func addAllAdditionalMedia() -> Self {
        self.configuration.allAudiosSubs = true
        return self
    }
    
    
    
    /// Refresh fairplay licences
    public func renewLicence() {
        guard let downloadTask = task else {
            guard let entitlementRequest = entitlementRequest else {
                createRefreshLicenceTask(assetId: configuration.identifier, lazily: false) { [weak self] in
                    guard let `self` = self else { return }
                    `self`.task?.resume()
                    `self`.eventPublishTransmitter.onResumed(`self`)
                }
                return
            }
            entitlementRequest.resume()
            eventPublishTransmitter.onResumed(self) // TODO: Remove pause/resume functionality for entitlementreq
            return
        }
        downloadTask.resume()
        eventPublishTransmitter.onResumed(self)
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

extension ExposureDownloadTask: iOSClientDownload.EventPublisher {
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
            self.sessionManager.remove(localRecordId: task.configuration.identifier)
            // Clean up already downloaded file from the device
            do {
                try FileManager.default.removeItem(at: url)
                print("🚮 Downloaded media was successfully deleted from \(url)")
            } catch {
                print(error.localizedDescription )
            }
            
            callback(task, url)
        }
        return self
    }
    
    public func onCompleted(callback: @escaping (ExposureDownloadTask, URL) -> Void) -> ExposureDownloadTask {
        eventPublishTransmitter.onCompleted = { [weak self] task, url in
            guard let `self` = self else { return }

            // Inform the exposure backend that the download has completed
            self.sendDownloadCompleted(assetId: `self`.configuration.identifier)
            
            `self`.sessionManager.save(assetId: `self`.configuration.identifier, accountId: self.sessionToken.accountId, userId: self.sessionToken.userId, entitlement: `self`.entitlement, url: url, downloadState: .completed)
            callback(task,url)
        }
        return self
    }
    
    public func onError(callback: @escaping (ExposureDownloadTask, URL?, Swift.Error) -> Void) -> ExposureDownloadTask {
        eventPublishTransmitter.onError = { [weak self] task, url, error in
            guard let `self` = self else { return }

            `self`.sessionManager.save(assetId: `self`.configuration.identifier, accountId: self.sessionToken.accountId, userId:  self.sessionToken.userId, entitlement: `self`.entitlement, url: url, downloadState: .suspend)
            
            
            callback(task,url, error)
        }
        return self
    }
    
    
    public func onLicenceRenewed(callback: @escaping (ExposureDownloadTask, URL) -> Void) -> ExposureDownloadTask {
        eventPublishTransmitter.onLicenceRenewed = { [weak self] task, url in
            guard let `self` = self else { return }

            // Inform the exposure backend that the licence has renewed
            self.sendDownloadRenewed(assetId: `self`.configuration.identifier)
            
            `self`.sessionManager.save(assetId: `self`.configuration.identifier, accountId: self.sessionToken.accountId, userId: self.sessionToken.userId, entitlement: `self`.entitlement, url: url, downloadState: .completed)
            callback(task,url)
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

extension ExposureDownloadTask {
    
    
    /// Send download renewal completion to the exposure
    /// - Parameter assetId: assetId
    internal func sendDownloadRenewed(assetId: String) {
        SendDownloadRenewed(assetId: assetId, environment: environment, sessionToken: sessionToken)
            .request()
            .validate()
            .response { result in
                if result.error != nil {
                    // Ignore any errors , keep the downloaded media
                    print("🚨 DownloadRenewed request to the Backend was failed. Error from Exposure : \(result.error )" )
                } else {
                    print("✅ DownloadRenewed request to the Backend was success. Message from Exposure : \(result.value )" )
                }
            }
    }
    
    /// Send the download completion to the exposure
    /// - Parameter assetId: asset id
    internal func sendDownloadCompleted(assetId: String) {
        SendDownloadCompleted(assetId: assetId, environment: environment, sessionToken: sessionToken)
        .request()
        .validate()
        .response { result in
            if result.error != nil {
                // Ignore any errors , keep the downloaded media
                print("🚨 Download completion request to the Backend was failed. Error from Exposure : \(result.error )" )
            } else {
                print("✅ Download completion request to the Backend was success. Message from Exposure : \(result.value )" )
            }
        }
    }
}
