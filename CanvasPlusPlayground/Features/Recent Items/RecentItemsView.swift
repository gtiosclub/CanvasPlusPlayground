//
//  RecentItemsView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/11/25.
//

import SwiftUI

struct RecentItemsView: View {
    @Environment(RecentItemsManager.self) private var recentItemsManager
    @Environment(NavigationModel.self) private var navigationModel

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 250, maximum: 350), spacing: 16)
                ],
                spacing: 16
            ) {
                ForEach(recentItemsManager.recentItems) { item in
                    if let destination = item.navigationDestination {
                        NavigationLink(value: destination) {
                            RecentItemCard(item: item)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background {
                                    RoundedRectangle(cornerRadius: 16.0)
                                        .fill(.secondary.opacity(0.15))
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .task {
            await recentItemsManager.loadRecentItemsData()
        }
        .navigationTitle("Recent Items")
        .overlay {
            if recentItemsManager.recentItems.isEmpty {
                ContentUnavailableView(
                    "No Recent Items",
                    systemImage: "clock",
                    description: Text(
                        "Assignments, announcements, and files you view will appear here for quick access."
                    )
                )
            }
        }
    }
}
