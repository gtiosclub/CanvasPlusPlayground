//
//  FileType.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/9/24.
//

import Foundation

enum FileType {
    case latex, docx, pdf
    
    var formatExtension: String {
        switch self {
        case .latex: return ".latex"
        case .docx: return ".docx"
        case .pdf: return ".pdf"
        }
    }
    
    /// Checks the filename for file format, returns nil if File format isn't supported or format was uninferable.
    static func fromFile(_ file: File) -> FileType? {
        let fileExtension = URL(fileURLWithPath: file.filename ?? "").pathExtension.lowercased()
        
        switch fileExtension {
        case "latex": return .latex
        case "docx": return .docx
        case "pdf": return .pdf
        default: return nil
        }
    }
    
    static func isSupported(_ file: File) -> Bool {
        self.fromFile(file) != nil
    }
}
