//
//  OfflineMediaAsset.swift
//  iOSReferenceApp
//
//  Created by Fredrik Sjöberg on 2017-10-06.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import AVFoundation
import iOSClientExposure

public struct OfflineMediaAsset {
    internal init(assetId: String, accountId:String?, entitlement: PlayBackEntitlementV2?, url: URL?, downloadState: DownloadState) {
        self.assetId = assetId
        self.entitlement = entitlement
        self.accountId = accountId
        self.downloadState = downloadState
        
        if let entitlement = entitlement {
            self.fairplayRequester = ExposureDownloadFairplayRequester(entitlement: entitlement, assetId: assetId)
        }
        else {
            self.fairplayRequester = nil
        }
        
        if let url = url {
            self.urlAsset = AVURLAsset(url: url)
        }
        else {
            self.urlAsset = nil
        }
    }
    
    /// Identifier for this `OfflineMediaAsset`
    public let assetId: String
    
    /// `PlaybackEntitlementV2` associated with this media
    public let entitlement: PlayBackEntitlementV2?
    
    /// `AVURLAsset` used to initiate playback.
    public let urlAsset: AVURLAsset?
    internal let fairplayRequester: ExposureDownloadFairplayRequester?
    
    public let accountId:String?
    
    
    /// Define download state 
    public let downloadState: DownloadState
 
    /// Retrieves the `State` of the related media *asynchronously*.
    ///
    /// An asset is only `.playable` if it has an associated `PlaybackEntitlementV2` and a valid `url` to the locally stored media files. If either of these criteria are not met, the asset is `.notPlayable`. Not playable assets should be considered damaged and candidates for removal.
    public func state(callback: @escaping (State) -> Void) {
        guard let entitlement = entitlement else {
            callback(.notPlayable(entitlement: self.entitlement, url: self.urlAsset?.url))
            return
        }
        
        guard let urlAsset = urlAsset else {
            callback(.notPlayable(entitlement: entitlement, url: self.urlAsset?.url))
            return
        }
        
        
        if #available(iOS 10.0, *) {
            if let assetCache = urlAsset.assetCache, assetCache.isPlayableOffline {
                callback(.completed(entitlement: entitlement, url: urlAsset.url))
                return
            }
        }
        
        urlAsset.loadValuesAsynchronously(forKeys: ["playable"]) { [entitlement, urlAsset] in
            DispatchQueue.main.async {
                
                // Check for any issues preparing the loaded values
                var error: NSError?
                if urlAsset.statusOfValue(forKey: "playable", error: &error) == .loaded {
                    if urlAsset.isPlayable {
                        callback(.completed(entitlement: entitlement, url: urlAsset.url))
                    }
                    else {
                        callback(.notPlayable(entitlement: entitlement, url: urlAsset.url))
                    }
                }
                else {
                    callback(.notPlayable(entitlement: entitlement, url: urlAsset.url))
                }
            }
        }
    }
    
    /// The state of the `OfflineMediaAsset`
    public enum State {
        /// An asset is only `.playable` if it has an associated `PlaybackEntitlementV2` and a valid `url` to the locally stored media files
        ///
        /// - parameter entitlement: Entitlement granted when the download request was made
        /// - parameter url: on device path to the locally stored media
        case completed(entitlement: PlayBackEntitlementV2, url: URL)
        
        /// A not playable asset should be considered damaged and a candidate for removal.
        ///
        /// - parameter entitlement: Entitlement granted when the download request was made. If this is nil, it is likely in part the cause for this asset not being playable
        /// - parameter url: on device path to the locally stored media. If this is nil, it is likely in part the cause for this asset not being playable
        case notPlayable(entitlement: PlayBackEntitlementV2?, url: URL?)
    }
}

extension Data {
    /// Convenience function for persisting a `Data` blob through `FileManager`.
    ///
    /// - parameter filename: Name of the file, including extension
    /// - parameter directoryUrl: `URL` to the storage directory
    /// - throws: `FileManager` related `Error` or `Data` related error in the *Cocoa Domain*
    internal func persist(as filename: String, at directoryUrl: URL) throws {
        if !FileManager.default.fileExists(atPath: directoryUrl.path) {
            try FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: true, attributes: nil)
        }
        
        try self.write(to: directoryUrl.appendingPathComponent(filename))
    }
}
