//
//  GroupsListView.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 3/23/25.
//

import SwiftUI

struct GroupsListView: View {
    let groups: [CanvasGroup]

    var body: some View {
        List(groups) { group in
            GroupRowView(group: group)
                .onAppear {
                    // TODO: fetch current user membership status
                }
        }
    }
}

struct GroupRowView: View {
    let group: CanvasGroup

    var body: some View {
        VStack {
            HStack {
                Text(group.name + " (\(group.groupCategoryName ?? "Unknown Category"))")
                    .font(.title)

                Spacer()

                Text("\(group.membersCount)/\(group.groupLimit)" )
            }
            Text((group.users ?? []).map { $0.name }.joined(separator: ", "))
                .font(.caption)
        }
    }
}
