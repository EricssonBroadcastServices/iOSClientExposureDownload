//
//  SessionManager+Exposure.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2017-10-13.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import iOSClientDownload
import iOSClientExposure

extension iOSClientDownload.SessionManager where T == ExposureDownloadTask {
    
    /* /// Create an `ExposureDownloadTask` by requesting a `PlaybackEntitlementV2` supplied through exposure.
     ///
     /// If the requested content is *FairPlay* protected, the appropriate `DownloadExposureFairplayRequester` will be created. Configuration will be taken from the `PlaybackEntitlementV2` response.
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
     */
    public func download(assetId: String, using sessionToken: SessionToken, in environment: Environment) -> T {
        return download(assetId: assetId, sessionToken: sessionToken, environment: environment)
    }
    
}

extension iOSClientDownload.SessionManager where T == ExposureDownloadTask {
    
    
    /*
     Remove passing analyticsProvider temporary
     
     /// Create an `ExposureDownloadTask` by requesting a `PlaybackEntitlementV2` supplied through exposure.
     ///
     ///  Entitlement requests will be done by using the `Environment` and `SessionToken` associated with `analyticsProvider`
     ///
     /// If the requested content is *FairPlay* protected, the appropriate `DownloadExposureFairplayRequester` will be created. Configuration will be taken from the `PlaybackEntitlementV2` response.
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
     */
    
    
    /// Create an `ExposureDownloadTask` by requesting a `PlaybackEntitlementV2` supplied through exposure.
    ///
    ///  Entitlement requests will be done by using the `Environment` and `SessionToken` associated with `analyticsProvider`
    ///
    /// If the requested content is *FairPlay* protected, the appropriate `DownloadExposureFairplayRequester` will be created. Configuration will be taken from the `PlaybackEntitlementV2` response.
    ///
    /// - Parameters:
    ///   - assetId: assetId: A unique identifier for the asset
    ///   - sessionToken: user session token
    ///   - environment: customer enviornment
    /// - Returns: ExposureDownloadTask
    public func download(assetId: String, sessionToken: SessionToken, environment: Environment ) -> T {
        if let currentTask = delegate[assetId] {
            print("♻️ Retrieved ExposureDownloadTask associated with request for: \(assetId)")
            return currentTask
        }
        else {
            print("✅ Created new ExposureDownloadTask for: \(assetId)")
            return ExposureDownloadTask(assetId: assetId,
                                        sessionManager: self,
                                        sessionToken: sessionToken,
                                        environment: environment)
        }
        
    }
    
}

// MARK: - OfflineMediaAsset
extension iOSClientDownload.SessionManager where T == ExposureDownloadTask {
    public func getDownloadedAsset(assetId: String) -> OfflineMediaAsset? {
        return getDownloadedAssets()
            .filter{ $0.assetId == assetId }
            .first
    }

    
    public func getDownloadedAssets() -> [OfflineMediaAsset] {
        guard let localMedia = localMediaRecords else { return [] }
        return localMedia.map{ resolve(mediaRecord: $0) }
    }
    
    
    /// Get downloaded Assets by `accountId`
    /// - Parameter accountId: accountId
    /// - Returns: array of OfflineMediaAsset
    public func getDownloadedAssets(accountId:String?) -> [OfflineMediaAsset] {
        guard let localMedia = localMediaRecords else { return [] }
        
        guard let accountId = accountId else {
            return []
        }
        
        let allLocalMdeia = localMedia.map{ resolve(mediaRecord: $0) }
        return allLocalMdeia.filter(){ $0.accountId == accountId }
    }
    
    
    
