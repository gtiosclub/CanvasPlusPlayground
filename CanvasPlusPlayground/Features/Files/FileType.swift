//
//  FileType.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/9/24.
//

import Foundation
import QuickLook

struct FileType {
    let fileExtension: String

    var formatExtension: String {
        "." + fileExtension
    }

    init(file: File) {
        self.fileExtension = Self.extensionFromFile(file)
    }

    /// Checks the filename for file format, returns nil if File format isn't supported or format was uninferable.
    static func extensionFromFile(_ file: File) -> String {
        let fileExtension = URL(fileURLWithPath: file.filename).pathExtension.lowercased()

        return fileExtension
    }
}
