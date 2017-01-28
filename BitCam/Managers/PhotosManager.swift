//
//  PhotosManager.swift
//  Lumen
//
//  Created by Mohssen Fathi on 4/23/16.
//  Copyright © 2016 mohssenfathi. All rights reserved.
//

import UIKit
import Photos

class PhotosManager: NSObject {

    static let sharedManager = PhotosManager()
    var requestIds = [PHImageRequestID]()
  
    
//  MARK: - Saving
    func saveToBitCamAlbum(_ photo: UIImage) {
        BitCamAlbum.sharedInstance.savePhoto(photo)
    }
    
    
//  MARK: - Fetch
    
    func lumenAssets(completion: @escaping (_ assets: [PHAsset]) -> ()) {
    
        BitCamAlbum.sharedInstance.loadLumenAlbum { (collection) in
            if collection == nil {
                completion([])
                return
            }
            completion(self.assets(collection!))
        }
    
    }
    
    var collections: [PHAssetCollection] {
        get {
            var allCollections = [PHAssetCollection]()
            
            let options = PHFetchOptions()
            var type = PHAssetCollectionType.smartAlbum
            var subtype = PHAssetCollectionSubtype.smartAlbumUserLibrary
            var fetchResult: PHFetchResult<PHAssetCollection> = PHAssetCollection.fetchAssetCollections(with: type, subtype: subtype, options: options)
            
            for i in 0 ..< fetchResult.count {
                allCollections.append(fetchResult.object(at: i))
            }
            
            options.predicate = NSPredicate(format: "estimatedAssetCount > %d", 0)
            type = PHAssetCollectionType.album
            subtype = PHAssetCollectionSubtype.any
            fetchResult = PHAssetCollection.fetchAssetCollections(with: type, subtype: subtype, options: options)
            fetchResult.enumerateObjects({ (collection, index, stop) in
                if self.shouldIncludeCollection(collection) {
                    allCollections.append(collection)
                }
            })
            
            return allCollections
        }
    }
    
    func shouldIncludeCollection(_ collection: PHAssetCollection) -> Bool {
        if collection.localizedTitle == "slo-mo" { return false }
        if collection.localizedTitle == "videos" { return false }
        if collection.localizedTitle == "recently deleted" { return false }
        
        let listResult = PHCollectionList.fetchCollectionListsContaining(collection, options: nil)
        
        if listResult.count == 0 { return true }
        let collectionList = listResult.firstObject! as PHCollectionList
        if collectionList.localizedTitle?.lowercased() == "iphoto events" {
            return false
        }
    
        return true
    }
    
    
    func assets(_ collection: PHAssetCollection) -> [PHAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let fetchResult = PHAsset.fetchAssets(in: collection, options: options)
        
        var allObjects = [PHAsset]()
        for i in 0 ..< fetchResult.count {
            allObjects.append(fetchResult.object(at: i))
        }
        
        return allObjects
    }
    
    var allAssets: [PHAsset] {
        get {
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let fetchResult = PHAsset.fetchAssets(with: .image, options: nil)
            
            var allObjects = [PHAsset]()
            for i in 0 ..< fetchResult.count {
                allObjects.append(fetchResult.object(at: i))
            }
            
            return allObjects
        }
    }
    
    lazy var allAssetsCollection: PHAssetCollection? = {
        for collection in self.collections {
            if collection.localizedTitle?.lowercased() == "all photos" { // Will this work in other countries?
                return collection
            }
        }
        return nil
    }()
    
    
//   MARK: - Images
    func imageForAsset(_ asset: PHAsset, size:CGSize,
                       progress: PHAssetImageProgressHandler?,
                       completion:@escaping (_ resultImage: UIImage?) -> Void) {
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        options.progressHandler = progress
        
        let requestId = PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { (resultImage, _) in
            DispatchQueue.main.async(execute: {
                completion(resultImage)
            })
        }
        
        requestIds.append(requestId)
    }
    
    func cancelAllRequests() {
        for requestId in requestIds {
            PHImageManager.default().cancelImageRequest(requestId)
        }
    }
    
    func imageForCollection(_ collection: PHAssetCollection, size:CGSize, completion:@escaping (_ resultImage: UIImage?) -> Void) {
        guard let asset = assets(collection).last else {
            completion(nil)
            return
        }
    
        self.imageForAsset(asset, size: size, progress: nil) { (resultImage) in
            completion(resultImage)
        }
    }

}
//
//extension PHFetchResult where ObjectType is PHAsset {
//    func allObjects() -> [PHAsset] {
//        let range = NSRange(location: 0, length: self.count)
//        let objects = self.objects(at: IndexSet(integersIn: range.toRange() ?? 0..<0))
//        return objects
//    }
//}