    /// Shoud renew licenes for a given asset
    /// - Parameters:
    ///   - assetId: asset Id
    ///   - sessionToken: session token
    ///   - environment: environment
    ///   - completion: completion
    public func renewLicense(assetId: String, sessionToken: SessionToken, environment: Environment, completion: @escaping (OfflineMediaAsset?, Error?) -> Void) {
        
            guard let media = getDownloadedAsset(assetId: assetId) else {
                print("❌ Could not find local media for renewal: assetId \(assetId)")
                let error = ExposureDownloadTask.Error.fairplay(reason: .missingApplicationCertificateUrl)
                completion(nil, error)
                return
            }
            
            self.validateEntitlementRequest(environment: environment, sessionToken: sessionToken, assetId: assetId) {  [weak self] newEntitlement, error in
                
                if let error = error {
                    print("❌ Entitlement granted failed for assetId: \(assetId) , Error \(error)")
                    completion(nil, error )
                } else {
                    print("✅ New entitlement was granted for assetId : \(assetId)")
                    do {
                        if let localRecord = self?.getLocalMediaRecordFor(assetId: assetId) {
                            var updatedLocalRecord = localRecord
                            updatedLocalRecord.entitlement = newEntitlement
                            self?.save(localRecord: updatedLocalRecord)
      
                            let offlineAsset = OfflineMediaAsset(assetId: assetId, accountId: sessionToken.accountId, userId: sessionToken.userId, entitlement: newEntitlement, url: try media.fairplayRequester?.contentKeyUrl(for: assetId), downloadState: .completed, format: media.format)
                            completion(offlineAsset, nil )
                        }
                    } catch {
                        print("❌ Updating local record with new entitlement was failed for assetId : \(assetId) , Error \(error)")
                        completion(nil, error)
                    }
                }
            }
    }
    
    
    fileprivate func validateEntitlementRequest(environment:Environment,sessionToken:SessionToken, assetId: String, completionHandler: @escaping (PlayBackEntitlementV2?, ExposureError?) -> Void) {
        
        let _ = Entitlement(environment:environment,
                                         sessionToken: sessionToken)
            .validate(downloadId: assetId)
            .request()
            .validate()
            .response {
                guard let entitlement = $0.value else {
                    
                    // self.eventPublishTransmitter.onError(self, nil, $0.error!)
                    
                    completionHandler(nil, $0.error)
                    return
                }
                completionHandler(entitlement, nil )
        }
    }
    
    /// Get downloaded Assets by `userId`
    /// - Parameter userId: userId
    /// - Returns: array of OfflineMediaAsset
    public func getDownloadedAssets(userId:String?) -> [OfflineMediaAsset] {
        guard let localMedia = localMediaRecords else { return [] }
        
        guard let userId = userId else {
            return []
        }
        
        let allLocalMdeia = localMedia.map{ resolve(mediaRecord: $0) }
        return allLocalMdeia.filter(){ $0.userId == userId }
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
    
    
    /// Delete a downloaded asset
    /// - Parameter assetId: assetId
    public func removeDownloadedAsset(assetId: String, sessionToken: SessionToken, environment: Environment) {
        guard let media = getDownloadedAsset(assetId: assetId) else { return }
        delete(media: media)
    }
    
    internal func save(assetId: String, accountId:String?, userId:String?, entitlement: PlayBackEntitlementV2?, url: URL?, downloadState: DownloadState) {
        do {
            if let currentAsset = getDownloadedAsset(assetId: assetId) {
                
                if currentAsset.urlAsset?.url != nil {
                    print("⚠️ There is another record for an offline asset with id: \(assetId). This data will be overwritten. The location of any downloaded media or content keys will be lost!")
                    print(" x  ",currentAsset.urlAsset?.url)
                    print(" <- ",url)
                }
                else {
                    print("✅ SessionManager+Exposure. Updated \(assetId) with a destination url \(url)")
                }
            }
            
            let record = try LocalMediaRecord(assetId: assetId, accountId: accountId, userId: userId, entitlement: entitlement, completedAt: url, downloadState: downloadState, format: entitlement?.formats?.first?.format ?? "HLS")
            
            save(localRecord: record)
        }
        catch {
            print("🚨 Unable to bookmark local media record \(assetId): ",error.localizedDescription)
        }
    }
}

// MARK: - LocalMediaRecord
extension iOSClientDownload.SessionManager where T == ExposureDownloadTask {
    
    /// Get local media record for a given `assetId`
    func getLocalMediaRecordFor(assetId: String) -> LocalMediaRecord? {
        do {
            let logFile = try logFileURL()
            let logData = try Data(contentsOf: logFile)
            print("Reading...  📖: \(logFile.description)")
            let localMedia = try JSONDecoder().decode([LocalMediaRecord].self, from: logData)
            let filteredLog = localMedia.filter{ $0.assetId == assetId }.first
            return filteredLog
        } catch {
            print("🚨 Error fetching local media : \(error)")
            return nil
        }
        
    }
    
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
            return OfflineMediaAsset(assetId: mediaRecord.assetId, accountId: mediaRecord.accountId, userId: mediaRecord.userId, entitlement: mediaRecord.entitlement, url: nil, downloadState: mediaRecord.downloadState, format: mediaRecord.format)
        }
        
