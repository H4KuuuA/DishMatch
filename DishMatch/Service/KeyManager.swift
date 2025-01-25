//
//  KeyManager.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/25.
//

import Foundation

struct KeyManager {
    private let keyFilePath = Bundle.main.path(forResource: "APIKey", ofType: "plist")

    func getKeys() -> [String: Any]? {
        guard let keyFilePath = keyFilePath,
              let data = FileManager.default.contents(atPath: keyFilePath) else {
            return nil
        }

        do {
            if let keys = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
                return keys
            }
        } catch {
            print("Error reading plist: \(error)")
        }
        return nil
    }

    func getValue(forKey key: String) -> String? {
        guard let keys = getKeys(), let value = keys[key] as? String else {
            return nil
        }
        return value
    }
}
