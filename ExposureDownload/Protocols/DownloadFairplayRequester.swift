//
//  ExposureFairplayRequester.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2017-07-03.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import AVFoundation
import Exposure

internal protocol DownloadFairplayRequester: class, ContentKeyManager {
    /// Entitlement related to this specific *Fairplay* request.
    var entitlement: PlayBackEntitlementV2 { get }
    
    /// The DispatchQueue to use for AVAssetResourceLoaderDelegate callbacks.
    var resourceLoadingRequestQueue: DispatchQueue { get }
    
    /// Options specifying the resource loading request
    var resourceLoadingRequestOptions: [String : AnyObject]? { get }
    
    /// The URL scheme for FPS content.
    var customScheme: String { get }
    
    /// Called when `CKC` data was successfully retrieved from remote server
    ///
    /// - parameter ckc: The `CKC` data retrieved from server
    /// - returns: Key data used to finalize the request
    func onSuccessfulRetrieval(of ckc: Data, for resourceLoadingRequest: AVAssetResourceLoadingRequest) throws-> Data
    
    func shouldContactRemote(for resourceLoadingRequest: AVAssetResourceLoadingRequest) throws -> Bool
}

extension DownloadFairplayRequester {
    /// Starting point for the *Fairplay* validation chain. Note that returning `false` from this method does not automatically mean *Fairplay* validation failed.
    ///
    /// - parameter resourceLoadingRequest: loading request to handle
    /// - returns: ´true` if the requester can handle the request, `false` otherwise.
    internal func canHandle(resourceLoadingRequest: AVAssetResourceLoadingRequest) -> Bool {
    
        guard let url = resourceLoadingRequest.request.url else {
            return false
        }
        
        //EMPFairplayRequester only should handle FPS Content Key requests.
        if url.scheme != customScheme {
            return false
        }
        
        resourceLoadingRequestQueue.async { [weak self] in
            guard let weakSelf = self else { return }
            do {
                
                if try weakSelf.shouldContactRemote(for: resourceLoadingRequest) {
                    weakSelf.handle(resourceLoadingRequest: resourceLoadingRequest)
                }
            }
            catch {
                resourceLoadingRequest.finishLoading(with: error)
            }
        }
        
        return true
    }
}

extension DownloadFairplayRequester {
    /// Handling a *Fairplay* validation request is a process in several parts:
    ///
    /// * Fetch and parse the *Application Certificate*
    /// * Request a *Server Playback Context*, `SPC`, for the specified asset using the *Application Certificate*
    /// * Request a *Content Key Context*, `CKC`, for the validated `SPC`.
    ///
    /// If this process fails, the `resourceLoadingRequest` will call `resourceLoadingRequest.finishLoading(with: someError`.
    ///
    /// For more information regarding *Fairplay* validation, please see Apple's documentation regarding *Fairplay Streaming*.
    fileprivate func handle(resourceLoadingRequest: AVAssetResourceLoadingRequest) {
        
        guard let url = resourceLoadingRequest.request.url,
            let assetIDString = url.host,
            let contentIdentifier = assetIDString.data(using: String.Encoding.utf8) else {
                resourceLoadingRequest.finishLoading(with: ExposureDownloadTask.Error.fairplay(reason: .invalidContentIdentifier))
                return
        }
        
        print(url, " - ",assetIDString)
        
       guard let certificateUrl =  certificateUrl    else {
        resourceLoadingRequest.finishLoading(with: ExposureDownloadTask.Error.fairplay(reason: .missingApplicationCertificateUrl))
            return
        }
        
        // Fetch Fairplay Certificate
        fetchApplicationCertificate(certificateUrl:certificateUrl ) { [unowned self] certificate, certificateError in
            if let certificateError = certificateError {
                resourceLoadingRequest.finishLoading(with: certificateError)
                return
            }
            
            if let certificate = certificate {
                do {
                    let spcData = try resourceLoadingRequest.streamingContentKeyRequestData(forApp: certificate, contentIdentifier: contentIdentifier, options: self.resourceLoadingRequestOptions)
                    
                    
                    guard let url = self.licenseUrl else {
                        resourceLoadingRequest.finishLoading(with: ExposureDownloadTask.Error.fairplay(reason: .missingContentKeyContextUrl))
                        return
                    }
                    
                    
                    guard let playToken = self.entitlement.playToken else {
                        resourceLoadingRequest.finishLoading(with: ExposureDownloadTask.Error.fairplay(reason: .missingPlaytoken))
                        return
                    }
                    
                    
                    // Fetch ContentKeyContext
                    self.fetchContentKeyContext(licenseUrl: url, playToken: playToken, spc: spcData) { ckcBase64, ckcError in
                        if let ckcError = ckcError {
                            print("CKC Error",ckcError.localizedDescription, ckcError.message, ckcError.code)
                            resourceLoadingRequest.finishLoading(with: ckcError)
                            return
                        }
                        
                        guard let dataRequest = resourceLoadingRequest.dataRequest else {
                            print("dataRequest Error",ExposureDownloadTask.Error.fairplay(reason: .missingDataRequest).message)
                            resourceLoadingRequest.finishLoading(with: ExposureDownloadTask.Error.fairplay(reason: .missingDataRequest))
                            return
                        }
                        
                        guard let ckcBase64 = ckcBase64 else {
                            print("ckcBase64 Error",ExposureDownloadTask.Error.fairplay(reason: .missingContentKeyContext).message)
                            resourceLoadingRequest.finishLoading(with: ExposureDownloadTask.Error.fairplay(reason: .missingContentKeyContext))
                            return
                        }
                        
                        do {
                            // Allow implementation specific handling of the returned `CKC`
                            let contentKey = try self.onSuccessfulRetrieval(of: ckcBase64, for: resourceLoadingRequest)
                            
                            // Provide data to the loading request.
                            dataRequest.respond(with: contentKey)
                            resourceLoadingRequest.finishLoading() // Treat the processing of the request as complete.
                        }
                        catch {
                            resourceLoadingRequest.finishLoading(with: error)
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
                    return
                }
            }
        }
    }
}

// MARK: - Application Certificate
extension DownloadFairplayRequester {
    
    /// Retrieve the `certificateUrl` by parsing the *entitlement*.
    fileprivate var certificateUrl: URL? {
        guard let urlString = entitlement.formats?.first?.fairplay.first?.certificateUrl else { return nil }
        return URL(string: urlString)
    }
}


// MARK: - Content Key Context
extension DownloadFairplayRequester {

    /// Retrieve the `licenseUrl` by parsing the *entitlement*.
    fileprivate var licenseUrl: URL? {
        guard let urlString = entitlement.formats?.first?.fairplay.first?.licenseServerUrl else { return nil }
        return URL(string: urlString)
    }
}
