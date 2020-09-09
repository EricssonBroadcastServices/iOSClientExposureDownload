//
//  Util+FileManager.swift
//  ExposureDownload
//
//  Created by Udaya Sri Senarathne on 2020-08-25.
//  Copyright © 2020 emp. All rights reserved.
//

import Foundation
import Exposure

public protocol ContentKeyManager {
}


// FIX ALL THIS PERSISTING + LOADING PERSISTED KEYS.
// FIX Offline vs Download Fairplay requester
extension ContentKeyManager {
    internal func contentKeyDirectory() throws -> URL {
        let contentKeyDirectory =  try FileManager
            .default
            .url(for: .documentDirectory,
                 in: .userDomainMask,
                 appropriateFor: nil,
                 create: true)
            .appendingPathComponent("emp")
            .appendingPathComponent("exposure")
            .appendingPathComponent("offlineMedia")
            .appendingPathComponent("keys", isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: contentKeyDirectory.path, isDirectory: nil) {
            do {
                try FileManager.default.createDirectory(at: contentKeyDirectory,
                                                    withIntermediateDirectories: false,
                                                    attributes: nil)
            } catch {
                fatalError("Unable to create directory for content keys at path: \(contentKeyDirectory.path)")
            }
        }
        
        return contentKeyDirectory
    }

    func contentKeyUrl(for assetId: String) throws -> URL {
        return try contentKeyDirectory().appendingPathComponent("\(assetId)-key")
    }

    
    func persistedContentKeyExists(for assetId: String) throws -> Bool {
        let url = try contentKeyUrl(for: assetId)
        return FileManager.default.fileExists(atPath: url.path)
    }

    func deletePersistedContentKey(for assetId: String) throws {
        let url = try contentKeyUrl(for: assetId)
        print("Persisted CKC",assetId,url)
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("Persisted CKC? : NO")
            return
        }
        try FileManager.default.removeItem(at: url)
    }

    internal func persistedContentKey(for assetId: String) throws -> Data? {
        let url = try contentKeyUrl(for: assetId)
        print("Persisted CKC",assetId,url)
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("Persisted CKC? : NO")
            return nil
        }
        print("Persisted CKC? : YES")
        return try Data(contentsOf: url)
    }
    
    
    /// The *Application Certificate* is fetched from a server specified by a `certificateUrl` delivered in the *entitlement* obtained through *Exposure*.
    ///
    /// - note: This method uses a specialized function for parsing the retrieved *Application Certificate* from an *MRR specific* format.
    /// - parameter callback: fires when the certificate is fetched or when an `error` occurs.
    ///
    /// - Parameters:
    ///   - certificateUrl: certificateUrl
    ///   - callback: callback
    func fetchApplicationCertificate(certificateUrl: URL, callback: @escaping (Data?, ExposureDownloadTask.Error?) -> Void) {
        
        SessionManager
            .default
            .request(certificateUrl, method: .get)
            .validate()
            .rawResponse{ _,_, data, error in
                
                if let error = error {
                    callback(nil, .fairplay(reason: .networking(error: error)))
                    return
                }
                
                if let success = data {
                    
                    callback(success, nil)
                } else {
                    callback(nil, .fairplay(reason: .applicationCertificateParsing))
                }
        }
    }
    
    
    /// Fetching a *Content Key Context*, `CKC`, requires a valid *Server Playback Context*.
    ///
    /// - note: This method uses a specialized function for parsing the retrieved *Content Key Context* from an *MRR specific* format.
    ///
    /// - Parameters:
    ///   - licenseUrl: licenseUrl
    ///   - playToken: playToken
    ///   - spc: spc data
    ///   - callback: callback
    func fetchContentKeyContext(licenseUrl:URL, playToken:String, spc: Data, callback: @escaping (Data?, ExposureDownloadTask.Error?) -> Void) {

        var headers = ["Content-type": "application/octet-stream"]
        headers["Authorization"] =  "Bearer " + playToken
        
        SessionManager
            .default
            .request(licenseUrl,
                     method: .post,
                     data: spc,
                     headers: headers)
            .validate()
            .rawResponse { _,_, data, error in
                
                
                if let error = error {

                    callback(nil, .fairplay(reason:.networking(error: error)))
                    return
                }
                
                if let success = data {
                    callback(success, nil)
                } else {
                    callback(nil, .fairplay(reason: .contentKeyContextDataFormatInvalid))
                }
        }
    }
    
}


