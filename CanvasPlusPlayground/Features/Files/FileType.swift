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

    private static func extensionFromFile(_ file: File) -> String {
        URL(fileURLWithPath: file.filename).pathExtension.lowercased()
    }
}
