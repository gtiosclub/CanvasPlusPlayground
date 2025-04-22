//
//  IGCParsingView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 4/21/25.
//

import SwiftUI

struct IGCParsingView: View {
    @EnvironmentObject private var llmEvaluator: LLMEvaluator
    @EnvironmentObject private var intelligenceManager: IntelligenceManager
    @Environment(GradeCalculator.self) private var gradeCalculator
    @Environment(\.dismiss) private var dismiss

    let selectedItem: (any PickableItem)?

    @State private var isEditing = false
    @State private var isLoading = false
    @State private var didExtractWeights = false
    @State private var rippleCondition = false
    @State private var showCompletionAlert = false
    @State private var groups: [GradeCalculator.GradeGroup] = []

    var body: some View {
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

                Text("Select 'Analyze' to update assignment weights by analyzing the content from the selected file.")
                    .multilineTextAlignment(.center)

                if let selectedItem {
                    Text("Selected File: \(selectedItem.itemTitle)")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 6)

            VStack(alignment: .center, spacing: 4) {
                analyzeStatusText

                IntelligenceContentView(
                    rippleEffectIsEnabled: !isEditing,
                    condition: rippleCondition,
                    isOutline: true
                ) {
                    weightsView
                }
                .frame(minWidth: 200)
                .padding(.bottom)

                if didExtractWeights {
                    HStack {
                        Button(isEditing ? "Done" : "Edit") {
                            isEditing.toggle()
                        }

                        Spacer()
                    }
                }
            }

            analyzeButton
        }
        .padding()
        .onAppear {
            groups = gradeCalculator.gradeGroups
        }
        .onChange(of: groups) { old, _ in
            if !old.isEmpty {
                rippleCondition.toggle()
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if didExtractWeights {
                    Button("Done") {
                        showCompletionAlert = true
                    }
                    .disabled(isLoading)
                }
            }
        }
        .alert(
            "Extracted Weights",
            isPresented: $showCompletionAlert) {
                Button("Done") {
                    dismiss()
                }

                Button("Open Grade Calculator", role: .cancel) {
                    // TODO: Open Grade Calc
                }
            } message: {
                Text("The extracted weights have been successfully saved! You can access them using the Grade Calculator at any time.")
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

    private var analyzeStatusText: some View {
        Group {
            Text("Analyzed: ") +
            Text(didExtractWeights ? "Yes" : "No")
                .fontWeight(.bold)
                .foregroundStyle(didExtractWeights ? Color.green : Color.red)
        }
        .contentTransition(.numericText())
        .animation(.default, value: didExtractWeights)
        .padding(.bottom)
    }

    private var analyzeButton: some View {
        HStack {
            Spacer()

            if isLoading {
                ProgressView()
                    .controlSize(.small)
            }

            Button("Analyze") {
                Task {
                    await extractWeights()
                }
            }
            .bold()
            .disabled(isLoading)
        }
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
