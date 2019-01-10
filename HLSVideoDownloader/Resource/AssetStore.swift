//
//  AssetStore.swift
//  ATMusicPlayer
//
//  Created by Amrit Tiwari on 9/28/18.
//  Copyright © 2018 Amrit Tiwari. All rights reserved.
//

import Foundation

internal struct AssetStore {
    
    private static var shared: [String: String] = {
        if FileManager.default.fileExists(atPath: storeURL.path) {
            return NSDictionary(contentsOf: storeURL) as! [String : String]
        }
        return [:]
    }()
    
    private static let storeURL: URL = {
    
//        let fileManager = FileManager.default
//        let documentsUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
//        let appInternalUrl:URL = documentsUrl.appendingPathComponent(".InternalFolderCreatedByAmrit")
//        try? fileManager.createDirectory(at: appInternalUrl, withIntermediateDirectories: true, attributes: nil)
//        return appInternalUrl.appendingPathComponent("LastPath")
        
        let library = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
        return URL(fileURLWithPath: library).appendingPathComponent("ATMusicPlayer").appendingPathExtension("plist")
    }()
    
    static func allMap() -> [String: String] {
        return shared
    }
    
    static func path(forName: String) -> String? {
        if let path = shared[forName] {
            return path
        }
        return nil
    }
    
    @discardableResult
    static func set(path: String, forName: String) -> Bool {
        shared[forName] = path
        let dict = shared as NSDictionary
        return dict.write(to: storeURL, atomically: true)
    }
    
    @discardableResult
    static func remove(forName: String) -> Bool {
        guard let _ = shared.removeValue(forKey: forName) else { return false }
        let dict = shared as NSDictionary
        return dict.write(to: storeURL, atomically: true)
    }
}
