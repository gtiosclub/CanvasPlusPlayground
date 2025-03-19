//
//  APIGradingPeriod.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/23/24.
//

import Foundation

// swiftlint:disable identifier_name
// https://canvas.instructure.com/doc/api/grading_periods.html
// https://github.com/instructure/canvas-ios/blob/49a3e347116d623638c66b7adbcc946294faa212/Core/Core/Grades/Model/API/APIGradingPeriod.swift
struct APIGradingPeriod: Codable, Equatable, Hashable {
    let id: Int
    let title: String
    let start_date: Date?
    let end_date: Date?
}
