//
//  TextChunk.swift
//  CanvasPlusPlayground
//
//  Created by Kareem Alaiwat on 10/18/26.
//

import CryptoKit
import Foundation

struct TextChunk: Hashable, Sendable {
    let sourceID: String
    let ordinal: Int
    let headingPath: [String]
    let text: String

    var embeddingText: String {
        Self.headingPrefix(for: headingPath) + text
    }

    /// - Parameter headingPath: Enclosing headings, outermost first.
    /// - Returns: The exact text `embeddingText` places before the chunk body, or an empty string.
    static func headingPrefix(for headingPath: [String]) -> String {
        headingPath.isEmpty ? "" : headingPath.joined(separator: " › ") + "\n"
    }

    // Hashes embeddingText rather than text so renaming a section re-embeds its chunks.
    var contentHash: String {
        SHA256.hash(data: Data(embeddingText.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
