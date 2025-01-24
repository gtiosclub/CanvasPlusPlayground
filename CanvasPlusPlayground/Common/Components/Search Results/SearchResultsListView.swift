//
//  SearchResultsListView.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 1/23/25.
//

import SwiftUI

/// https://medium.engineering/how-to-do-pagination-in-swiftui-04511be7fbd1
struct SearchResultsListView<Content: View, Error: View>: View {
    @State var dataSource: any SearchResultListDatasource
    let itemsView: () -> Content

    var body: some View {
        listView
    }

    var listView: some View {
        List {
            itemsView()

            Color.clear.onAppear {
                Task {
                    switch dataSource.loadingState {
                    case .nextPageReady:
                        await dataSource.fetchNextPage()                        
                    default:
                        return
                    }
                }
            }
            .overlay {
                if case let .error(reason) = dataSource.loadingState {
                    ContentUnavailableView(
                        "Failed to load more, \(reason)",
                        systemImage: "exclamationmark"
                    )
                }
            }
        }
        .statusToolbarItem(
            dataSource.label,
            isVisible: dataSource.loadingState == .loading
        )
    }
}

#Preview {
    SearchResultsListView()
}
