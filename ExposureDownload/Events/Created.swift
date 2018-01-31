//
//  Created.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-07-16.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Exposure

extension Playback {
    /// This event is sent when the player is instantiated, or invoked for the first time during the playback session. 
    internal struct Created: AnalyticsEvent {
        internal let eventType: String = "Playback.Created"
        internal let bufferLimit: Int64 = 3000
        internal let timestamp: Int64
        
        /// Id string of the player/sdk.
        /// Example: EMP.tvOS2, EMP.iOS2
        internal var player: String {
            return "EMP.iOS2"
        }
        
        /// Release version and build revision of the player
        /// Example: 1.34.0
        internal let version: String
        
        /// Additional optional version information. For instance, the embedded player
        /// Example: AMC 2.9.1.42740
        internal let revision: String?
        
        /// If true, the player will start playing as soon as possible. If false, player does not start playing, and will be initialized at a later time. If this field is missing, it is assumed to have the value "true".
        internal let autoPlay: Bool?
        
        /// One of the following: vod, live, offline
        internal var playMode: String {
            return "vod"
        }
        
        internal let assetId: String?
        
        /// Identity of the media the player should play. This should be the media locator as received from the call to the entitlement service. This is a string of proprietary format that corresponds to the MRR Media ID if applicable, but can contain implementation specific strings for other streaming formats.
        /// Example: 1458209835_fai-hls_IkCMxd
        internal let mediaId: String?
        
        internal init(timestamp: Int64, version: String, revision: String? = nil, assetId: String? = nil, mediaId: String? = nil, autoPlay: Bool? = nil) {
            self.timestamp = timestamp
            self.version = version
            self.revision = revision
            self.assetId = assetId
            self.mediaId = mediaId
            self.autoPlay = autoPlay
        }
    }
}

extension Playback.Created {
    internal var jsonPayload: [String : Any] {
        var params: [String: Any] = [
            JSONKeys.eventType.rawValue: eventType,
            JSONKeys.timestamp.rawValue: timestamp,
            JSONKeys.player.rawValue: player,
            JSONKeys.version.rawValue: version,
            JSONKeys.playMode.rawValue: playMode
        ]
        
        if let revision = revision {
            params[JSONKeys.revision.rawValue] = revision
        }
        
        if let autoPlay = autoPlay {
            params[JSONKeys.autoPlay.rawValue] = autoPlay
        }
        
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
        case player = "Player"
        case version = "Version"
        case revision = "Revision"
        case autoPlay = "AutoPlay"
        case playMode = "PlayMode"
        case assetId = "AssetId"
        case mediaId = "MediaId"
    }
}
