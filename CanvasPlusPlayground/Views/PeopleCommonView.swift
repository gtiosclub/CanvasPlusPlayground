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
    @State var commonCourses: [Course] = []
    @State private var loading: Bool = false

    var body: some View {
        List {
            Section {
                statusLabel
            }

            ForEach(commonCourses, id: \.id) { course in
                Text(course.name ?? "")
            }
        }
        .task {
            loading = true
            await peopleManager.fetchAllClassesWith(userID: user.id!) {
                commonCourses.append($0)
            }
            loading = false
        }
    }

    private var statusLabel: some View {
        HStack {
            Text("\(commonCourses.count) Common Course\(commonCourses.count == 1 ? "" : "s")")

            Spacer()

            if loading {
                ProgressView()
            }
        }
    }
}

