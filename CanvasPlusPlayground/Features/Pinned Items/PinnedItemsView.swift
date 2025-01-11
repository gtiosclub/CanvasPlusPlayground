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
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(pinnedItemsManager.pinnedItemsByType[type] ?? []) { item in
                            PinnedItemCard(item: item)
                        }
                    }
                }
                .scrollTargetBehavior(.paging)
                .listRowSeparator(.hidden)

            } header: {
                Text(type.displayName)
                    .font(.title)
                    .fontDesign(.rounded)
                    .foregroundStyle(.tint)
                    .bold()
            }

        }
        #if os(macOS)
        .navigationSplitViewColumnWidth(min: 350, ideal: 400)
        #endif
    }
}

struct PinnedItemCard: View {
    let item: PinnedItem

    var body: some View {
        AsyncView {
            await item.itemData()
        } content: { itemData in
            switch itemData.modelData {
            case .announcement(let announcement):
                PinnedAnnouncementCard(
                    announcement: announcement,
                    course: itemData.course
                )
            default: Text("Got \(itemData)")
            }
        } placeholder: {
            Text("Loading...")
        }
    }
}

struct PinnedAnnouncementCard: View {
    let announcement: Announcement
    let course: Course

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(course.displayName.uppercased())
                .font(.caption)
                .foregroundStyle(course.rgbColors?.color ?? .accentColor)

            VStack(alignment: .leading, spacing: 3) {
                Text(announcement.title ?? "")
                    .font(.headline)
                    .fontDesign(.rounded)
                    .bold()

                Text(
                    announcement.message?
                        .stripHTML()
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                    ?? ""
                )
                .lineLimit(2)
            }
        }
        .frame(width: 250)
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 16.0)
                .fill(.secondary.opacity(0.3))
        }
    }
}
