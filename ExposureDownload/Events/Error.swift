//
//  Error.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-07-17.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import iOSClientExposure

extension Playback {
    /// Playback stopped because of an error.
    internal struct Error: AnalyticsEvent {
        internal let eventType: String = "Playback.Error"
        internal let bufferLimit: Int64 = 3000
        internal let timestamp: Int64
        
        /// Human readable error message
        /// Example: "Unable to parse HLS manifest"
        internal let message: String
        
        /// Error Domain
        internal let domain: String
        
        /// Platform-dependent error code
        internal let code: Int
        
        /// Additional detailed error information
        internal let info: String?
        
        internal init(timestamp: Int64, message: String, code: Int, domain: String, info: String? = nil) {
            self.timestamp = timestamp
            self.message = message
            self.code = code
            self.domain = domain
            self.info = info
        }
    }
}

extension Playback.Error {
    internal var jsonPayload: [String : Any] {
        var json: [String: Any] = [
            JSONKeys.eventType.rawValue: eventType,
            JSONKeys.timestamp.rawValue: timestamp,
            JSONKeys.message.rawValue: message,
            JSONKeys.code.rawValue: code,
            JSONKeys.domain.rawValue: domain
        ]
        
        if let info = info {
            json[JSONKeys.info.rawValue] = info
        }
        return json
    }
    
    internal enum JSONKeys: String {
        case eventType = "EventType"
        case timestamp = "Timestamp"
        case message = "Message"
        case code = "Code"
        case domain = "Domain"
        case info = "Info"
    }
}

