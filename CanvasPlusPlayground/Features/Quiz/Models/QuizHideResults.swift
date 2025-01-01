//
//  QuizHideResults.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/14/24.
//

import Foundation

public enum QuizHideResults: String, Codable {
    case always, untilAfterLastAttempt = "until_after_last_attempt"
}
