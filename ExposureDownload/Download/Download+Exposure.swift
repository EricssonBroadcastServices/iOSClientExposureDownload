//
//  Download+Exposure.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2017-09-27.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import AVFoundation
import Download
import Player

extension Player {
    public func offline(entitlement: PlaybackEntitlement, assetId: String, urlAsset: AVURLAsset) {
        let fairplayRequester = ExposureDownloadFairplayRequester(entitlement: entitlement, assetId: assetId)
        
//        stream(urlAsset: urlAsset, using: fairplayRequester, playSessionId: nil)
    }
}

