//
//  PeopleCommonView.swift
//  CanvasPlusPlayground
//
//  Created by Max Ko on 10/2/24.
//

import SwiftUI

struct PeopleCommonView: View {
    @Environment(CourseManager.self) private var courseManager
    let user: User

    @State private var commonCourses: [Course] = []
    @State private var fetchingCommonCourses: Bool = false

    var body: some View {
        Group {
            Section {
                statusLabel
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

            Section {
                ForEach(commonCourses, id: \.id) { course in
                    Text(course.displayName)
                }
            }
        }
        .formStyle(.grouped)
        .task {
            await getCommonCourses()
        }
        .animation(.default, value: commonCourses.count)
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
        let id = user.id

        fetchingCommonCourses = true
        await PeopleManager
            .fetchAllClassesWith(
                userID: id,
                activeCourses: courseManager.activeCourses
            ) {
            commonCourses.append($0)
            }
        fetchingCommonCourses = false
    }
}
