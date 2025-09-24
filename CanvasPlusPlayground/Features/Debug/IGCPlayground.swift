//
//  IGCPlayground.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 8/16/25.
//

#if DEBUG
import SwiftUI
import UniformTypeIdentifiers
import PDFKit

@available(iOS 26.0, macOS 26.0, *)
struct IGCPlayground: View {
    static let windowID = "com.CanvasPlus.IGCPlayground"
    @Environment(CourseManager.self) var courseManager

    @State private var selectedCourse: Course?

    @State private var showingPicker = false
    @State private var pickedItem: (any PickableItem)?
    @State private var assignmentGroups: [AssignmentGroup] = []
    @State private var igcIntelligenceService: GradeCalculatorIntelligenceService?
    @State private var intelligenceOutput = [GradeCalculatorIntelligenceServiceResult]()

    @State private var showingPDFImporter = false

    @State private var errorMessage: String? = nil
    @State private var showingErrorAlert = false
    @State private var isLoading = false

    var body: some View {
        Form {
            Section("Select Course") {
                Picker("Course", selection: $selectedCourse) {
                    ForEach(courseManager.activeCourses) { course in
                        Text(course.displayName).tag(course)
                    }
                }
            }

            Section("Select Syllabus file") {
                Button("Pick an item", systemImage: "filemenu.and.selection") {
                    showingPicker.toggle()
                }

                Button("Upload PDF from Disk", systemImage: "doc.richtext") {
                    showingPDFImporter = true
                }
            }
            .disabled(selectedCourse == nil)

            HStack {
                Button("Extract assignments weights") {
                    Task {
                        isLoading = true
                        await extractWeights()
                        isLoading = false
                    }
                }
                .disabled(pickedItem == nil)
                .disabled(isLoading)

                Spacer()

                if isLoading {
                    ProgressView().controlSize(.small)
                }
            }

            Section("Intelligence Output") {
                ForEach(intelligenceOutput) { output in
                    VStack(alignment: .leading) {
                        Text("id: \(output.id)")
                        Text("name: \(output.name)")
                        Text("Weight: \(output.weight)")
                    }
                }
            }
        }
        .formStyle(.grouped)
        .sheet(isPresented: $showingPicker) {
            if let selectedCourse {
                CourseItemPicker(
                    course: selectedCourse,
                    selectedItem: $pickedItem
                )
            } else {
                Text("No course selected")
                Button("Done") { showingPicker = false }
            }
        }
        .pickableFileImporter(
            isPresented: $showingPDFImporter,
            pickedItem: $pickedItem
        )
        .task(id: selectedCourse) {
            if let selectedCourse {
                let assignmentsManager = CourseAssignmentManager(
                    courseID: selectedCourse.id)
                await assignmentsManager.fetchAssignmentGroups()
                assignmentGroups = assignmentsManager.assignmentGroups
            }
        }
        .task(id: assignmentGroups) {
            igcIntelligenceService = .init(
                groups: GradeCalculator(
                    assignmentGroups: assignmentGroups
                ).gradeGroups
            )
        }
        .alert("Error", isPresented: $showingErrorAlert, actions: {
            Button("OK", role: .cancel) {}
        }, message: {
            Text(errorMessage ?? "Unknown error")
        })
    }

    private func extractWeights() async {
        guard let pickedItem else { return }

        do {
            intelligenceOutput = try await igcIntelligenceService?.performRequest(for: pickedItem) ?? []
        } catch {
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
    }
}
#endif
