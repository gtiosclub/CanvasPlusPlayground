//
//  IntelligentGradeCalculatorSetupView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 3/29/25.
//

import SwiftUI

struct IGCFilePickerView: View {
    @Environment(NavigationModel.self) private var navigationModel

    let course: Course
    @Binding var selectedFile: (any PickableItem)?
    let onCompletion: () -> Void

    var body: some View {
        @Bindable var navigationModel = navigationModel

        VStack(alignment: .center, spacing: 24) {
            Text("Select a syllabus file to get started...")
                .multilineTextAlignment(.center)

            if let selectedFile {
                Text("Selected File: \(selectedFile.itemTitle)")
                    .foregroundStyle(.secondary)
            }

            Button("Select File...") {
                navigationModel.selectedCourseForItemPicker = course
            }

            Spacer()

            nextButton
        }
        .padding()
        .sheet(item: $navigationModel.selectedCourseForItemPicker) {
            CourseItemPicker(course: $0, selectedItem: $selectedFile)
        }
    }


    private var nextButton: some View {
        HStack {
            Spacer()

            Button("Continue") {
                onCompletion()
            }
            .disabled(selectedFile == nil)
        }
    }
}
