//
//  GroupsListView.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 3/23/25.
//

import SwiftUI

struct GroupsListView: View {
    @Environment(CourseGroupsViewModel.self) private var courseGroupsVM

    @State private var selectedGroupDetail: CanvasGroup?

    var body: some View {
        List(courseGroupsVM.groupsDisplayed) { group in
            GroupRowView(group: group, selectedGroupDetail: $selectedGroupDetail)
                .frame(height: 40)
                .task {
                    do {
                        try await group.fetchMembershipState()
                    } catch {
                        // TODO: indicate unknown status in UI (perhaps triangle with !, clicking on it shows subtle popover with error message
                    }
                }
        }
        .sheet(item: $selectedGroupDetail) { group in
            NavigationStack {
                groupDetail(for: group)
                    .navigationTitle("Details")
            }
            .frame(height: 600)
        }
    }

    @ViewBuilder
    func groupDetail(for group: CanvasGroup) -> some View {
        GroupDetailView(group: group)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        selectedGroupDetail = nil
                    }
                }
            }
    }
}

#Preview {
    var courseGroupVM = {
        let vm = CourseGroupsViewModel()
        vm.groups = [.sample, .sample]
        return vm
    }()

    GroupsListView()
        .environment(courseGroupVM)
}
