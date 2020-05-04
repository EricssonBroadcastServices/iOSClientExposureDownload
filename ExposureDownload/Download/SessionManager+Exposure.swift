//
//  SessionManager+Exposure.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2017-10-13.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Download
import Exposure

extension Download.SessionManager where T == ExposureDownloadTask {
    /// Create an `ExposureDownloadTask` by requesting a `PlaybackEntitlement` supplied through exposure.
    ///
    /// If the requested content is *FairPlay* protected, the appropriate `DownloadExposureFairplayRequester` will be created. Configuration will be taken from the `PlaybackEntitlement` response.
    ///
    /// A relevant `ExposureAnalytics` object will be created.
    ///
    /// - parameter assetId: A unique identifier for the asset
    /// - parameter sessionToken: Token identifying the active session
    /// - parameter environment: Exposure environment used for the active session
    /// - returns: `ExposureDownloadTask`
    public func download(assetId: String, using sessionToken: SessionToken, in environment: Environment) -> T {
        let provider = ExposureAnalytics(environment: environment, sessionToken: sessionToken)
        return download(assetId: assetId, analyticProvider: provider)
    }
}

extension Download.SessionManager where T == ExposureDownloadTask {
    /// Create an `ExposureDownloadTask` by requesting a `PlaybackEntitlement` supplied through exposure.
    ///
    ///  Entitlement requests will be done by using the `Environment` and `SessionToken` associated with `analyticsProvider`
    ///
    /// If the requested content is *FairPlay* protected, the appropriate `DownloadExposureFairplayRequester` will be created. Configuration will be taken from the `PlaybackEntitlement` response.
    ///
    /// - parameter assetId: A unique identifier for the asset
    /// - parameter analyticsProvider: The specified analytics provider.
    /// - returns: `ExposureDownloadTask`
    public func download(assetId: String, analyticProvider: ExposureDownloadAnalyticsProvider) -> T {
        if let currentTask = delegate[assetId] {
            print("♻️ Retrieved ExposureDownloadTask associated with request for: \(assetId)")
            return currentTask
        }
        else {
            print("✅ Created new ExposureDownloadTask for: \(assetId)")
            return ExposureDownloadTask(assetId: assetId,
                                        sessionManager: self,
                                        analyticsProvider: analyticProvider)
        }
        
    }
}

// MARK: - OfflineMediaAsset
extension Download.SessionManager where T == ExposureDownloadTask {
    public func offline(assetId: String) -> OfflineMediaAsset? {
        return offlineAssets()
            .filter{ $0.assetId == assetId }
            .first
    }
    
    public func offlineAssets() -> [OfflineMediaAsset] {
        guard let localMedia = localMediaRecords else { return [] }
        return localMedia.map{ resolve(mediaRecord: $0) }
    }
    
    public func delete(media: OfflineMediaAsset) {
        remove(localRecordId: media.assetId)
        do {
            try media.fairplayRequester?.deletePersistedContentKey(for: media.assetId)
            if let url = media.urlAsset?.url {
                try FileManager.default.removeItem(at: url)
            }
            print("✅ SessionManager+Exposure. Cleaned up local media",media.assetId,"Destination:",media.urlAsset?.url)
        }
        catch {
            print("🚨 SessionManager+Exposure. Failed to clean local media: ",error.localizedDescription)
        }
    }
    
    public func delete(assetId: String) {
        guard let media = offline(assetId: assetId) else { return }
        delete(media: media)
    }
    
    internal func save(assetId: String, entitlement: PlaybackEntitlement?, url: URL?) {
        do {
            if let currentAsset = offline(assetId: assetId) {
                if currentAsset.urlAsset?.url != nil {
                    print("⚠️ There is another record for an offline asset with id: \(assetId). This data will be overwritten. The location of any downloaded media or content keys will be lost!")
                    print(" x  ",currentAsset.urlAsset?.url)
                    print(" <- ",url)
                }
                else {
                    print("✅ SessionManager+Exposure. Updated \(assetId) with a destination url \(url)")
                }
            }
            
            let record = try LocalMediaRecord(assetId: assetId, entitlement: entitlement, completedAt: url)
            save(localRecord: record)
        }
        catch {
            print("🚨 Unable to bookmark local media record \(assetId): ",error.localizedDescription)
        }
    }
}

