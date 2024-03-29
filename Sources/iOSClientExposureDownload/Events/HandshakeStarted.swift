//
//  HandshakeStarted.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-07-17.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import iOSClientExposure

extension Playback {
    /// If the player was created but not supposed to automatically play the asset as soon as possible, the HandshakeStarted event indicates that the player is preparing for playback now.
    internal struct HandshakeStarted: AnalyticsEvent {
        internal let eventType: String = "Playback.HandshakeStarted"
        internal let bufferLimit: Int64 = 3000
        internal let timestamp: Int64
        
        internal let assetId: String?
        
        /// Identity of the media the player should play. This should be the media locator as received from the call to the entitlement service. This is a string of proprietary format that corresponds to the MRR Media ID if applicable, but can contain implementation specific strings for other streaming formats. If this is not known at this time, it can be omitted.
        /// Example: 1458209835_fai-hls_IkCMxd
        internal let mediaId: String?
        
        internal init(timestamp: Int64, assetId: String? = nil, mediaId: String? = nil) {
            self.timestamp = timestamp
            self.assetId = assetId
            self.mediaId = mediaId
        }
    }
}

extension Playback.HandshakeStarted {
    internal var jsonPayload: [String : Any] {
        var params: [String: Any] = [
            JSONKeys.eventType.rawValue: eventType,
            JSONKeys.timestamp.rawValue: timestamp
        ]
        
        if let assetId = assetId {
            params[JSONKeys.assetId.rawValue] = assetId
        }
        
        if let mediaId = mediaId {
            params[JSONKeys.mediaId.rawValue] = mediaId
        }
        
        return params
    }
    
    internal enum JSONKeys: String {
        case eventType = "EventType"
        case timestamp = "Timestamp"
        case assetId = "AssetId"
        case mediaId = "MediaId"
    }
}
