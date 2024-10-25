//
//  PeopleView.swift
//  CanvasPlusPlayground
//
//  Created by Max Ko on 9/22/24.
//

import SwiftUI

struct PeopleView: View {
    let courseID: Int?
    @State private var peopleManager: PeopleManager
    
    init(courseID: Int?) {
        self.courseID = courseID
        self.peopleManager = PeopleManager(courseID: courseID)
    }
    
    var body: some View {
        @Bindable var peopleManager = peopleManager

        NavigationStack {
            mainBody
        }
        .task {
            await peopleManager.fetchCurrentCoursePeople()
        }
        .refreshable {
            await peopleManager.fetchCurrentCoursePeople()
        }
    }
    
    private var mainBody: some View {
        List(peopleManager.users, id: \.id) { user in
            NavigationLink(user.name ?? "", value: user)
        }
        .navigationTitle("People")
        .navigationDestination(for: User.self) { user in
            PeopleCommonView(user: user).environment(peopleManager)
        }
    }
}

#Preview {
    PeopleView(courseID: 409318)
}
