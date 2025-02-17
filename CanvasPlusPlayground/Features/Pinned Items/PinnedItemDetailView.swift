//
//  PinnedItemDetailView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 2/16/25.
//

import SwiftUI

struct PinnedItemDetailView: View {
    let item: PinnedItem

    var body: some View {
        AsyncView {
            await item.itemData()
        } content: { itemData in
            switch itemData.modelData {
            case .announcement(let announcement):
                Text("Announcement: \(announcement.title)")
            case .file(let file):
                Text("File: \(file.displayName)")
            case .assignment(let assignment):
                Text("Assignment: \(assignment.name)")
            }
        } placeholder: {
            Text("Loading...")
        }
        .buttonStyle(.plain)
    }
}
