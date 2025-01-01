//
//  PeopleView.swift
//  CanvasPlusPlayground
//
//  Created by Max Ko on 9/22/24.
//

import SwiftUI

struct Token: Identifiable {
    let id = UUID()
    let text: String
}

struct PeopleView: View {
    let courseID: String?

    @State private var peopleManager: PeopleManager
    @State private var searchText: String = ""
    @State private var selectedTokens = [Token]()

    @State private var isLoadingPeople = true

    private var suggestedTokens: [Token] {
        Set(peopleManager.users.compactMap(\.role)).map { Token(text: $0) }
            .sorted { $0.text < $1.text }
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
                    Text(user.name ?? "")
                    Spacer()
                    Text(user.role ?? "nil")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("People")
        .navigationDestination(for: UserAPI.self) { user in
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
            Label(token.text, systemImage: "person.fill")
        }
        #else
        .searchable(
            text: $searchText,
            tokens: $selectedTokens,
            suggestedTokens: .constant(suggestedTokens),
            prompt: "Search People..."
        ) { token in
            Label(token.text, systemImage: "person.fill")
        }
        #endif
        .overlay {
            if !searchText.isEmpty && displayedUsers.isEmpty {
                ContentUnavailableView("No results for '\(searchText)'", systemImage: "magnifyingglass")
            }
        }
    }

    private var displayedUsers: [UserAPI] {

        return peopleManager.users.filter { user in
            let matchesSearchText = searchText.isEmpty || user.name?.localizedCaseInsensitiveContains(searchText) ?? true

            let matchesSelectedTokens = selectedTokens.allSatisfy { token in
                user.role?.contains(token.text) ?? false
            }

            return matchesSearchText && matchesSelectedTokens
        }
    }

    private func loadPeople() async {
        isLoadingPeople = true
        await peopleManager.fetchPeople()
        isLoadingPeople = false
    }
}

#Preview {
    PeopleView(courseID: "409318")
}
