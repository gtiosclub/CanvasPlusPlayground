//
//  LogRecentItemModifier.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/11/25.
//

import SwiftUI

struct LogRecentItemModifier: ViewModifier {
    @Environment(RecentItemsManager.self) private var recentItemsManager

    let itemID: String
    let courseID: String
    let type: RecentItemType

    func body(content: Content) -> some View {
        content
            .onAppear {
                recentItemsManager.logRecentItem(
                    itemID: itemID,
                    courseID: courseID,
                    type: type
                )
            }
    }
}

extension View {
    func logRecentItem(
        itemID: String,
        courseID: String,
        type: RecentItemType
    ) -> some View {
        modifier(LogRecentItemModifier(
            itemID: itemID,
            courseID: courseID,
            type: type
        ))
    }
}
