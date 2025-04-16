//
//  IntelligentGradeCalculatorSetupView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 3/29/25.
//

import SwiftUI

struct IGCSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(NavigationModel.self) private var navigationModel

    let course: Course

    @State private var selectedFile: (any PickableItem)?
    @State private var showingParserView = false

    var body: some View {
        @Bindable var navigationModel = navigationModel

        NavigationStack {
            VStack(alignment: .center, spacing: 24) {
                Spacer()

                VStack(alignment: .center, spacing: 8) {
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
                }

                if let selectedFile {
                    Text("Selected File: \(selectedFile.itemTitle)")
                        .foregroundStyle(.secondary)
                }

                Button("Select File...") {
                    navigationModel.selectedCourseForItemPicker = course
                }
                .bold()

                Spacer()

                nextButton
            }
            .padding()
            .navigationTitle("Choose File")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .navigationDestination(isPresented: $showingParserView) {
                IGCParsingView(selectedItem: selectedFile)
            }
        }
        .sheet(item: $navigationModel.selectedCourseForItemPicker) {
            CourseItemPicker(course: $0, selectedItem: $selectedFile)
        }
    }

    private var nextButton: some View {
        Button {
            showingParserView = true
        } label: {
            Text("Next")
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .bold()
        }
        .disabled(selectedFile == nil)
        .buttonStyle(.borderedProminent)
    }

    private var descText: String {
        """
        Canvas Plus Intelligence will parse through the course's syllabus
        document and extract assignment group weights automatically. \n

        Select a file to get started.
        """
    }
}

private struct IGCParsingView: View {
    @EnvironmentObject private var llmEvaluator: LLMEvaluator
    @EnvironmentObject private var intelligenceManager: IntelligenceManager
    @Environment(GradeCalculator.self) private var gradeCalculator

    let selectedItem: (any PickableItem)?

    @State private var isEditing = false
    @State private var isLoading = false
    @State private var didExtractWeights = false
    @State private var rippleCondition = false

    @State private var showingGradeCalculator = false

    @State private var groups: [GradeCalculator.GradeGroup] = []

    var body: some View {
        Group {
            if selectedItem != nil {
                ScrollView {
                    VStack {
                        VStack(alignment: .center, spacing: 8) {
                            Image(systemName: "wand.and.sparkles")
                                .font(.largeTitle)
                                .bold()
                                .foregroundStyle(.intelligenceGradient())

                            Text("Extract Weights")
                                .font(.title)
                                .bold()
                                .fontDesign(.rounded)

                            Text("Select 'Analyze Document' to update assignment weights by analyzing the content from the selected file.")
                                .multilineTextAlignment(.center)
                        }

                        VStack(alignment: .center, spacing: 4) {
                            IntelligenceContentView(
                                rippleEffectIsEnabled: !isEditing,
                                condition: rippleCondition,
                                isOutline: true
                            ) {
                                weightsView
                            }
                            .frame(minWidth: 200)

                            Group {
                                Text("Analyzed: ") +
                                Text(didExtractWeights ? "Yes" : "No")
                                    .fontWeight(.bold)
                                    .foregroundStyle(didExtractWeights ? Color.green : Color.red)
                            }
                            .contentTransition(.numericText())
                            .animation(.default, value: didExtractWeights)
                        }

                        HStack {
                            if didExtractWeights {
                                Button(isEditing ? "Done" : "Edit") {
                                    isEditing.toggle()
                                }
                            }

                            Spacer()
                        }

                        Spacer()

                        if didExtractWeights {
                            Button {
                                showingGradeCalculator = true
                            } label: {
                                Text("View in Grade Calculator")
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 32)
                                    .bold()
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            HStack {
                                Button("Analyze Document") {
                                    Task {
                                        await extractWeights()
                                    }
                                }
                                .disabled(isLoading)

                                if isLoading {
                                    ProgressView()
                                        .controlSize(.small)
                                }
                            }
                        }
                    }
                    .padding()
                }
            } else {
                ContentUnavailableView(
                    "Item not selected",
                    systemImage: "exclamationmark.triangle.fill"
                )
            }
        }
        .onAppear {
            groups = gradeCalculator.gradeGroups
        }
        .onChange(of: groups) { old, _ in
            if !old.isEmpty {
                rippleCondition.toggle()
            }
        }
        .sheet(isPresented: $showingGradeCalculator) {
            NavigationStack {
                GradeCalculatorView(
                    gradeGroups: groups
                )
            }
            #if os(macOS)
            .frame(width: 550, height: 650)
            #endif
        }
    }

    private var weightsView: some View {
        GradeGroupWeightsView(
            groups: $groups,
            isEnabled: isEditing
        )
        .background(.intelligenceGradient().opacity(0.2))
        .shadow(radius: 6)
    }

    private func extractWeights() async {
        if let selectedItem {
            isLoading = true
            groups = await gradeCalculator
                .extractWeightsUsingFile(
                    contents: selectedItem.contents,
                    intelligenceManager: intelligenceManager,
                    llmEvaluator: llmEvaluator
                )
            isLoading = false
            didExtractWeights = true
        }
    }
}
