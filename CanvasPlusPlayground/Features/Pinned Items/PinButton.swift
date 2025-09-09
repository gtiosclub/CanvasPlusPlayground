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

    private var isItemPinned: Bool {
		guard let courseID = courseID else {return false}
		return pinnedItemsManager.isItemPinned(itemID: itemID, courseID: courseID, type: type)
        
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
