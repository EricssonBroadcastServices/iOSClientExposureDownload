//
//  DownloadResumed.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-11-09.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import iOSClientExposure

extension Playback {
    internal struct DownloadResumed: AnalyticsEvent {
        internal let eventType: String = "Playback.DownloadResumed"
        internal let bufferLimit: Int64 = 3000
        internal let timestamp: Int64
        
        /// *EMP* asset id of the video being downloaded.
        internal let assetId: String
        
        /// The currently downloaded media size
        internal let downloadedSize: Int64?
        
        /// Total size of media download
        internal let mediaSize: Int64?
        
        internal init(timestamp: Int64, assetId: String, downloadedSize: Int64? = nil, mediaSize: Int64? = nil) {
            self.timestamp = timestamp
            self.assetId = assetId
            self.downloadedSize = downloadedSize
            self.mediaSize = mediaSize
        }
    }
}

extension Playback.DownloadResumed {
    internal var jsonPayload: [String : Any] {
        var params: [String: Any] = [
            JSONKeys.eventType.rawValue: eventType,
            JSONKeys.timestamp.rawValue: timestamp,
            JSONKeys.assetId.rawValue: assetId
        ]
        
        if let downloadedSize = downloadedSize {
            params[JSONKeys.downloadedSize.rawValue] = downloadedSize
        }
        
        if let mediaSize = mediaSize {
            params[JSONKeys.mediaSize.rawValue] = mediaSize
        }
        
        return params
    }
    
    internal enum JSONKeys: String {
        case eventType = "EventType"
        case timestamp = "Timestamp"
        case assetId = "AssetId"
        case downloadedSize = "DownloadedSize"
        case mediaSize = "MediaSize"
    }
}
