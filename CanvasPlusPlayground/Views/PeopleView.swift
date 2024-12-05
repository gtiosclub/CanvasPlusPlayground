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
            await peopleManager.fetchPeople()
        }
        .refreshable {
            await peopleManager.fetchPeople()
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

    private var displayedUsers: [User] {
        var result = peopleManager.users
        if !searchText.isEmpty {
            result = result.filter {
                $0.name?.localizedCaseInsensitiveContains(searchText) ?? true
            }
        }

        selectedTokens.forEach { token in
            result = result.filter {
                $0.role?.contains(token.text) ?? true
            }
        }

        return result
    }
}

#Preview {
    PeopleView(courseID: "409318")
}