        do {
            
            let url = try URL(resolvingBookmarkData: urlBookmark, bookmarkDataIsStale: &bookmarkDataIsStale)
            
            /* guard let url = try URL(resolvingBookmarkData: urlBookmark, bookmarkDataIsStale: &bookmarkDataIsStale) else {
             return OfflineMediaAsset(assetId: mediaRecord.assetId, entitlement: mediaRecord.entitlement, url: nil)
             
             } */
            
            guard !bookmarkDataIsStale else {
                return OfflineMediaAsset(assetId: mediaRecord.assetId, accountId: mediaRecord.accountId, userId: mediaRecord.userId, entitlement: mediaRecord.entitlement, url: nil, downloadState: mediaRecord.downloadState, format: mediaRecord.format)
            }
            
            return OfflineMediaAsset(assetId: mediaRecord.assetId, accountId: mediaRecord.accountId, userId: mediaRecord.userId, entitlement: mediaRecord.entitlement, url: url, downloadState: mediaRecord.downloadState, format: mediaRecord.format)
        }
        catch {
            return OfflineMediaAsset(assetId: mediaRecord.assetId, accountId: mediaRecord.accountId, userId: mediaRecord.userId, entitlement: mediaRecord.entitlement, url: nil, downloadState: mediaRecord.downloadState, format: mediaRecord.format)
        }
    }
}

// MARK: Directory
extension iOSClientDownload.SessionManager where T == ExposureDownloadTask {
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
extension iOSClientDownload.SessionManager where T == ExposureDownloadTask {
    
    /// This method will update `LocalMediaLog` with given updated `localRecord`
    fileprivate func update(localRecord: LocalMediaRecord) {
        var localMedia = localMediaRecords ?? []
        let filteredLog = localMedia.filter{ $0.assetId == localRecord.assetId }.first
        localMedia.removeAll(where: {$0.assetId == filteredLog?.assetId })
        localMedia.append(localRecord)
  
        save(mediaLog: localMedia)
        print("✅ Update bookmark for local media record \(localRecord.assetId): ")
    }
    
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



// MARK: - Download Info
extension iOSClientDownload.SessionManager where T == ExposureDownloadTask {
    
    
    /// Returns if an asset is available to download or not
    /// - Parameters:
    ///   - assetId: assetId
    ///   - environment: enviornment
    ///   - sessionToken: sessionToken
    ///   - completionHandler: completion
    public func isAvailableToDownload( assetId: String, environment: Environment, sessionToken: SessionToken, _ completionHandler: @escaping (Bool) -> Void) {
        
        self.getDownloadableInfo(assetId: assetId, environment: environment, sessionToken: sessionToken) { [weak self] info in
            completionHandler( info != nil ? true : false )
        }
    }
    
    /// Get downloadable info of an Asset
    /// - Parameters:
    ///   - assetId: assetId
    ///   - environment: Exposure Enviornment
    ///   - sessionToken: user sessionToken
    ///   - completionHandler: completion
    public func getDownloadableInfo(assetId: String, environment: Environment, sessionToken: SessionToken, _ completionHandler: @escaping (DownloadInfo?) -> Void) {
        GetDownloadableInfo(assetId: assetId, environment: environment, sessionToken: sessionToken)
            .request()
            .validate()
            .response { info in
                
                if let downloadInfo = info.value {
                    completionHandler(downloadInfo)
                    
                } else {
                    completionHandler(nil)
                }
        }
    }
    
    
    /// Check if the license has expired or not
    /// - Parameter assetId: asset id
    /// - Returns: true if the license has expired
    public func isExpired(assetId: String)-> Bool {
        let downloadedAsset = getDownloadedAsset(assetId: assetId)
        guard let playTokenExpiration = downloadedAsset?.entitlement?.playTokenExpiration else {
            return true
        }

        let today = Date().millisecondsSince1970
        
        return playTokenExpiration * 1000 >= today ? false : true
    }
    
    
    /// get the license expiration time
    /// - Parameter assetId: asset id
    /// - Returns: playTokenExpiration
    public func getExpiryTime(assetId: String)->Int? {
        let downloadedAsset = getDownloadedAsset(assetId: assetId)
        return downloadedAsset?.entitlement?.playTokenExpiration
    }
}
