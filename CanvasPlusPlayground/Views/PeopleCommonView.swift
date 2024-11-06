//
//  PeopleCommonView.swift
//  CanvasPlusPlayground
//
//  Created by Max Ko on 10/2/24.
//

import SwiftUI

struct PeopleCommonView: View {
    @Environment(PeopleManager.self) var peopleManager
    let user: User
    @State var courses: [Course] = []
    @State private var loading: Bool = false

    var body: some View {
        List {
            Section {
                statusLabel
            }

            ForEach(courses, id: \.id) { course in
                Text(course.name ?? "")
            }
        }
        .task {
            loading = true
            self.courses = await peopleManager.fetchAllClassesWith(userID: user.id!)
            loading = false
        }
    }

    private var statusLabel: some View {
        HStack {
            Text("\(courses.count) Common Course\(courses.count == 1 ? "" : "s")")

            Spacer()

            if loading {
                ProgressView()
            }
        }
    }
}

