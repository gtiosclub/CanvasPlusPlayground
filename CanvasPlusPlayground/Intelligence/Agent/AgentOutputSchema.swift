//
//  AgentOutputSchema.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/18/26.
//

import Foundation
import FoundationModels

/// Provider-neutral output schemas.
///
/// Decision (#571): output types are defined once as `@Generable` Swift types.
/// - On-device: the session uses the type's `GenerationSchema` directly.
/// - Cloud: `jsonSchema(for:)` encodes the same `GenerationSchema` as JSON Schema to send with the
///   request, and `decode(_:from:)` turns the JSON reply back into the Swift type.
///
/// The other direction (hand-written JSON Schema decoded into a `GenerationSchema`) also works,
/// but every output would come back as untyped `GeneratedContent`, so features would lose
/// compile-time checking. Generable-first keeps one typed definition.
@available(iOS 26.0, macOS 26.0, *)
enum AgentOutputSchema {
    /// JSON Schema for `type`. FoundationModels adds an `x-order` key (property order) that
    /// isn't standard JSON Schema; it's removed here.
    static func jsonSchema<Output: Generable>(for type: Output.Type) throws -> Data {
        let encoded = try JSONEncoder().encode(type.generationSchema)
        let object = try JSONSerialization.jsonObject(with: encoded)
        return try JSONSerialization.data(withJSONObject: removingNonStandardKeys(object), options: [.sortedKeys])
    }

    /// Decodes a provider's JSON reply into the Swift type.
    static func decode<Output: Generable>(_ type: Output.Type, from json: String) throws -> Output {
        do {
            return try Output(GeneratedContent(json: json))
        } catch {
            throw AgentModelError.decodingFailed
        }
    }

    private static func removingNonStandardKeys(_ value: Any) -> Any {
        if let dictionary = value as? [String: Any] {
            return dictionary
                .filter { !$0.key.hasPrefix("x-") }
                .mapValues(removingNonStandardKeys)
        } else if let array = value as? [Any] {
            return array.map(removingNonStandardKeys)
        }

        return value
    }
}
