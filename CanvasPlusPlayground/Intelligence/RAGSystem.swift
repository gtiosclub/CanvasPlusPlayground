//
//  Document.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 3/29/25.
//

import Foundation
import NaturalLanguage

class RAGSystem {
    private var documents: [Document] = []
    private let embeddingModel: NLEmbedding

    init() {
        guard let model = NLEmbedding.wordEmbedding(for: .english) else {
            fatalError("Unable to load embedding model")
        }
        self.embeddingModel = model
    }

    func addDocument(_ document: Document) {
        let words = document.content.components(separatedBy: .whitespacesAndNewlines)
        let embeddings = words.compactMap { embeddingModel.vector(for: $0) }
        let averageEmbedding = average(embeddings)
        document.embedding = averageEmbedding
        documents.append(document)
    }

    func searchRelevantDocuments(for query: String, limit: Int = 3) -> [Document] {
        let queryEmbedding = getEmbedding(for: query)
        let sortedDocuments = documents.sorted { doc1, doc2 in
            guard let emb1 = doc1.embedding, let emb2 = doc2.embedding else { return false }
            return cosineSimilarity(queryEmbedding, emb1) > cosineSimilarity(queryEmbedding, emb2)
        }
        return Array(sortedDocuments.prefix(limit))
    }

    private func getEmbedding(for text: String) -> [Double] {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        let embeddings = words.compactMap { embeddingModel.vector(for: $0) }
        return average(embeddings)
    }

    private func average(_ vectors: [[Double]]) -> [Double] {
        guard !vectors.isEmpty else { return [] }
        let sum = vectors.reduce(into: Array(repeating: 0.0, count: vectors[0].count)) { result, vector in
            for (index, value) in vector.enumerated() {
                result[index] += value
            }
        }
        return sum.map { $0 / Double(vectors.count) }
    }

    private func cosineSimilarity(_ v1: [Double], _ v2: [Double]) -> Double {
        guard v1.count == v2.count else { return 0 }
        let dotProduct = zip(v1, v2).map(*).reduce(0, +)
        let magnitude1 = sqrt(v1.map { $0 * $0 }.reduce(0, +))
        let magnitude2 = sqrt(v2.map { $0 * $0 }.reduce(0, +))
        return dotProduct / (magnitude1 * magnitude2)
    }
}

class Document {
    let id: String
    let content: String
    var embedding: [Double]?

    init(id: String, content: String) {
        self.id = id
        self.content = content
    }
}
