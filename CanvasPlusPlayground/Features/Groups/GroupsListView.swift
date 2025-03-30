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
                .frame(height: 40)
                .task {
                    do {
                        try await group.fetchMembershipState()
                    } catch {
                        // TODO: indicate unknown status in UI
                    }
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
    @Environment(CourseGroupsViewModel.self) private var courseGroupsVM

    let group: CanvasGroup
    @Binding var selectedGroupDetail: CanvasGroup?

    @State private var error: Error?
    private var showError: Binding<Bool> {
        Binding {
            error != nil
        } set: { showErrorNew in
            if !showErrorNew { error = nil }
        }
    }

    var membersLimit: String {
        group.groupLimit == .max ? "∞" : String(group.groupLimit)
    }

    var body: some View {
        HStack {
            Text(group.name)

            numMembersLabel
                .font(.subheadline)

            moreDetailsButton

            Spacer()

            if group.isLoadingMembership {
                ProgressView()
            } else if let action = group.availableAction {
                groupActionButton(for: action)
                    .font(.subheadline)
            } else {
                lockStatusLabel
            }
        }
        .font(.headline)
        .alert("Failure", isPresented: showError) {
            Button("Ok", role: .cancel) {
                error = nil
            }
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
        Text("(\(group.membersCount)/\(membersLimit))" )
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
        let label = if action == .join {
            courseGroupsVM.canOnlySwitch(to: group) ? "Switch to" : action.label
        } else { action.label }

        return Button(label) {
            Task {
                await groupAction(action)
            }
        }
    }

    func groupAction(_ action: GroupAction) async {
        do {
            switch action {
            case .join:
                // TODO: must update existing groups upon success
                try await group.joinGroup()
                if let categoryId = group.groupCategoryId {
                    try await courseGroupsVM.fetchAllGroupMembershipsFor(
                        categoryId: categoryId,
                        excluding: group.id
                    )
                }
            case .leave:
                try await group.leaveGroup()
            case .cancelRequest:
                // TODO: action here
                break
            case .accept:
                try await group.acceptInvite()
            }
        } catch {
            self.error = error
        }
    }
}

#Preview {
    GroupsListView(groups: [.sample, .sample])
}
