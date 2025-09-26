//
//  IGCSetupView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/24/25.
//

import SwiftUI

/// Entry point for setting up the Intelligent Grade Calculator.
@available(macOS 26.0, iOS 26.0, *)
struct IGCSetupView: View {
    @Environment(\.dismiss) var dismiss

    let course: Course
    let calculator: GradeCalculator
    @State private var path = [IGCOnboardingScreen]()
    @State private var manager = IGCSetupManager()

    var body: some View {
        NavigationStack(path: $path) {
            IGCOnboardingView(
                screen: IGCOnboardingScreen.first,
                path: $path,
                dismiss: dismiss)
                .toolbar {
                    Button(role: .close) { dismiss() }
                }
                .navigationDestination(for: IGCOnboardingScreen.self) { screen in
                    IGCOnboardingView(screen: screen, path: $path, dismiss: dismiss)
                }
        }
        .onAppear {
            manager.course = course
            manager.calculator = calculator
        }
        .interactiveDismissDisabled(!path.isEmpty && path.last != .first)
        .environment(manager)
    }
}
