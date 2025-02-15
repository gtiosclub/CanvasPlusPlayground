//
//  APIGradingSchemeEntry.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/26/24.
//

import Foundation

// https://github.com/instructure/canvas-ios/blob/master/Core/Core/Grades/Model/API/APIGradingSchemeEntry.swift
struct APIGradingSchemeEntry: APIResponse, Identifiable {
    typealias Model = NoOpCacheable

    var id: String

    let name: String
    let value: Double

    init(name: String, value: Double) {
        self.id = UUID().uuidString
        self.name = name
        self.value = value
    }

    /**
     This initializer is used when constructing grading scheme from a Course API response
     which has a different format compared to the grading scheme API.
     */
    init?(courseGradingScheme: [TypeSafeCodable<String, Double>]) {
        guard courseGradingScheme.count == 2,
              let name = courseGradingScheme[0].value1,
              let value = courseGradingScheme[1].value2
        else { return nil }
        self.init(name: name, value: value)
    }
}
