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
                CourseAnnouncementDetailView(announcement: announcement)
            case .file(let file):
                Text("file")
            case .assignment(let assignment):
                AssignmentDetailView(assignment: assignment)
            }
        } placeholder: {
            Text("Loading...")
        }
        .id(item.id)
    }
}
