//
//  SearchIndex.swift
//  CanvasPlusPlayground
//
//  Created by Kareem Alaiwat on 10/20/26.
//

import Accelerate

/// Every stored vector, centered and scaled to unit length, packed into one row-major matrix
/// so a query scores against all of them with a single matrix-vector multiply.
struct SearchIndex: Sendable {
    let dimension: Int
    let center: [Float]?
    private(set) var matrix: [Float] = []
    /// The candidate each matrix row belongs to.
    private(set) var owners: [Int] = []

    /// - Parameters:
    ///   - candidates: Each candidate's vectors (usually one; more when a chunk was split for truncation).
    ///   - centroid: Subtracted from every vector before normalizing, or nil for raw vectors.
    ///     Ignored when its length isn't `dimension`.
    ///   - dimension: The vector length to index. Vectors of any other length, or of zero length after
    ///     centering, are skipped.
    init(candidates: [[[Float]]], centroid: [Float]?, dimension: Int) {
        self.dimension = dimension
        center = centroid?.count == dimension ? centroid : nil

        matrix.reserveCapacity(candidates.count * dimension)
        for (owner, vectors) in candidates.enumerated() {
            for vector in vectors where vector.count == dimension {
                guard let unit = unitVector(vector) else { continue }
                matrix += unit
                owners.append(owner)
            }
        }
    }

    /// - Parameters:
    ///   - query: A vector of length `dimension`.
    ///   - isIncluded: Decides by candidate index which candidates may appear in the result.
    /// - Returns: Candidate indices with their best vector's cosine similarity to the query,
    ///   best first; ties keep candidate order.
    func rank(query: [Float], where isIncluded: (Int) -> Bool = { _ in true }) -> [(index: Int, score: Float)] {
        guard query.count == dimension, !owners.isEmpty, let unitQuery = unitVector(query) else { return [] }

        var scores = [Float](repeating: 0, count: owners.count)
        vDSP_mmul(matrix, 1, unitQuery, 1, &scores, 1, vDSP_Length(owners.count), 1, vDSP_Length(dimension))

        var best: [Int: Float] = [:]
        for (row, owner) in owners.enumerated() where isIncluded(owner) {
            best[owner] = max(best[owner] ?? -.infinity, scores[row])
        }
        return best
            .map { (index: $0.key, score: $0.value) }
            .sorted { $0.score != $1.score ? $0.score > $1.score : $0.index < $1.index }
    }

    private func unitVector(_ vector: [Float]) -> [Float]? {
        let centered = center.map { zip(vector, $0).map(-) } ?? vector
        let length = centered.reduce(0) { $0 + $1 * $1 }.squareRoot()
        return length > 0 ? centered.map { $0 / length } : nil
    }
}
