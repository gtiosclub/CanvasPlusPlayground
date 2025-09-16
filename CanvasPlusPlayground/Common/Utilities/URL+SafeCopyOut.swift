//
//  URL+SafeCopyOut.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 9/13/25.
//

import Foundation

extension URL {
    func safeCopyOut() throws -> URL {
        let coordinator = NSFileCoordinator()
        var coordError: NSError?
        var destURL: URL?
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(self.lastPathComponent)

        coordinator.coordinate(readingItemAt: self, options: [.withoutChanges], error: &coordError) { readURL in
            try? FileManager.default.removeItem(at: tmp)
            try! FileManager.default.copyItem(at: readURL, to: tmp)
            destURL = tmp
        }
        if let e = coordError { throw e }
        return destURL!
    }
}
