//
//  IntelligenceOnboardingView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/31/24.
//

import MLXLLM
import SwiftUI

struct IntelligenceOnboardingView: View {
    enum InstallState {
        case selectModel
        case installing
        case installed
    }

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var intelligenceManager: IntelligenceManager
    @EnvironmentObject private var llmEvaluator: LLMEvaluator

    @State private var selectedModel: ModelConfiguration?
    @State private var currentInstallState: InstallState = .selectModel

    var body: some View {
        VStack(spacing: 8) {
            Spacer()

            header

            Spacer()

            List {
                listContent
            }
            .listStyle(.plain)

            Spacer()

            if currentInstallState == .installing {
                HStack {
                    ProgressView(value: llmEvaluator.progress, total: 1)
                        .progressViewStyle(.linear)
                    ProgressView()
                }
            }
        }
        .fontDesign(.rounded)
        .padding()
        .onChange(of: llmEvaluator.progress) { _, newValue in
            if newValue == 1.0 {
                completeInstallation()
            }
        }
        .toolbar {
            if currentInstallState == .selectModel {
                #if os(macOS)
                ToolbarItem(placement: .destructiveAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: .xmarkCircleFill) {
                        dismiss()
                    }
                    .labelsHidden()
                }
                #endif

                ToolbarItem(placement: .confirmationAction) {
                    Button("Install") {
                        installModel()
                    }
                    .disabled(selectedModel == nil)
                }
            } else if currentInstallState == .installed {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minHeight: 400)
        #endif
    }

    @ViewBuilder
    private var header: some View {
        Image(systemName: .wandAndStars)
            .font(.largeTitle)
            .foregroundStyle(.tint)

        Text("Install a Model")
            .font(.largeTitle)
            .bold()

        Text(descriptionText)
            .multilineTextAlignment(.center)
    }

    @ViewBuilder
    private var listContent: some View {
        Section("Available") {
            ForEach(filteredModels, id: \.name) { model in
                Button {
                    selectedModel = model
                } label: {
                    HStack {
                        Text(intelligenceManager.modelDisplayName(model.name))
                        Spacer()
                        if selectedModel == model {
                            Image(systemName: .checkmark)
                        }
                    }
                    .contentShape(.rect)
                }
            }
        }
        .disabled(currentInstallState != .selectModel)

        if !intelligenceManager.installedModels.isEmpty {
            Section("Installed") {
                ForEach(intelligenceManager.installedModels, id: \.self) { model in
                    Button {
                        if let config = llmEvaluator.getModelByName(model) {
                            selectedModel = config
                            installModel()
                        }
                    } label: {
                        HStack {
                            Text(model)
                            Spacer()
                            if intelligenceManager.currentModelName == model {
                                Image(systemName: .checkmark)
                            }
                        }
                    }
                }
            }
        }
    }

    private func installModel() {
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = true
        #endif

        Task {
            if let selectedModel {
                currentInstallState = .installing
                await llmEvaluator.switchModel(selectedModel)
            }
        }
    }

    private func completeInstallation() {
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = false
        #endif

        if let selectedModel {
            intelligenceManager.currentModelName = selectedModel.name
            intelligenceManager.addInstalledModel(selectedModel.name)
        }

        currentInstallState = .installed
    }

    private var filteredModels: [ModelConfiguration] {
        ModelConfiguration.availableModels
            .filter { !intelligenceManager.installedModels.contains($0.name) }
            .sorted { $0.name < $1.name }
    }

    private var descriptionText: String {
        let modelName = intelligenceManager.modelDisplayName(selectedModel?.name ?? "")

        return switch currentInstallState {
        case .selectModel:
            "Choose a model to install and use for summarization and other intelligence features."
        case .installing:
            "Installing \(modelName)"
        case .installed:
            "Installed \(modelName)"
        }
    }
}

#Preview {
    NavigationStack {
        IntelligenceOnboardingView()
    }
        .environmentObject(IntelligenceManager())
        .environmentObject(LLMEvaluator())
}
