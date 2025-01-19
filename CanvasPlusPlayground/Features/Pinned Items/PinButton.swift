//
//  PinButton.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 1/9/25.
//

import SwiftUI

struct PinButton: View {
    @Environment(PinnedItemsManager.self) private var pinnedItemsManager

    let itemID: String
    let courseID: String?
    let type: PinnedItem.PinnedItemType

    var isItemPinned: Bool {
        pinnedItemsManager.pinnedItems.contains {
            $0.id == itemID && $0.courseID == courseID && $0.type == type
        }
    }

    var body: some View {
        Button(
            isItemPinned ? "Unpin" : "Pin",
            systemImage: isItemPinned ? "pin.slash" : "pin"
        ) {
            pinnedItemsManager
                .togglePinnedItem(
                    itemID: itemID,
                    courseID: courseID,
                    type: type
                )
        }
        .tint(.orange)
    }
}
