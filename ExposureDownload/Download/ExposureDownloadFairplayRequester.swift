//
//  ExposureDownloadFairplayRequester.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2017-10-13.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import AVFoundation
import Download
import Exposure

/// *Exposure* specific implementation of the `OfflineFairplayRequester` protocol.
///
/// This class handles any *Exposure* related `DRM` validation with regards to *Fairplay*. It is designed to be *plug-and-play* and should require no configuration to use.
internal class ExposureDownloadFairplayRequester: NSObject, DownloadFairplayRequester, FairplayRequester {
    
    init(entitlement: PlaybackEntitlement, assetId: String) {
        self.entitlement = entitlement
        self.assetId = assetId
    }
    
    //    4.4.4.5.  EXT-X-SESSION-KEY
    //    The EXT-X-SESSION-KEY tag allows encryption keys from Media Playlists
    //    to be specified in a Master Playlist.  This allows the client to
    //    preload these keys without having to read the Media Playlist(s)
    //    first.
    //    Its format is:
    //    #EXT-X-SESSION-KEY:<attribute-list>
    //    All attributes defined for the EXT-X-KEY tag (Section 4.4.2.4) are
    //    also defined for the EXT-X-SESSION-KEY, except that the value of the
    //    METHOD attribute MUST NOT be NONE.  If an EXT-X-SESSION-KEY is used,
    //    the values of the METHOD, KEYFORMAT and KEYFORMATVERSIONS attributes
    //    MUST match any EXT-X-KEY with the same URI value.
    //    EXT-X-SESSION-KEY tags SHOULD be added if multiple Variant Streams or
    //    Renditions use the same encryption keys and formats.  A EXT-X
    //    -SESSION-KEY tag is not associated with any particular Media
    //    Playlist.
    //    A Master Playlist MUST NOT contain more than one EXT-X-SESSION-KEY
    //    tag with the same METHOD, URI, IV, KEYFORMAT, and KEYFORMATVERSIONS
    //    attribute values.
    //    The EXT-X-SESSION-KEY tag is optional.
    
    internal let assetId: String
    internal let entitlement: PlaybackEntitlement
    internal let resourceLoadingRequestQueue = DispatchQueue(label: "com.emp.exposure.offline.fairplay.requests")
    internal let customScheme = "skd"
    internal let resourceLoadingRequestOptions: [String : AnyObject]? = [AVAssetResourceLoadingRequestStreamingContentKeyRequestRequiresPersistentKey: true as AnyObject]
    
    
    internal func onSuccessfulRetrieval(of ckc: Data, for resourceLoadingRequest: AVAssetResourceLoadingRequest) throws -> Data {
        // Obtain a persistable content key from a context.
        //
        // The data returned from this method may be used to immediately satisfy an
        // AVAssetResourceLoadingDataRequest, as well as any subsequent requests for the same key url.
        //
        // The value of AVAssetResourceLoadingContentInformationRequest.contentType must be set to AVStreamingKeyDeliveryPersistentContentKeyType when responding with data created with this method.
        let persistedCKC = try resourceLoadingRequest.persistentContentKey(fromKeyVendorResponse: ckc, options: nil)
        
        let persistedKeyURL = try contentKeyUrl(for: assetId)
        print("onSuccessfulRetrieval CKC",assetId,persistedKeyURL)
        try persistedCKC.write(to: persistedKeyURL)
        
        return persistedCKC
    }
    
    func shouldContactRemote(for resourceLoadingRequest: AVAssetResourceLoadingRequest) throws -> Bool {
        guard resourceLoadingRequest.contentInformationRequest != nil else {
            throw ExposureDownloadTask.Error.fairplay(reason: .contentInformationRequestMissing)
        }
        
        resourceLoadingRequest.contentInformationRequest?.contentType = AVStreamingKeyDeliveryPersistentContentKeyType
        
        guard let dataRequest = resourceLoadingRequest.dataRequest else {
            throw ExposureDownloadTask.Error.fairplay(reason: .missingDataRequest)
        }
        
        // Check if we can handle the request with a previously persisted content key
        if let keyData = try persistedContentKey(for: assetId) {
            dataRequest.respond(with: keyData)
            resourceLoadingRequest.finishLoading()
            return false
        }
        return true
    }
}

// FIX ALL THIS PERSISTING + LOADING PERSISTED KEYS.
// FIX Offline vs Download Fairplay requester
extension ExposureDownloadFairplayRequester {
    public func persistedContentKeyExists(for assetId: String) throws -> Bool {
        let url = try contentKeyUrl(for: assetId)
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    public func deletePersistedContentKey(for assetId: String) throws {
        let url = try contentKeyUrl(for: assetId)
        print("Persisted CKC",assetId,url)
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("Persisted CKC? : NO")
            return
        }
        try FileManager.default.removeItem(at: url)
    }
    
    internal func persistedContentKey(for assetId: String) throws -> Data? {
        let url = try contentKeyUrl(for: assetId)
        print("Persisted CKC",assetId,url)
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("Persisted CKC? : NO")
            return nil
        }
        print("Persisted CKC? : YES")
        return try Data(contentsOf: url)
    }
    
    
}
extension ExposureDownloadFairplayRequester {
    internal func contentKeyDirectory() throws -> URL {
        return try FileManager
            .default
            .url(for: .documentDirectory,
                 in: .userDomainMask,
                 appropriateFor: nil,
                 create: true)
            .appendingPathComponent("emp")
            .appendingPathComponent("exposure")
            .appendingPathComponent("offlineMedia")
            .appendingPathComponent("keys", isDirectory: true)
    }
    
    internal func contentKeyUrl(for assetId: String) throws -> URL {
        return try contentKeyDirectory().appendingPathComponent("\(assetId)-key")
    }
}

// MARK: - AVAssetResourceLoaderDelegate
extension ExposureDownloadFairplayRequester {
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        return canHandle(resourceLoadingRequest: loadingRequest)
    }
    
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest) -> Bool {
        return canHandle(resourceLoadingRequest: renewalRequest)
    }
}
