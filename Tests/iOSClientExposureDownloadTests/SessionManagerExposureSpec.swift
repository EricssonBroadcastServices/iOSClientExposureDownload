//
//  SessionManager+ExposureSpec.swift
//  ExposureDownloadTests
//
//  Created by Udaya Sri Senarathne on 2020-08-20.
//  Copyright © 2020 emp. All rights reserved.
//
import Quick
import Nimble
import iOSClientExposure
import iOSClientDownload
import Foundation

@testable import iOSClientExposureDownload

class SessionManagerExposureSpec: QuickSpec, EnigmaDownloadManager {

    override func spec() {
        super.spec()
        
        let formats: [String: Any] = [
            "format": "HLS",
            "drm" : [
                "com.apple.fps" : [
                    "licenseServerUrl" : "licenseServerUrl",
                    "certificateUrl" : "certificateUrl"
                ]
            ],
            "mediaLocator": "https://cache-dev.sample.mpd?t=2019-04-15T12%3A00%3A00.000"
        ]
  
        let json:[String: Any] = [
            "assetId": "assetId",
            "accountId": "accountId",
            "requestId": "requestId",
            "formats":[formats],
            "playSessionId": "33f4sfdfdwrtgdgdfgh",
            "playToken": "eyJ0eXAisdfsd545dftdftgdfgdfgdfgdfgdfgdfgdgf",
            "playTokenExpiration": 1587474753,
            "playTokenExpirationReason": "MAX_TIME_AFTER_DOWNLOAD",
            "productId": "test_productId",
            "publicationId": "test_publicationId",
            "durationInMs": 124000,
            "materialId": "test_materialId",
            "materialVersion": 1
        ]
        
        
        let entitlement = json.decode(PlayBackEntitlementV2.self)
        
        let manager = iOSClientDownload.SessionManager<ExposureDownloadTask>()
    
        
        let downloadedAsset = OfflineMediaAsset(assetId: "assetId", accountId: "accountId", userId: "userId",  entitlement: entitlement, url: URL(string: "fileURL"), downloadState: .completed, format: "", sessionManager: manager)
    
            
         describe("OfflineMedia Assets") {
            
            it("Should decode properly") {
                let entitlement = json.decode(PlayBackEntitlementV2.self)
                expect(entitlement).toNot(beNil())
            }
                
                
            it("should provide an offlineMedia Asset") {
                expect(downloadedAsset).toNot(beNil())
            }
            
            it("should have entitelements") {
                expect(downloadedAsset.entitlement).toNot(beNil())
            }
            
            it("should have a url") {
                expect(downloadedAsset.urlAsset).toNot(beNil())
            }
        }
    }
}


extension Dictionary where Key == String, Value == Any {
    func decode<T>(_ type: T.Type) -> T? where T : Decodable {
        guard let data = try? JSONSerialization.data(withJSONObject: self, options: .prettyPrinted) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
