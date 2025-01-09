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
                Text("Got Data: \(itemData)")
            } placeholder: {
                Text("Loading...")
            }
        }
    }
}
