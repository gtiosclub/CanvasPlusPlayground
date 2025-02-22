//
//  PinnedItemDetailView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 2/16/25.
//

import SwiftUI

struct PinnedItemDetailView: View {
    let item: PinnedItem
    @State var itemData: PinnedItemData?
    var body: some View {
        Group {
            if let itemData = itemData {
                switch itemData.modelData {
                case .announcement(let announcement):
                    CourseAnnouncementDetailView(announcement: announcement)
                case .file(let file):
                    if let url = file.localURL {
                        QuickLookPreview(url: url, onDismiss: { })
                    } else {
                        ContentUnavailableView("Unable to preview file, please download first.", systemImage: "xmark.rectangle.fill")
                    }
                case .assignment(let assignment):
                    AssignmentDetailView(assignment: assignment)
                }
            } else {
                ProgressView()
            }
        }
        .id(item.id)
    }
}
