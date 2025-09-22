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
                .disabled(selectedCourse == nil)

                Button("Upload PDF from Disk", systemImage: "doc.richtext") {
                    showingPDFImporter = true
                }
                .disabled(selectedCourse == nil)
            }

            if let pickedItem {
                Button("Extract assignments weights") {
                    Task {
                        do {
                            intelligenceOutput = try await igcIntelligenceService?.performRequest(for: pickedItem) ?? []
                        } catch {
                            errorMessage = error.localizedDescription
                            showingErrorAlert = true
                        }
                    }
                }
                .disabled(assignmentGroups.isEmpty)
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
        .fileImporter(isPresented: $showingPDFImporter,
                      allowedContentTypes: [.pdf],
                      allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                Task {
                    do {
                        let data = try Data(contentsOf: url)
                        var extractedText = ""
                        if let pdfDocument = PDFDocument(data: data),
                           let pageCount = pdfDocument.pageCount as Int? {
                            for i in 0..<pageCount {
                                if let page = pdfDocument.page(at: i),
                                   let pageText = page.string {
                                    extractedText.append(pageText)
                                    extractedText.append("\n")
                                }
                            }
                            extractedText = extractedText.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        if extractedText.isEmpty {
                            extractedText = data.base64EncodedString()
                        }
                        let pdfItem = PDFPickableItem(fileURL: url, contents: extractedText)
                        await MainActor.run {
                            pickedItem = pdfItem
                        }
                    } catch {
                        print(error)
                    }
                }
            case .failure(_):
                // ignore error
                break
            }
        }
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
}

private struct PDFPickableItem: PickableItem, Identifiable {
    let id = UUID()
    let fileURL: URL
    let contents: String
}
#endif
