//
//  MTLCloudKitManager.swift
//  Pods
//
//  Created by Mohssen Fathi on 6/3/16.
//
//

import UIKit
import CloudKit

let publicDatabase = CKContainer.default().publicCloudDatabase

public
class MTLCloudKitManager: NSObject {

    static let sharedManager = MTLCloudKitManager()
    
    func allRecords() -> [CKRecord]? {
        
        return nil
    }
    
    func upload(_ filterGroup: MTLFilterGroup, container: CKContainer, completion: ((_ record: CKRecord?, _ error: Error?) -> ())?) {
        
        let record = filterGroup.ckRecord()
        
        container.publicCloudDatabase.save(record) { (record, error) in
            completion?(record, error)
        }
    }
    
}

public
extension MTLFilterGroup {
    
    public func ckRecord() -> CKRecord {
        
        let record = CKRecord(recordType: "MTLFilterGroup")
        
        record["identifier"]  = self.identifier as CKRecordValue
        record["title"]       = self.title as CKRecordValue
        record["category"]    = self.category as CKRecordValue
        record["description"] = self.filterDescription as CKRecordValue
        record["filterData"]  = filterDataAsset(MTLImage.archive(self)!)
        
        return record
    }
    
    func filterDataAsset(_ data: Data) -> CKAsset {
        
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        let url = try! URL(fileURLWithPath: path!).appendingPathComponent(identifier)
        try! data.write(to: url, options: .atomicWrite) // Handle later
        
        return CKAsset(fileURL: url)
    }
    
}
