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
    @Relationship(.unique) var file: File

    var localURL: URL?
    var downloadedDate: Date?

    var progress: Double = 0
    @Transient var downloadTask: URLSessionDownloadTask?

    init(file: File) {
        self.file = file
//        super.init()
    }

//    func urlSession(_ session: URLSession,
//                    downloadTask: URLSessionDownloadTask,
//                    didWriteData bytesWritten: Int64,
//                    totalBytesWritten: Int64,
//                    totalBytesExpectedToWrite: Int64) {
////        self.progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
//    }
}
