//
//  SearchResultsListView.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 1/23/25.
//

import SwiftUI

/// https://medium.engineering/how-to-do-pagination-in-swiftui-04511be7fbd1
struct SearchResultsListView<Content: View, DataSource: SearchResultListDatasource>: View {
    @State var dataSource: DataSource
    let itemsView: () -> Content

    init(
        dataSource: DataSource,
        itemsView: @escaping () -> Content
    ) {
        self._dataSource = State(initialValue: dataSource)
        self.itemsView = itemsView
    }

    var body: some View {
        listView
    }

    var listView: some View {
        List {
            itemsView()

            if dataSource.queryMode == .offline {
                offlineLabel
            }

            switch dataSource.loadingState {
            case .nextPageReady:
                Color.clear
                    .onAppear {
                        Task { await dataSource.fetchNextPage() }
                    }
            case .error(let reason):
                errorView(for: reason)
            case .idle, .loading:
                EmptyView()
            }
        }
        .statusToolbarItem(
            dataSource.label,
            isVisible: dataSource.loadingState == .loading
        )
    }

    func errorView(for reason: String) -> some View {
        VStack {
            Text("Failed to load more, try again.")
            Text(reason)

            Button("Try again") {
                Task { await dataSource.fetchNextPage() }
            }
            .bold()
        }
        .foregroundStyle(.gray)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical)
    }

    var offlineLabel: some View {
        HStack {
            Image(systemName: "wifi.slash")
            Text("Offline Results")
                .foregroundStyle(.gray)
                .font(.system(size: 16))
        }
    }
}

//#Preview {
//    SearchResultsListView()
//}
