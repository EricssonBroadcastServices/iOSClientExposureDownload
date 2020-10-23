//
//  LocalMediaRecord.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2017-10-19.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Exposure

internal struct LocalMediaRecord: Codable {
    /// Id for the asset at `bookmarkURL`
    internal let assetId: String
    
    /// Related entitlement
    internal let entitlement: PlayBackEntitlementV2?
    
    /// URL encoded as bookmark data
    internal let urlBookmark: Data?
    
    internal let accountId: String?
    
    internal init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        assetId = try container.decode(String.self, forKey: .assetId)
        entitlement = try container.decodeIfPresent(PlayBackEntitlementV2.self, forKey: .entitlement)
        urlBookmark = try container.decodeIfPresent(Data.self, forKey: .urlBookmark)
        accountId = try container.decodeIfPresent(String.self, forKey: .accountId)
    }
    
    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(assetId, forKey: .assetId)
        try container.encodeIfPresent(entitlement, forKey: .entitlement)
        try container.encodeIfPresent(urlBookmark, forKey: .urlBookmark)
        try container.encodeIfPresent(accountId, forKey: .accountId)
    }
    
    internal init(assetId: String, accountId:String?, entitlement: PlayBackEntitlementV2?, completedAt location: URL?) throws {
        self.assetId = assetId
        self.entitlement = entitlement
        self.urlBookmark = try location?.bookmarkData()
        self.accountId = accountId
    }
    
    internal enum CodingKeys: String, CodingKey {
        case assetId
        case entitlement
        case urlBookmark
        case accountId
    }
}
