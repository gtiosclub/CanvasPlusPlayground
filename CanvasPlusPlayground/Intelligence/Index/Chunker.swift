//
//  Chunker.swift
//  CanvasPlusPlayground
//
//  Created by Kareem Alaiwat on 10/18/26.
//

import Foundation
import NaturalLanguage

struct Chunker: Sendable {
    typealias Block = HTMLTextNormalizer.Block

    /// Upper bound on a chunk's `embeddingText`, in estimated tokens. Keep it below
    /// `NLContextualEmbedding.maximumSequenceLength` (256), which silently truncates longer input.
    var maxTokens = 240

    /// - Parameters:
    ///   - html: The HTML body of a Canvas object (page, announcement, assignment description…).
    ///   - sourceID: Stable identifier of that object, copied onto every chunk.
    ///   - title: The object's title, used as the outermost heading of every chunk.
    func chunks(fromHTML html: String, sourceID: String, title: String? = nil) -> [TextChunk] {
        chunks(from: HTMLTextNormalizer().blocks(fromHTML: html), sourceID: sourceID, title: title)
    }

    /// - Parameters:
    ///   - text: Plain text, e.g. extracted from a file.
    ///   - sourceID: Stable identifier of the source object, copied onto every chunk.
    ///   - title: The object's title, used as the outermost heading of every chunk.
    func chunks(fromPlainText text: String, sourceID: String, title: String? = nil) -> [TextChunk] {
        chunks(from: HTMLTextNormalizer().blocks(fromPlainText: text), sourceID: sourceID, title: title)
    }

    /// - Parameters:
    ///   - blocks: Normalized blocks. Headings start new sections and are not emitted as body text.
    ///   - sourceID: Stable identifier of the source object, copied onto every chunk.
    ///   - title: The object's title, used as the outermost heading of every chunk.
    /// - Returns: Chunks in document order with consecutive ordinals. A chunk never spans two sections.
    ///   Heading paths costing more than half of `maxTokens` lose their outermost headings first.
    func chunks(from blocks: [Block], sourceID: String, title: String? = nil) -> [TextChunk] {
        var result: [TextChunk] = []

        for section in Self.sections(of: blocks) {
            var headingPath = (title.map { [$0] } ?? []) + section.headingPath
            while headingPath.count > 1, Self.prefixTokens(headingPath) > maxTokens / 2 {
                headingPath.removeFirst()
            }
            let budget = max(maxTokens - Self.prefixTokens(headingPath), maxTokens / 2)

            let units = section.blocks.enumerated().flatMap { blockIndex, block in
                Self.sentences(in: block.text)
                    .flatMap { Self.split($0, toFit: budget) }
                    .map { Unit(text: $0, tokens: Self.estimatedTokens($0), blockIndex: blockIndex) }
            }

            for range in pack(units.map(\.tokens), budget: budget) {
                result.append(TextChunk(
                    sourceID: sourceID,
                    ordinal: result.count,
                    headingPath: headingPath,
                    text: Self.join(units[range])
                ))
            }
        }

        return result
    }

    /// Groups consecutive units into chunks.
    ///
    /// - Parameters:
    ///   - tokenCounts: Estimated token count of each unit, in document order. Every count is `<= budget`.
    ///   - budget: Maximum total tokens per chunk.
    /// - Returns: Ranges into `tokenCounts`, one per chunk, in order. Ranges will not overlap.
    func pack(_ tokenCounts: [Int], budget: Int) -> [Range<Int>] {
        guard !tokenCounts.isEmpty, budget > 0 else {
            return []
        }

        let sum = tokenCounts.reduce(0, +)
        let totalChunksNeeded = max(1, Self.divideRoundingUp(sum, by: budget))
        let tokensPerChunk = max(1, Self.divideRoundingUp(sum, by: totalChunksNeeded))
        var ranges: [Range<Int>] = []

        let n = tokenCounts.count
        var firstIndex = 0
        var runningCount = 0
        for countIndex in 0..<n {
            let tokenCount = tokenCounts[countIndex]

            // chunk already reached the target in a previous iteration
            let exceededBefore = runningCount >= tokensPerChunk
            // this unit cannot fit regardless
            let wouldOverflow = runningCount + tokenCount > budget

            if exceededBefore || wouldOverflow, firstIndex < countIndex {
                ranges.append(firstIndex..<countIndex)
                runningCount = tokenCount
                firstIndex = countIndex
            } else {
                runningCount += tokenCount
            }
        }
        ranges.append(firstIndex..<n)
        
        return ranges
    }

    // MARK: - Sections and units

    private struct Section {
        let headingPath: [String]
        var blocks: [Block]
    }

    private struct Unit {
        let text: String
        let tokens: Int
        let blockIndex: Int
    }

    private static func sections(of blocks: [Block]) -> [Section] {
        var sections: [Section] = []
        var current: Section?

        for block in blocks {
            if case .heading = block.kind {
                current.map { sections.append($0) }
                current = nil
                continue
            }
            if current == nil { current = Section(headingPath: block.headingPath, blocks: []) }
            current?.blocks.append(block)
        }
        current.map { sections.append($0) }
        return sections
    }

    // Units from the same block are sentences of one paragraph; different blocks get a line break.
    private static func join(_ units: ArraySlice<Unit>) -> String {
        var text = ""
        var previousBlock: Int?
        for unit in units {
            if let previousBlock { text += previousBlock == unit.blockIndex ? " " : "\n" }
            text += unit.text
            previousBlock = unit.blockIndex
        }
        return text
    }

    // MARK: - Segmentation

    // Calibrated against NLContextualEmbedding on Canvas text (mean 2.3, worst 4.8 for URLs and codes).
    // Underestimates on dense text are caught by ChunkEmbedder's truncation check.
    private static let tokensPerWord = 2.6

    static func estimatedTokens(_ text: String) -> Int {
        let words = text.split(whereSeparator: \.isWhitespace).count
        return Int((Double(words) * tokensPerWord).rounded(.up))
    }

    private static func prefixTokens(_ headingPath: [String]) -> Int {
        estimatedTokens(TextChunk.headingPrefix(for: headingPath))
    }

    static func sentences(in text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        return tokenizer.tokens(for: text.startIndex..<text.endIndex)
            .map { text[$0].trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func split(_ sentence: String, toFit budget: Int) -> [String] {
        guard estimatedTokens(sentence) > budget else { return [sentence] }
        let wordsPerPiece = max(1, Int(Double(budget) / tokensPerWord))
        let words = sentence.split(whereSeparator: \.isWhitespace)
        return stride(from: 0, to: words.count, by: wordsPerPiece).map {
            words[$0..<min($0 + wordsPerPiece, words.count)].joined(separator: " ")
        }
    }

    private static func divideRoundingUp(_ dividend: Int, by divisor: Int) -> Int {
        dividend / divisor + (dividend % divisor == 0 ? 0 : 1)
    }
}
