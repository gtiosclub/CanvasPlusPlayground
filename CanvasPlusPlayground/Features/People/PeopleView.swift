//
//  PeopleView.swift
//  CanvasPlusPlayground
//
//  Created by Max Ko on 9/22/24.
//

import SwiftUI

struct PeopleView: View {
    struct Token: Identifiable, Equatable {
        let id = UUID()
        let category: EnrollmentType
    }

    let courseID: String?

    @State private var peopleManager: PeopleManager
    @State private var selectedTokens: [Token] = []
    @State private var searchText: String = ""

    @State private var selectedUser: User?

    @State private var currentSearchTask: Task<Void, Never>?

    private var suggestedTokens: [Token] {
        EnrollmentType.allCases
            .map { Token(category: $0) }
            .sorted { $0.category.displayName < $1.category.displayName }
    }

    init(courseID: String?) {
        self.courseID = courseID
        self.peopleManager = PeopleManager(courseID: courseID)
    }

    var body: some View {
        NavigationStack {
            mainBody
        }
        .refreshable {
            currentSearchTask?.cancel()
            await newQuery() // don't use `newQueryAsync` to allow the refresh animation to persist until query finished
        }
        .sheet(item: $selectedUser) { user in
            NavigationStack {
                ProfileView(user: user)
            }
        }
    }

    private var mainBody: some View {
        SearchResultsListView(
            dataSource: peopleManager
        ) {
            ForEach(peopleManager.displayedUsers, id: \.id) { user in
                UserCell(user: user, selectedUser: $selectedUser)
            }
        }
        .navigationTitle("People")
        #if os(iOS)
        .searchable(
            text: $searchText,
            tokens: $selectedTokens,
            suggestedTokens: .constant(suggestedTokens),
            placement:
                    .navigationBarDrawer(
                        displayMode: .always
                    ),
            prompt: "Search People..."
        ) { token in
            Label(token.category.displayName, systemImage: "person.fill")
        }
        #else
        .searchable(
            text: $searchText,
            tokens: $selectedTokens,
            suggestedTokens: .constant(suggestedTokens),
            prompt: "Search People..."
        ) { token in
            Label(token.category.displayName, systemImage: "person.fill")
        }
        #endif
        .overlay {
            noResultsBanner
        }
        .onChange(of: searchText) { _, _ in
            newQueryAsync()
        }
        .onChange(of: selectedTokens) { _, _ in
            newQueryAsync()
        }
    }

    @ViewBuilder
    var noResultsBanner: some View {
        if peopleManager.loadingState != .loading {
            if !searchText.isEmpty && peopleManager.displayedUsers.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else if peopleManager.displayedUsers.isEmpty {
                ContentUnavailableView("Failed to fetch people", systemImage: "exclamationmark.triangle.fill")
            }
        }
    }

    private func newQuery() async {
        peopleManager.page = 1
        peopleManager.queryMode = .live
        peopleManager.searchText = searchText
        peopleManager.selectedRoles = selectedTokens.map(\.category)
        await peopleManager.fetchNextPage()
    }

    private func newQueryAsync() {
        currentSearchTask?.cancel()
        currentSearchTask = Task {
            await newQuery()
        }
    }
}

private struct UserCell: View {
    let user: User
    @Binding var selectedUser: User?

    var body: some View {
        HStack {
            ProfilePicture(user: user)
                .frame(width: 35, height: 35)

            VStack(alignment: .leading) {
                Text(user.name)
                Text(
                    user.enrollmentRoles
                        .map(\.displayName)
                        .joined(separator: ", ")
                )
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                selectedUser = user
            } label: {
                Image(systemName: "info.circle")
            }
        }
    }
}

#Preview {
    PeopleView(courseID: "409318")
}
