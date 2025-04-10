//
//  PageConfiguration.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 4/3/25.
//


enum PageConfiguration {
    /// 1-indexed. Get a specific page from offset (perPage*(pageNum-1))
    case page(pageNum: Int, perPage: Int = 50)
    /// Avoid using this for possibly large network/storage queries
    case all(perPage: Int = 50)

    var perPage: Int {
        switch self {
        case let .page(_, perPage):
            return perPage
        case let .all(perPage):
            return perPage
        }
    }

    var offset: Int {
        switch self {
        case let .page(pageNum, perPage):
            return perPage * (pageNum - 1)
        case .all:
            return 0
        }
    }

    var orderMin: Int {
        offset
    }

    var orderMax: Int {
        switch self {
        case .all:
            Int.max
        case let .page(pageNum, perPage):
            (pageNum * perPage)
        }
    }
}
