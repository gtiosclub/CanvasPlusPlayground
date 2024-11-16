//
//  NetworkError.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 11/9/24.
//

import Foundation

enum NetworkError: Error {
    case failedToDecode(msg: String), fetchFailed(msg: String), invalidURL(msg: String), failedToEncode
}
