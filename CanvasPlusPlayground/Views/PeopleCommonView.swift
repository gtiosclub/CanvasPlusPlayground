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

    @State private var commonCourses: [Course] = []
    @State private var fetchingCommonCourses: Bool = false

    var body: some View {
        Form {
            Section {
                statusLabel
            }

            Section {
                ForEach(commonCourses, id: \.id) { course in
                    Text(course.name ?? "")
                }
            } footer: {
                if fetchingCommonCourses {
                    HStack {
                        Text("Results may be incomplete...")

                        Spacer()

                        ProgressView()
                            .controlSize(.small)
                    }
                    .foregroundStyle(.secondary)
                    .font(.caption)
                }
            }
        }
        .formStyle(.grouped)
        .task {
            await getCommonCourses()
        }
        .animation(.default, value: commonCourses)
    }

    private var statusLabel: some View {
        HStack {
            Text("Common Courses")

            Spacer()

            Text("\(commonCourses.count)")
                .bold()
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
        }
    }

    private func getCommonCourses() async {
        fetchingCommonCourses = true
        await peopleManager.fetchAllClassesWith(userID: user.id!) {
            if !commonCourses.contains($0) {
                commonCourses.append($0)
            }
        }
        fetchingCommonCourses = false
    }
}

