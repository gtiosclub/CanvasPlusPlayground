//
//  CourseGradeView.swift
//  CanvasPlusPlayground
//
//  Created by Songyuan Liu on 9/16/24.
//

import SwiftUI

struct CourseGradeView: View {
    @Environment(ProfileManager.self) private var profileManager
    @State private var gradesVM: GradesViewModel

    let course: Course

    init(course: Course) {
        self.course = course
        self._gradesVM = State(initialValue: GradesViewModel(courseId: course.id))
    }

    var body: some View {
        CourseAssignmentsView(course: course, showGrades: true)
            .safeAreaInset(edge: .top, spacing: 0) {
                gradesAccessoryBar
            }
            .navigationTitle("Grades")
            .task {
                await loadGrades()
            }
            .onChange(of: profileManager.currentUser) { _, _ in
                Task {
                    await loadGrades()
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
    }

    private var gradesAccessoryBar: some View {
        VStack {
            Divider()

            HStack {
                Text("Current Score")
                Spacer()
                Text(gradesVM.currentScore)
                    .animation(.default, value: gradesVM.currentScore)
                    .contentTransition(.numericText())
                    .foregroundStyle(.tint)
            }
            .fontDesign(.rounded)
            .font(.title2)
            .bold()
            .padding(.horizontal)
            .padding(.vertical, 4)

            Divider()
        }
        .frame(maxWidth: .infinity)
        .background(.bar)
    }

    private func loadGrades() async {
        await gradesVM
            .getEnrollments(currentUserID: profileManager.currentUser?.id)
    }
}
