//
//  PeopleCommonView.swift
//  CanvasPlusPlayground
//
//  Created by Max Ko on 10/2/24.
//

import SwiftUI

struct PeopleCommonView: View {
    @Environment(PeopleManager.self) var peopleManager
    @Environment(CourseManager.self) var courseManager
    let user: UserAPI

    @State private var commonCourses: [Course] = []
    @State private var fetchingCommonCourses: Bool = false

    var body: some View {
        Form {
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
        guard let id = user.id else { return }

        fetchingCommonCourses = true
        await peopleManager
            .fetchAllClassesWith(
                userID: id,
                activeCourses: courseManager.courses
            ) {
            commonCourses.append($0)
        }
        fetchingCommonCourses = false
    }
}

