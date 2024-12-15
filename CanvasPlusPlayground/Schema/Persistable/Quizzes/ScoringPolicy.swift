//
//  ScoringPolicy.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/14/24.
//


public enum ScoringPolicy: String, Codable, CaseIterable {
    case keep_latest, keep_highest, keep_average

    public var text: String {
        switch self {
        case .keep_latest:
            return String(localized: "Latest", bundle: .core)
        case .keep_highest:
            return String(localized: "Highest", bundle: .core)
        case .keep_average:
            return String(localized: "Average", bundle: .core)
        }
    }
}