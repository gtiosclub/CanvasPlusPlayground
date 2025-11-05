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
        Group {
            if let destination = item.destination() {
                destination.destinationView()
            } else {
                ProgressView()
            }
        }
    }
}
