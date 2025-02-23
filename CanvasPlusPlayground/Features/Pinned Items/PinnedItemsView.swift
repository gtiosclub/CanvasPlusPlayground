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
                sectionContent(for: type)
            } header: {
                Text(type.displayName)
                    .font(.title)
                    .fontDesign(.rounded)
                    .foregroundStyle(.tint)
                    .bold()
            }

        }
        .onAppear {
            for item in pinnedItemsManager.pinnedItems {
                Task {
                    await item.itemData()
                }
            }
        }
        .navigationTitle("Pinned")
        #if os(macOS)
        .navigationSplitViewColumnWidth(min: 350, ideal: 400)
        #endif
        .overlay {
            if sortedTypes.isEmpty {
                ContentUnavailableView(
                    "No Pinned Items",
                    systemImage: "pin.fill",
                    description: Text(
                        "Pin files, assignments, announcements, and more from across all your courses for quick access."
                    )
                )
            }
        }
    }

    @ViewBuilder
    private func sectionContent(for type: PinnedItem.PinnedItemType) -> some View {
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
                    NavigationLink {
                        PinnedItemDetailView(item: item)
                    } label: {
                        PinnedItemCard(item: item)
                    }
                    .buttonStyle(.plain)

                }
            }
        }
        .scrollTargetBehavior(.paging)
        .listRowSeparator(.hidden)
        .fixedSize(horizontal: false, vertical: true)
        .listRowInsets(EdgeInsets())
        .contentMargins(.horizontal, 24, for: .scrollContent)
    }
}
