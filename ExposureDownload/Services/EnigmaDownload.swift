//
//  EnigmaDownload.swift
//  ExposureDownload
//
//  Created by Udaya Sri Senarathne on 2020-07-22.
//  Copyright © 2020 emp. All rights reserved.
//

import Foundation
import Exposure
import Download


/// Enigma Download
class EnigmaDownload {
    
    static var shared = EnigmaDownload()
    private init(){}
    let manager = Download.SessionManager<ExposureDownloadTask>()
}


/// EnigmaDownloadManager defines the Asset Downloads
/// When implement this , developers will be able to access all the download features provided by the SDK
public protocol EnigmaDownloadManager {
    
}

extension EnigmaDownloadManager {
    public var enigmaDownloadManager: Download.SessionManager<ExposureDownloadTask> {
        return EnigmaDownload.shared.manager
    }
}
