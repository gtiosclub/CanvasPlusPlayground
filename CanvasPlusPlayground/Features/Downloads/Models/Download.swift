//
//  Download.swift
//  CanvasPlusPlayground
//
//  Created by João Pozzobon on 2/17/25.
//

import SwiftData
import Foundation

@Model
class Download {
    var id = UUID()
    @Relationship(.unique, inverse: \File.download) var file: File

    var localURL: URL?
    var finalURL: URL
    var downloadedDate: Date?

    var progress: Double = 0
    @Transient var downloadTask: URLSessionDownloadTask?

    init(file: File, finalURL: URL) {
        self.file = file
        self.finalURL = finalURL
    }
}
