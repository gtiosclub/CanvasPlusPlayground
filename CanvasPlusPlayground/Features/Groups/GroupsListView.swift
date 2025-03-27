//
//  GroupsListView.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 3/23/25.
//

import SwiftUI

struct GroupsListView: View {
    let groups: [CanvasGroup]

    @State private var selectedGroupDetail: CanvasGroup?

    var body: some View {
        List(groups) { group in
            GroupRowView(group: group, selectedGroupDetail: $selectedGroupDetail)
                .onAppear {
                    // TODO: fetch and set current user membership status
                }
        }
        .sheet(item: $selectedGroupDetail) { group in
            NavigationStack {
                groupDetail(for: group)
                    .navigationTitle("Details")
            }
            .frame(minHeight: 600)
        }
    }

    @ViewBuilder
    func groupDetail(for group: CanvasGroup) -> some View {
#if os(macOS)
        GroupDetailView(group: group)

        Divider()

        HStack {
            Spacer()
            Button("Done") {
                selectedGroupDetail = nil
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.extraLarge)
            .keyboardShortcut(.return)
        }
        .padding()
#else
        GroupDetailView(group: group)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        selectedGroupDetail = nil
                    }
                }
            }
#endif
    }
}

struct GroupRowView: View {
    let group: CanvasGroup
    @Binding var selectedGroupDetail: CanvasGroup?

    var membersLimit: String {
        group.groupLimit == .max ? "∞" : String(group.groupLimit)
    }

    var body: some View {
        VStack {
            HStack {
                Text(group.name)
                    .font(.headline)

                numMembersLabel
                moreDetailsButton

                Spacer()

                if let action = group.availableAction {
                    groupActionButton(for: action)
                } else {
                    lockStatusLabel
                }
            }
            .font(.subheadline)
        }
    }

    var moreDetailsButton: some View {
        Button {
            selectedGroupDetail = group
        } label: {
            Image(systemName: .infoCircle)
        }
        .buttonStyle(.plain)
#if os(macOS)
        .foregroundStyle(.secondary)
#else
        .foregroundStyle(.blue)
#endif
    }

    var numMembersLabel: some View {
        Text("\(group.membersCount)/\(membersLimit)" )
            .foregroundStyle(.secondary)
    }

    var categoryLabel: some View {
        Text(group.groupCategoryName ?? "Unknown Category")
    }

    var lockStatusLabel: Image {
#if os(macOS)
        Image(systemName: .lock)
#else
        Image(systemName: .lockFilled)
#endif
    }

    func groupActionButton(for action: GroupAction) -> some View {
        Button("Join") {
            // TODO: join/leave action here
            switch action {
            case .join:
                break
            case .leave:
                break
            case .cancelRequest:
                break
            case .accept:
                break
            }
        }
    }
}

#Preview {
    GroupsListView(groups: [.sample, .sample])
}
