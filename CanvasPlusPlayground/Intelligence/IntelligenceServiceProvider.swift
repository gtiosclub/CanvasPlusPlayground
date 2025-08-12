//
//  IntelligenceServiceProvider.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 8/12/25.
//

import Foundation

@MainActor
protocol IntelligenceServiceProvider {
    associatedtype Input
    associatedtype Output: Codable

    func setup()
    func performRequest(for input: Input) async throws -> Output
}
