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
    }

    private var mainBody: some View {
        SearchResultsListView(dataSource: peopleManager) {
            ForEach(peopleManager.displayedUsers, id: \.id) { user in
                UserCell(for: user)
            }
        }
        .navigationTitle("People")
        .navigationDestination(for: User.self) { user in
            PeopleCommonView(user: user).environment(peopleManager)
        }
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
        .toolbar {
            Button("Reload", systemImage: "arrow.clockwise.circle") {
                currentSearchTask?.cancel()
                peopleManager.users = Set()
                peopleManager.loadingState = .loading
                currentSearchTask = Task {
                    newQueryAsync()
                }
            }
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

    static let height: CGFloat = 25 // Only works on MacOS

    init(for user: User) {
        self.user = user
    }

    var body: some View {
        NavigationLink(value: user) {
            HStack {
                Text(user.name)
                    .font(.headline)
                Spacer()
                Text(
                    user.enrollmentRoles
                        .map(\.displayName)
                        .joined(separator: ", ")
                )
                .foregroundStyle(.secondary)
            }
        }
        .frame(height: Self.height)
    }
}

#Preview {
    PeopleView(courseID: "409318")
}
