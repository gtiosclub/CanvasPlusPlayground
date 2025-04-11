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
        case readyToInstall
        case installing
        case installed
    }

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var intelligenceManager: IntelligenceManager
    @EnvironmentObject private var llmEvaluator: LLMEvaluator

    @State private var currentInstallState: InstallState = .readyToInstall

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            header

            Spacer()

            if currentInstallState == .installing {
                HStack {
                    ProgressView(value: llmEvaluator.progress, total: 1)
                        .progressViewStyle(.linear)

                    ProgressView()
                }
            } else if currentInstallState == .readyToInstall {
                #if os(iOS)
                installButton
                #endif
            }
        }
        .padding()
        .multilineTextAlignment(.center)
        .onAppear {
            if !intelligenceManager.installedModels.isEmpty {
                currentInstallState = .installed
            }
        }
        .onChange(of: llmEvaluator.progress) { _, newValue in
            if newValue == 1.0 {
                completeInstallation()
            }
        }
        .toolbar {
            if currentInstallState == .readyToInstall {
                #if os(macOS)
                ToolbarItem(placement: .destructiveAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark.circle.fill") {
                        dismiss()
                    }
                    .labelsHidden()
                }
                #endif

                #if os(macOS)
                ToolbarItem(placement: .confirmationAction) {
                    installButton
                }
                #endif
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
        Image(systemName: "wand.and.stars")
            .font(.system(size: 70))
            .foregroundStyle(.intelligenceGradient())

        Group {
            Text("Canvas Plus ") +
            Text("Intelligence")
                .foregroundStyle(.intelligenceGradient())
        }
        .font(.largeTitle)
        .fontDesign(.rounded)
        .bold()

        Text(descriptionText)
    }

    private var installButton: some View {
        Button {
            installModel()
        } label: {
            Text("Install")
                #if os(iOS)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .bold()
                #endif
        }
        #if os(iOS)
        .buttonStyle(.borderedProminent)
        #endif
    }

    private func installModel() {
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = true
        #endif

        Task {
            currentInstallState = .installing
            await llmEvaluator.switchModel(ModelConfiguration.defaultModel)
        }
    }

    private func completeInstallation() {
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = false
        #endif

        intelligenceManager.currentModelName = ModelConfiguration.defaultModel.name
        intelligenceManager.addInstalledModel(ModelConfiguration.defaultModel.name)

        currentInstallState = .installed
    }

    private var descriptionText: String {
        let baseText = """
            Canvas Plus can leverage on-device LLMs to enable intelligence capabilities, \
            such as summarizing announcements, \
            performing intelligent grade calculations, \
            and more. \
            Simply download and install a model to get started.
            """

        return switch currentInstallState {
        case .readyToInstall:
            baseText
        case .installing:
            baseText + "\n\nInstalling...\nPlease keep this view open while it downloads."
        case .installed:
            baseText + "\n\nIntelligence is installed."
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
