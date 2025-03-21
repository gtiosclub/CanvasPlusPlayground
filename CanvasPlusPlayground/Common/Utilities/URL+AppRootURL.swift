//
//  URL+AppRootURL.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 3/21/25.
//

import Foundation

extension URL {
    static var appRootURL: URL? {
        let fileManager = FileManager.default

        if let bundleId = Bundle.main.bundleIdentifier {
            let root = URL.applicationSupportDirectory.appendingPathComponent(bundleId)

            if fileManager.fileExists(atPath: root.path) {
                return root
            } else {
                do {
                    try fileManager.createDirectory(at: root, withIntermediateDirectories: true, attributes: nil)
                    return root
                } catch {
                    LoggerService.main.error("Failure creating directory to root.")
                    return nil
                }
            }
        } else {
            LoggerService.main.error("Failure getting bundle identifier")
            return nil
        }
    }
}
