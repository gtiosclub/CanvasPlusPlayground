//
//  IGCSetupView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 4/22/25.
//

import SwiftUI

struct IGCSetupView: View {
    @Environment(\.dismiss) private var dismiss

    enum IGCPhase {
        case pickFile
        case parseFile
    }

    let course: Course

    @State private var currentPhase: IGCPhase = .pickFile
    @State private var selectedFile: (any PickableItem)?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    Image(systemName: "plus.slash.minus")
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(.intelligenceGradient())

                    Text("Intelligent Grade Calculator")
                        .font(.title)
                        .bold()
                        .fontDesign(.rounded)

                    Text(descText)
                        .multilineTextAlignment(.center)
                    
                    pickFileCell
                    parseFileCell
                }
                .padding()
            }
            .animation(.default, value: currentPhase)
            .navigationTitle("Intelligent Grade Calculator")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var pickFileCell: some View {
        IGCSetupViewCell(
            title: "Pick File",
            icon: "document",
            isExpanded: currentPhase == .pickFile) {
                IGCFilePickerView(
                    course: course,
                    selectedFile: $selectedFile
                ) {
                    currentPhase = .parseFile
                }
            }
    }

    private var parseFileCell: some View {
        IGCSetupViewCell(
            title: "Parse File",
            icon: "wand.and.sparkles.inverse",
            isExpanded: currentPhase == .parseFile) {
                IGCParsingView(selectedItem: selectedFile)
            }
    }

    private var descText: String {
        """
        Canvas Plus Intelligence will parse through the course's syllabus
        document and extract assignment group weights automatically. \n
        """
    }
}

private struct IGCSetupViewCell<Content: View>: View {
    let title: String
    let icon: String
    let isExpanded: Bool
    let content: Content

    init(
        title: String,
        icon: String,
        isExpanded: Bool,
        content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.isExpanded = isExpanded
        self.content = content()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16.0)
                .fill(.background.secondary)

            VStack(spacing: 8) {
                header

                if isExpanded {
                    content
                }
            }
        }
        .fixedSize(horizontal: false, vertical: !isExpanded)
    }

    private var header: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)

            Text(title)
                .font(.headline)
                .fontDesign(.rounded)

            Spacer()
        }
        .bold()
        .foregroundStyle(isExpanded ? .primary : .secondary)
        .padding()
        .contentShape(.rect)
    }
}
