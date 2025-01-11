//
//  PinnedItemsView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 1/8/25.
//

import SwiftUI

struct PinnedItemsView: View {
    @Environment(PinnedItemsManager.self) private var pinnedItemsManager

    private var sortedTypes: [PinnedItem.PinnedItemType] {
        Array(pinnedItemsManager.pinnedItemsByType.keys)
            .sorted(by: { $0.rawValue < $1.rawValue })
    }

    var body: some View {
        List(sortedTypes, id: \.self) { type in
            Section {
                let items = pinnedItemsManager.pinnedItemsByType[type] ?? []
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(
                        rows: .init(
                            repeating: .init(
                                .flexible(maximum: 400)
                            ),
                            count: min(2, items.count)
                        )
                    ) {
                        ForEach(items) { item in
                            PinnedItemCard(item: item)
                        }
                    }
                }
                .scrollTargetBehavior(.paging)
                .listRowSeparator(.hidden)
                .fixedSize(horizontal: false, vertical: true)

            } header: {
                Text(type.displayName)
                    .font(.title)
                    .fontDesign(.rounded)
                    .foregroundStyle(.tint)
                    .bold()
            }

        }
        .navigationTitle("Pinned")
        #if os(macOS)
        .navigationSplitViewColumnWidth(min: 350, ideal: 400)
        #endif
    }
}
