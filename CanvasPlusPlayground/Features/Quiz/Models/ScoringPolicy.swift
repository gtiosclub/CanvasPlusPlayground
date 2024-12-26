//
//  ScoringPolicy.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/14/24.
//


public enum ScoringPolicy: String, Codable, CaseIterable {
    case keepLatest = "keep_latest", keepHighest = "keep_highest", keepAverage = "keep_average"

    public var text: String {
        switch self {
        case .keepLatest:
            "Latest"
        case .keepHighest:
            "Highest"
        case .keepAverage:
            "Average"
        }
    }
}
