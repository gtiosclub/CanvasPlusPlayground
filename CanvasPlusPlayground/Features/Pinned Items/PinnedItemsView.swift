//
//  PinnedItemsView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 1/8/25.
//

import SwiftUI

struct PinnedItemsView: View {
    @Environment(PinnedItemsManager.self) private var pinnedItemsManager

    var body: some View {
        List(pinnedItemsManager.pinnedItems) { item in
            AsyncView {
                await item.itemData()
            } content: { itemData in
                switch itemData {
                case .announcement(let announcement):
                    PinnedAnnouncementCard(announcement: announcement)
                default: Text("Got \(itemData)")
                }
            } placeholder: {
                Text("Loading...")
            }
        }
        #if os(macOS)
        .navigationSplitViewColumnWidth(min: 350, ideal: 400)
        #endif
    }
}

struct PinnedAnnouncementCard: View {
    let announcement: Announcement

    var body: some View {
        VStack(alignment: .leading) {
            Text(announcement.title ?? "")
                .font(.headline)
                .bold()
            Text(
                announcement.message?
                    .stripHTML()
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                ?? ""
            )
            .font(.body)
            .lineLimit(2)
        }
    }
}
