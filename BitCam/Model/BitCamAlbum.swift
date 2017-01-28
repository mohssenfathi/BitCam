//
//  LumenAlbum.swift
//  LumenCamera
//
//  Created by Mohssen Fathi on 6/26/16.
//  Copyright © 2016 mohssenfathi. All rights reserved.
//

import UIKit
import Photos

class BitCamAlbum {
    
    static let albumName = "BitCam"
    static let sharedInstance = BitCamAlbum()
    
    var assetCollection: PHAssetCollection?
    
    init() {
        loadLumenAlbum(completion: nil)
    }
    
    func loadLumenAlbum(completion: ((_ album: PHAssetCollection?) -> ())?) {
        
        func fetchAssetCollectionForAlbum() -> PHAssetCollection? {
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "title = %@", BitCamAlbum.albumName)
            let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
            
            if let _: AnyObject = collections.firstObject {
                return collections.firstObject! as PHAssetCollection
            }
            
            return nil
        }
        
        self.assetCollection = fetchAssetCollectionForAlbum()
        if self.assetCollection != nil {
            completion?(self.assetCollection)
            return
        }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: BitCamAlbum.albumName)
        }) { success, _ in
            if success {
                self.assetCollection = fetchAssetCollectionForAlbum()
                completion?(self.assetCollection)
            }
            else {
                print("Error creating Lumen album")
            }
        }
        
    }
    
    func savePhoto(_ photo: UIImage) {
        
        if assetCollection == nil {
            return   // If there was an error upstream, skip the save.
        }
        
        PHPhotoLibrary.shared().performChanges({
            let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: photo)
            let assetPlaceholder = assetChangeRequest.placeholderForCreatedAsset
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: self.assetCollection!)
            albumChangeRequest?.addAssets([assetPlaceholder!] as NSFastEnumeration)
            }, completionHandler: nil)
    }
    
    
}