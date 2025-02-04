//
//  SearchResultsListView.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 1/23/25.
//

import SwiftUI

/// Inspired by https://medium.engineering/how-to-do-pagination-in-swiftui-04511be7fbd1
struct SearchResultsListView<
    Content: View,
    DataSource: SearchResultListDataSource,
    SelectionItem: Hashable
>: View {
    enum SelectionValue {
        case single(Binding<SelectionItem>)
        case multi(Binding<Set<SelectionItem>>)
    }

    @State var dataSource: DataSource
    var selection: SelectionValue? = nil
    let itemsView: () -> Content

    init(
        dataSource: DataSource,
        selection: Binding<SelectionItem>? = nil,
        itemsView: @escaping () -> Content
    ) {
        self._dataSource = State(initialValue: dataSource)
        if let selection {
            self.selection = .single(selection)
        }
        self.itemsView = itemsView
    }

    init(
        dataSource: DataSource,
        selection: Binding<Set<SelectionItem>>? = nil,
        itemsView: @escaping () -> Content
    ) {
        self._dataSource = State(initialValue: dataSource)
        if let selection {
            self.selection = .multi(selection)
        }
        self.itemsView = itemsView
    }

    var body: some View {
        listView
    }

    var listView: some View {
        Group {
            if case .single(let selection) = selection {
                List(selection: selection) {
                    listContent
                }
            } else if case .multi(let selection) = selection {
                List(selection: selection) {
                    listContent
                }
            } else {
                List {
                    listContent
                }
            }
        }
        .statusToolbarItem(
            dataSource.label,
            isVisible: dataSource.loadingState == .loading
        )
    }

    @ViewBuilder
    var listContent: some View {
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

// #Preview {
//    SearchResultsListView()
// }
