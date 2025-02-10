//
//  SearchResultListDatasource.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 1/23/25.
//

import Foundation

protocol SearchResultListDataSource: AnyObject {
    /// Label for source type (e.g. Grade for grades loading). Used in loading text.
    var label: String { get }
    /// Should start with .nextPageFound
    var loadingState: LoadingState { get set }
    var queryMode: PageMode { get set }

    func fetchNextPage() async
}

enum LoadingState: Equatable {
    case idle /// To stop querying for pages - if no more exist
    case nextPageReady /// To fetch new page the next time we scroll down
    case error(_ reason: String = "")
    case loading /// Can't query anything during this
}

enum PageMode {
    case offline, live
}

extension SearchResultListDataSource {
    @MainActor
    func setLoadingState(_ state: LoadingState) {
        self.loadingState = state
    }

    @MainActor
    func setQueryMode(_ mode: PageMode) {
        self.queryMode = mode
    }
}

/*
 Sample run: nextPageFound (initial), loading, nextPageFound, loading, error, loading, nextPageFound ... loading, idle (no more pages)
 */
