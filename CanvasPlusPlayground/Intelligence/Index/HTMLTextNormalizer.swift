//
//  HTMLTextNormalizer.swift
//  CanvasPlusPlayground
//
//  Created by Kareem Alaiwat on 10/18/26.
//

import Foundation

/// Converts HTML into plain-text blocks, preserving block boundaries and heading structure.
/// A forgiving scanner rather than a parser; safe to call off the main thread.
struct HTMLTextNormalizer: Sendable {
    struct Block: Equatable, Sendable {
        enum Kind: Equatable, Sendable {
            case heading(level: Int)
            case paragraph
            case listItem
            case tableRow
            case preformatted
        }

        let kind: Kind
        let text: String
        let headingPath: [String]
    }

    /// - Parameter html: An HTML fragment or document, e.g. a page body or announcement message.
    /// - Returns: Non-empty blocks in document order. Each block's `headingPath` lists its
    ///   enclosing headings, outermost first, excluding the block itself.
    func blocks(fromHTML html: String) -> [Block] {
        var builder = BlockBuilder()
        var index = html.startIndex

        while index < html.endIndex {
            guard html[index] == "<", let tag = Tag(in: html, at: index) else {
                let next = html[html.index(after: index)...].firstIndex(of: "<") ?? html.endIndex
                builder.appendText(Self.decodeEntities(in: html[index..<next]))
                index = next
                continue
            }

            index = tag.end

            if Self.skippedElements.contains(tag.name), !tag.isClosing {
                index = html.range(of: "</\(tag.name)", options: .caseInsensitive, range: index..<html.endIndex)?
                    .upperBound ?? html.endIndex
                index = html[index...].firstIndex(of: ">").map { html.index(after: $0) } ?? html.endIndex
                continue
            }

            builder.handle(tag)
        }

        builder.flush()
        return builder.blocks
    }

    /// - Parameter text: Text that was never HTML, such as text extracted from a PDF.
    /// - Returns: One paragraph block per blank-line-separated run of lines.
    func blocks(fromPlainText text: String) -> [Block] {
        text.components(separatedBy: "\n")
            .split { $0.allSatisfy(\.isWhitespace) }
            .map { lines in
                Block(kind: .paragraph, text: Self.collapseWhitespace(lines.joined(separator: " ")), headingPath: [])
            }
            .filter { !$0.text.isEmpty }
    }

    // MARK: - Tags

    private static let skippedElements: Set<String> = ["script", "style", "head", "noscript", "template", "svg"]

    private struct Tag {
        let name: String
        let isClosing: Bool
        let end: String.Index

        // Returns nil when "<" doesn't start a tag (e.g. "a < b"), so it's kept as text.
        init?(in html: String, at start: String.Index) {
            let afterBracket = html.index(after: start)
            guard afterBracket < html.endIndex else { return nil }

            if html[afterBracket...].hasPrefix("!--") {
                name = "!--"
                isClosing = false
                end = html.range(of: "-->", range: afterBracket..<html.endIndex)?.upperBound ?? html.endIndex
                return
            }

            let first = html[afterBracket]
            guard first.isLetter || first == "/" || first == "!" else { return nil }
            guard let close = html[afterBracket...].firstIndex(of: ">") else { return nil }

            var body = html[afterBracket..<close]
            isClosing = body.first == "/"
            if isClosing { body = body.dropFirst() }
            name = body.prefix { $0.isLetter || $0.isNumber }.lowercased()
            end = html.index(after: close)
        }
    }

    // MARK: - Block assembly

    private struct BlockBuilder {
        private(set) var blocks: [Block] = []
        private var buffer = ""
        private var kind: Block.Kind = .paragraph
        private var headingStack: [(level: Int, text: String)] = []

        private static let blockElements: Set<String> = [
            "p", "div", "section", "article", "header", "footer", "blockquote",
            "ul", "ol", "dl", "dt", "dd", "table", "thead", "tbody", "hr", "figure", "figcaption"
        ]

        mutating func appendText(_ text: String) {
            buffer += text
        }

        mutating func handle(_ tag: Tag) {
            switch tag.name {
            case "h1", "h2", "h3", "h4", "h5", "h6":
                flush()
                kind = tag.isClosing ? .paragraph : .heading(level: Int(String(tag.name.last!))!)
            case "li":
                flush()
                kind = tag.isClosing ? .paragraph : .listItem
            case "tr":
                flush()
                kind = tag.isClosing ? .paragraph : .tableRow
            case "td", "th":
                if !tag.isClosing, !buffer.allSatisfy(\.isWhitespace) { buffer += " | " }
            case "pre":
                flush()
                kind = tag.isClosing ? .paragraph : .preformatted
            case "br":
                // Canvas authors use <br> as a line separator ("Exam 1: Oct 3<br>Exam 2: Nov 7").
                if kind == .preformatted { buffer += "\n" } else { flush() }
            case let name where Self.blockElements.contains(name):
                flush()
            default:
                break
            }
        }

        mutating func flush() {
            defer { buffer = "" }
            let text = kind == .preformatted
                ? buffer.trimmingCharacters(in: .newlines)
                : HTMLTextNormalizer.collapseWhitespace(buffer)
            guard !text.isEmpty else { return }

            blocks.append(Block(kind: kind, text: text, headingPath: headingStack.map(\.text)))

            if case let .heading(level) = kind {
                headingStack.removeAll { $0.level >= level }
                headingStack.append((level, text))
            }
        }
    }

    // MARK: - Text helpers

    static func collapseWhitespace(_ text: String) -> String {
        text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    private static let namedEntities: [String: String] = [
        "amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'", "nbsp": " ",
        "ndash": "–", "mdash": "—", "lsquo": "‘", "rsquo": "’", "ldquo": "“", "rdquo": "”",
        "hellip": "…", "bull": "•", "middot": "·", "copy": "©", "reg": "®", "trade": "™",
        "deg": "°", "times": "×", "divide": "÷", "plusmn": "±", "frac12": "½", "frac14": "¼",
        "frac34": "¾", "sect": "§", "para": "¶", "euro": "€", "cent": "¢", "pound": "£"
    ]

    /// - Parameter text: Text that may contain named (`&amp;`) or numeric (`&#233;`, `&#xE9;`) entities.
    /// - Returns: The text with known entities decoded. Unknown entities are left unchanged.
    static func decodeEntities<S: StringProtocol>(in text: S) -> String {
        guard text.contains("&") else { return String(text) }

        var result = ""
        var index = text.startIndex
        while let amp = text[index...].firstIndex(of: "&") {
            result += text[index..<amp]
            let afterAmp = text.index(after: amp)

            // Bounded so a lone "&" doesn't scan the rest of the document for ";".
            let window = text[afterAmp...].prefix(10)
            if let semi = window.firstIndex(of: ";"), let decoded = decodeEntity(String(text[afterAmp..<semi])) {
                result += decoded
                index = text.index(after: semi)
            } else {
                result += "&"
                index = afterAmp
            }
        }
        result += text[index...]
        return result
    }

    private static func decodeEntity(_ name: String) -> String? {
        if name.hasPrefix("#") {
            let digits = name.dropFirst()
            let value = digits.first == "x" || digits.first == "X"
                ? UInt32(digits.dropFirst(), radix: 16)
                : UInt32(digits)
            return value.flatMap(Unicode.Scalar.init).map { String(Character($0)) }
        }
        return namedEntities[name]
    }
}
