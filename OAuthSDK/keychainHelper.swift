//
//  keychainHelper.swift
//  OAuthSDK
//
//  Created by RamaKrishna Mallireddy on 10/04/15.
//  Copyright (c) 2015 VUContacts. All rights reserved.
//

import UIKit

extension String {
    func toData() -> NSData? {
        return self.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
    }
}

extension Dictionary {
    func toData() -> NSData? {
        return NSKeyedArchiver.archivedDataWithRootObject(self as! AnyObject)
    }
}

extension NSData {
    func toString() -> String? {
        return (NSString(data: self, encoding: NSUTF8StringEncoding) as! String)
    }
    
    func toDictionary() -> [String: AnyObject]? {
        return NSKeyedUnarchiver.unarchiveObjectWithData(self) as? [String: AnyObject]
    }
}

public class keychainHelper: NSObject {
    
    public class func storeDataForKey(key: String, value: NSData, serviceId: String? = nil) {
        
        let service = serviceId == nil ? NSBundle.mainBundle().bundleIdentifier! : serviceId!
        let secItem = [ kSecClass as NSString : kSecClassGenericPassword as NSString, kSecAttrService as NSString : service, kSecAttrAccount as NSString : key, kSecValueData as NSString : value, ] as NSDictionary
        
        var result: Unmanaged<AnyObject>? = nil
        let status = Int( SecItemAdd(secItem, &result) )
        
        switch status {
        case Int(errSecSuccess):
            println("Successfully stored the value")
        case Int(errSecDuplicateItem):
            println("This item is already saved. Cannot duplicate it")
        default:
            println("An error occurred with code \(status)")
        }
    }
    
    public class func checkAndUpdateValueForKey(key: String, updateValue: NSData? = nil, serviceId: String? = nil) -> Bool {
        
        let service = serviceId == nil ? NSBundle.mainBundle().bundleIdentifier! : serviceId!
        let query = [
            kSecClass as NSString : kSecClassGenericPassword as NSString, kSecAttrService as NSString : service,kSecAttrAccount as NSString : key,] as NSDictionary
        
        var returnedData: Unmanaged<AnyObject>? = nil
        let check = Int(SecItemCopyMatching(query, &returnedData))
        
        if check == Int(errSecSuccess) {
            if updateValue != nil {
                let update = [kSecValueData as NSString : updateValue!,] as NSDictionary
                let updated = Int(SecItemUpdate(query, update))
            
                if updated == Int(errSecSuccess) {
                    return true
                } else {
                    println("Error updating key: \(updated)")
                    return false
                }
            }
            return true
            
        } else {
            if updateValue != nil {
                keychainHelper.storeDataForKey(key, value: updateValue!, serviceId: serviceId)
            }
            println("checking key: \(check)")
            return false
        }
        
    }
    
    public class func getValueForKey(key: String, serviceId: String? = nil) -> NSData? {
        
        let service = serviceId == nil ? NSBundle.mainBundle().bundleIdentifier! : serviceId!
        let query = [
            kSecClass as NSString : kSecClassGenericPassword as NSString, kSecAttrService as NSString : service,kSecAttrAccount as NSString : key, kSecReturnData as NSString : kCFBooleanTrue,] as NSDictionary
        
        var returnedData: Unmanaged<AnyObject>? = nil
        let results = Int(SecItemCopyMatching(query, &returnedData))
        
        if results == Int(errSecSuccess) {
            return (returnedData!.takeRetainedValue() as! NSData)
            
        } else {
            println("Error happened with code: \(results)")
        }
        
        return nil
    }
    
    public class func deleteKey(key: String, serviceId: String? = nil) -> Bool {
        let service = serviceId == nil ? NSBundle.mainBundle().bundleIdentifier! : serviceId!
        let query = [
            kSecClass as NSString : kSecClassGenericPassword as NSString, kSecAttrService as NSString : service,kSecAttrAccount as NSString : key,] as NSDictionary
        
        var returnedData: Unmanaged<AnyObject>? = nil
        let results = Int(SecItemCopyMatching(query, &returnedData))
        
        if results == Int(errSecSuccess) {
            let deleted = Int(SecItemDelete(query))
            
            if deleted == Int(errSecSuccess) {
                return true
            } else {
                println("Error deleting key: \(deleted)")
                return false
            }
            
        } else {
            println("Error checking key: \(results)")
            return false
        }
    }
    
    public class func keyCreationAndModification(key: String, serviceId: String? = nil) -> (NSDate?, NSDate?) {
        let service = serviceId == nil ? NSBundle.mainBundle().bundleIdentifier! : serviceId!
        
        let query = [
            kSecClass as NSString : kSecClassGenericPassword as NSString, kSecAttrService as NSString : service, kSecAttrAccount as NSString : key, kSecReturnAttributes as NSString : kCFBooleanTrue,] as NSDictionary
        
        var returnedData: Unmanaged<AnyObject>? = nil
        let results = Int(SecItemCopyMatching(query, &returnedData))
        
        if results == Int(errSecSuccess) {
            let attributes = returnedData!.takeRetainedValue() as! NSDictionary
            
            let key = attributes[kSecAttrAccount as NSString] as! String
            let accessGroup = attributes[kSecAttrAccessGroup as NSString] as! String
            let creationDate = attributes[kSecAttrCreationDate as NSString] as! NSDate
            let modifiedDate = attributes[ kSecAttrModificationDate as NSString] as! NSDate
            let serviceValue = attributes[kSecAttrService as NSString] as! String
            
            println("Key = \(key)")
            println("Access Group = \(accessGroup)")
            println("Creation Date = \(creationDate)")
            println("Modification Date = \(modifiedDate)")
            println("Service = \(serviceValue)")
            
            return (creationDate, modifiedDate)
            
        } else {
            println("Error happened with code: \(results)")
            return (nil, nil)
        }
    }
    
}
