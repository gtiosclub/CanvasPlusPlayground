//
//  IntelligenceServiceProvider.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 8/12/25.
//

import Foundation
import FoundationModels

@available(iOS 26.0, macOS 26.0, *)
@MainActor
protocol IntelligenceServiceProvider: AnyObject {
    associatedtype Input
    associatedtype Output: Codable

    var session: LanguageModelSession? { get set }

    func setup()
    func performRequest(for input: Input) async throws -> Output
}

enum IntelligenceServiceError: Error {
    case sessionNotAvailable
}
