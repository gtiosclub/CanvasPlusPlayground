//
//  PeopleView.swift
//  CanvasPlusPlayground
//
//  Created by Max Ko on 9/22/24.
//

import SwiftUI

private struct Token: Identifiable, Equatable {
    let id = UUID()
    let text: EnrollmentType
}

struct PeopleView: View {
    let courseID: String?

    @State private var peopleManager: PeopleManager
    @State private var searchText: String = ""
    @State private var page: Int = 1 // 1-indexed
    @State private var selectedTokens = [Token]()

    @State private var isLoadingPeople = true

    private var suggestedTokens: [Token] {
        EnrollmentType.allCases
            .map { Token(text: $0) }
            .sorted { $0.text.displayName < $1.text.displayName }
    }

    init(courseID: String?) {
        self.courseID = courseID
        self.peopleManager = PeopleManager(courseID: courseID)
    }

    var body: some View {
        @Bindable var peopleManager = peopleManager

        NavigationStack {
            mainBody
        }
        .task {
            await loadPeople()
        }
        .refreshable {
            await loadPeople()
        }
    }

    private var mainBody: some View {

        List(displayedUsers, id: \.id) { user in
            NavigationLink(value: user) {
                HStack {
                    Text(user.name)
                    Spacer()
                    Text(
                        user.enrollmentRoles
                            .map(\.displayName)
                            .joined(separator: ", ")
                    )
                    .foregroundStyle(.secondary)
                }
            }
            .onAppear(perform: {
                guard let userId = peopleManager.users.last?.id, userId == user.id else {
                    return
                }

                loadNewPage()
            })
        }
        .navigationTitle("People")
        .navigationDestination(for: User.self) { user in
            PeopleCommonView(user: user).environment(peopleManager)
        }
        .statusToolbarItem("People", isVisible: isLoadingPeople)
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
            Label(token.text.displayName, systemImage: "person.fill")
        }
        #else
        .searchable(
            text: $searchText,
            tokens: $selectedTokens,
            suggestedTokens: .constant(suggestedTokens),
            prompt: "Search People..."
        ) { token in
            Label(token.text.displayName, systemImage: "person.fill")
        }
        #endif
        .overlay {
            if !searchText.isEmpty && displayedUsers.isEmpty {
                ContentUnavailableView("No results for '\(searchText)'", systemImage: "magnifyingglass")
            }
        }
        .onChange(of: searchText) { _, _ in
            newSearchQuery()
        }
        .onChange(of: selectedTokens) { _, _ in
            newSearchQuery()
        }
    }

    private var displayedUsers: [User] {

        return peopleManager.users.filter { user in
            let matchesSearchText = searchText.isEmpty || user.name.localizedCaseInsensitiveContains(searchText)

            let matchesSelectedTokens = selectedTokens.allSatisfy { token in
                user.enrollmentRoles.contains(token.text)
            }

            return matchesSearchText && matchesSelectedTokens
        }
    }

    private func loadPeople() async {
        isLoadingPeople = true
        await peopleManager.fetchPeople(
            at: page,
            searchTerm: searchText.count >= 2 ? searchText : "",
            roles: selectedTokens.map(\.text)
        )
        isLoadingPeople = false
    }

    private func newSearchQuery() {
        Task {
            page = 1
            await loadPeople()
        }
    }

    private func loadNewPage() {
        Task {
            page += 1
            await loadPeople()
        }
    }
}

#Preview {
    PeopleView(courseID: "409318")
}
