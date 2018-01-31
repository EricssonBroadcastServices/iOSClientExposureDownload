//
//  ExposureDownloadTask+HeartbeatsProvider.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2017-11-08.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Download
import Exposure

extension ExposureDownloadTask: HeartbeatsProvider {
    public func requestHeatbeat() -> AnalyticsEvent {
        return Playback.Heartbeat(timestamp: Date().millisecondsSince1970)
    }
}
