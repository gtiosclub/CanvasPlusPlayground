//
//  APIGradingPeriod.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/23/24.
//

import Foundation

struct APIGradingPeriod: Codable, Equatable, Hashable {

    // swiftlint:disable identifier_name
    let id: Int
    let title: String
    let start_date: Date?
    let end_date: Date?
    // swiftlint:enable identifier_name
}
