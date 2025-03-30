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
                        // TODO: indicate unknown status in UI (perhaps triangle with !, clicking on it shows subtle popover with error message
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
        VStack(spacing: 0){
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
        }
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

#Preview {
    GroupsListView(groups: [.sample, .sample])
}
