//
//  LocalMediaRecord.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2017-10-19.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import iOSClientExposure


/// Downlload state of the downloaded media
public enum DownloadState: String, Codable {
    
    /// Download has started
    case started
    
    /// Download in progress.
    case downloading
    
    /// Download was suspended
    case suspend
    
    /// Downloading was canceled
    case cancel
    
    /// Download was completed
    case completed
    
    /// Media has not downloaded
    case notDownloaded
}

internal struct LocalMediaRecord: Codable {
    /// Id for the asset at `bookmarkURL`
    internal let assetId: String
    
    /// Related entitlement
    internal var entitlement: PlayBackEntitlementV2?
    
    /// URL encoded as bookmark data
    internal let urlBookmark: Data?
    
    internal let accountId: String?
    
    internal let userId: String?
    
    internal let downloadState: DownloadState
    
    internal let format: String?
    
    internal init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        assetId = try container.decode(String.self, forKey: .assetId)
        entitlement = try container.decodeIfPresent(PlayBackEntitlementV2.self, forKey: .entitlement)
        urlBookmark = try container.decodeIfPresent(Data.self, forKey: .urlBookmark)
        accountId = try container.decodeIfPresent(String.self, forKey: .accountId)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        downloadState = try container.decode(DownloadState.self, forKey: .downloadState)
        format = try container.decodeIfPresent(String.self, forKey: .format)
    }
    
    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(assetId, forKey: .assetId)
        try container.encodeIfPresent(entitlement, forKey: .entitlement)
        try container.encodeIfPresent(urlBookmark, forKey: .urlBookmark)
        try container.encodeIfPresent(accountId, forKey: .accountId)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(downloadState, forKey: .downloadState)
        try container.encodeIfPresent(format, forKey: .format)
    }
    
    internal init(assetId: String, accountId:String?, userId: String?, entitlement: PlayBackEntitlementV2?, completedAt location: URL?, downloadState: DownloadState, format: String?) throws {

        self.assetId = assetId
        self.entitlement = entitlement
        self.urlBookmark = try location?.bookmarkData()
        self.accountId = accountId
        self.userId = userId
        self.downloadState = downloadState
        self.format = format
    }
    
    internal enum CodingKeys: String, CodingKey {
        case assetId
        case entitlement
        case urlBookmark
        case accountId
        case userId
        case downloadState
        case format
    }
}
