//
//  PeopleView.swift
//  CanvasPlusPlayground
//
//  Created by Max Ko on 9/22/24.
//

import SwiftUI

struct PeopleView: View {
    let courseID: String?

    @State private var peopleManager: PeopleManager
    @State private var searchText: String = ""

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
            NavigationLink(user.name ?? "", value: user)
        }
        .navigationTitle("People")
        .navigationDestination(for: User.self) { user in
            PeopleCommonView(user: user).environment(peopleManager)
        }
        #if os(iOS)
        .searchable(
            text: $searchText,
            placement:
                    .navigationBarDrawer(
                        displayMode: .always
                    )
            ,
            prompt: "Search People..."
        )
        #else
        .searchable(text: $searchText, prompt: "Search People...")
        #endif
    }

    private var displayedUsers: [User] {
        searchText.isEmpty ?
        peopleManager.users :
        peopleManager.users
            .filter {
                $0.name?.localizedCaseInsensitiveContains(searchText) ?? true
            }
    }
}

#Preview {
    PeopleView(courseID: "409318")
}
