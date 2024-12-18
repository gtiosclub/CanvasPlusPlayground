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
        Form {
            Section {
                GradeRow("Current Score", value: gradesVM.currentScore)
                GradeRow("Current Grade", value: gradesVM.currentGrade)
                GradeRow("Final Score", value: gradesVM.finalScore)
                GradeRow("Final Grade", value: gradesVM.finalGrade)
            } header: {
                Text("Grades")
            } footer: {
                Group {
                    if let url = gradesVM.canvasURL {
                        Link("View on Canvas", destination: url)
                    } else {
                        Text("Loading grades...")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.footnote)
            }

            Section("Assignments") {
                CourseAssignmentsView(course: course, showGrades: true)
            }
        }
        .formStyle(.grouped)
        .task {
            await loadGrades()
        }
        .onChange(of: profileManager.currentUser) { _, _ in
            Task {
                await loadGrades()
            }
        }
        .navigationTitle("Grades")
    }
    
    private func GradeRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)

            Spacer()

            Text(value)
        }
        .contentTransition(.numericText())
        .animation(.default, value: value)
    }

    private func loadGrades() async {
        await gradesVM
            .getEnrollments(currentUserID: profileManager.currentUser?.id)
    }
}

