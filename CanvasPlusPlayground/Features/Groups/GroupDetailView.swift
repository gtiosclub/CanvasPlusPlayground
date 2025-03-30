//
//  GroupDetailView.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 3/24/25.
//

import SwiftUI

struct GroupDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let group: CanvasGroup

    var body: some View {
        List {
#if DEBUG
            Section(header: Text("Course Information")) {
                row(label: "ID", value: group.id)
                row(label: "Name", value: group.name)
                row(label: "Concluded?", value: group.concluded.description)
                row(label: "Members Count", value: group.membersCount.asString)
                row(label: "Course ID", value: group.courseId?.asString ?? "N/A")
                row(label: "Group Category ID", value: group.groupCategoryId?.asString ?? "N/A")
                row(label: "Group Category Name", value: group.groupCategoryName ?? "N/A")
                row(label: "Group Limit", value: group.groupLimit.asString)
                row(label: "Category Allows Multiple Memberships?", value: group.allowsMultipleMemberships?.description ?? "N/A")
                row(label: "Storage Quota (MB)", value: group.storageQuotaMb?.asString ?? "N/A")
                row(label: "Is Public?", value: group.isPublic.description)
                row(label: "Membership Status", value: group.currUserStatus?.rawValue ?? "No status (probs not a member)")
            }

            Section(header: Text("Description")) {
                Text(group.groupDescription ?? "N/A")
            }

            Section(header: Text("Permissions")) {
                row(label: "Can create discussion?", value: group.canCreateDiscussionTopic?.description ?? "N/A")
                row(label: "Can join?", value: group.canJoin?.description ?? "N/A")
                row(label: "Can create announcement?", value: group.canCreateAnnouncement?.description ?? "N/A")
            }
#endif

            Section(header: Text("Users")) {
                ForEach(group.users ?? []) {
                    row(label: $0.id.asString, value: $0.name)
                }
            }
        }
#if os(iOS)
        .listStyle(.insetGrouped)
#else
        .listStyle(.sidebar)
#endif
    }

    func row(label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    GroupDetailView(group: .sample)
}