// MARK: - LocalMediaRecord
extension Download.SessionManager where T == ExposureDownloadTask {
    fileprivate var localMediaRecords: [LocalMediaRecord]? {
        do {
            let logFile = try logFileURL()
            
            if !FileManager.default.fileExists(atPath: logFile.path) {
                return []
            }
            let data = try Data(contentsOf: logFile)
            
            let localMedia = try JSONDecoder().decode([LocalMediaRecord].self, from: data)
            
            return localMedia
        }
        catch {
            print("localMediaLog failed",error.localizedDescription)
            return nil
        }
    }
    
    fileprivate func resolve(mediaRecord: LocalMediaRecord) -> OfflineMediaAsset {
        var bookmarkDataIsStale = false
        guard let urlBookmark = mediaRecord.urlBookmark else {
            return OfflineMediaAsset(assetId: mediaRecord.assetId, entitlement: mediaRecord.entitlement, url: nil)
        }
        
        do {
            
            let url = try URL(resolvingBookmarkData: urlBookmark, bookmarkDataIsStale: &bookmarkDataIsStale)
            
            /* guard let url = try URL(resolvingBookmarkData: urlBookmark, bookmarkDataIsStale: &bookmarkDataIsStale) else {
                return OfflineMediaAsset(assetId: mediaRecord.assetId, entitlement: mediaRecord.entitlement, url: nil)
                
            } */
            
            guard !bookmarkDataIsStale else {
                return OfflineMediaAsset(assetId: mediaRecord.assetId, entitlement: mediaRecord.entitlement, url: nil)
            }
            
            return OfflineMediaAsset(assetId: mediaRecord.assetId, entitlement: mediaRecord.entitlement, url: url)
        }
        catch {
            return OfflineMediaAsset(assetId: mediaRecord.assetId, entitlement: mediaRecord.entitlement, url: nil)
        }
    }
}

// MARK: Directory
extension Download.SessionManager where T == ExposureDownloadTask {
    fileprivate var localMediaRecordsFile: String {
        return "localMediaRecords"
    }
    
    fileprivate func logFileURL() throws -> URL {
        return try baseDirectory().appendingPathComponent(localMediaRecordsFile)
    }
    
    /// This directory should be reserved for analytics data.
    ///
    /// - returns: `URL` to the base directory
    /// - throws: `FileManager` error
    internal func baseDirectory() throws -> URL {
        return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("emp")
            .appendingPathComponent("exposure")
            .appendingPathComponent("offlineMedia")
    }
}

// MARK: Save / Remove
extension Download.SessionManager where T == ExposureDownloadTask {
    
    /// This method will ensure `LocalMediaLog` has a unique list of downloads with respect to `assetId`
    fileprivate func save(localRecord: LocalMediaRecord) {
        let localMedia = localMediaRecords ?? []
        
        var filteredLog = localMedia.filter{ $0.assetId != localRecord.assetId }
        
        filteredLog.append(localRecord)
        save(mediaLog: filteredLog)
        print("✅ Saved bookmark for local media record \(localRecord.assetId): ")
    }
    
    fileprivate func save(mediaLog: [LocalMediaRecord]) {
        do {
            let logURL = try baseDirectory()
            
            let data = try JSONEncoder().encode(mediaLog)
            try data.persist(as: localMediaRecordsFile, at: logURL)
        }
        catch {
            print("save(mediaLog:) failed",error.localizedDescription)
        }
    }
    
    internal func remove(localRecordId: String) {
        guard let localMedia = localMediaRecords else { return }
        
        /// Update and save new log
        let newLog = localMedia.filter{ $0.assetId != localRecordId }
        save(mediaLog: newLog)
    }
}
