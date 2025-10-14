//
//  OnboardingFlowView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/11/25.
//

import SwiftUI

struct OnboardingFlowView: View {
    @Environment(ProfileManager.self) private var profileManager
    @Environment(CourseManager.self) private var courseManager
    @Environment(\.dismiss) private var dismiss

    enum OnboardingStep: Hashable {
        case setup
        case completion
    }

    @State private var navigationPath: [OnboardingStep] = []

    var body: some View {
        NavigationStack(path: $navigationPath) {
            WelcomeView {
                navigationPath.append(.setup)
            }
            .navigationDestination(for: OnboardingStep.self) { step in
                switch step {
                case .setup:
                    SetupView(isOnboarding: true) {
                        navigationPath.append(.completion)
                    }
                case .completion:
                    OnboardingCompletionView {
                        completeOnboarding()
                    }
                    .navigationBarBackButtonHidden()
                }
            }
        }
        .interactiveDismissDisabled()
    }

    private func completeOnboarding() {
        StorageKeys.hasCompletedOnboarding = true
        dismiss()
    }
}
