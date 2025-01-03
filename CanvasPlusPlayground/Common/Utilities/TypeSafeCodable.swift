//
//  TypeSafeCodable.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/23/24.
//

import Foundation

typealias CodableEquatable = Codable & Equatable

/** COPIED FROM https://github.com/instructure/canvas-ios/blob/49a3e347116d623638c66b7adbcc946294faa212/Core/Core/API/TypeSafeCodable.swift#L25
 The purpose of this entity is to allow two different data types to be coded/decoded to/from a single entity.
 Useful if a JSON property has different data types based on the context.
 Example: `APIPlannable`'s `submissions` property can be either a `Bool`
 or a custom structure depending on if the plannable is an announcement or an assignment.
 */
struct TypeSafeCodable<T1: CodableEquatable, T2: CodableEquatable>: CodableEquatable {
    public let value1: T1?
    public let value2: T2?

    public init(value1: T1?, value2: T2?) {
        self.value1 = value1
        self.value2 = value2
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let type1Value = try? container.decode(T1.self) {
            value1 = type1Value
            value2 = nil

        } else if let type2Value = try? container.decode(T2.self) {
            value1 = nil
            value2 = type2Value

        } else {
            value1 = nil
            value2 = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var singleEncoder = encoder.singleValueContainer()

        if let value1 = value1 {
            try singleEncoder.encode(value1)

        } else if let value2 = value2 {
            try singleEncoder.encode(value2)

        } else {
            try singleEncoder.encodeNil()
        }
    }
}
