//
//  SetupView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/7/24.
//

import SwiftUI

struct SetupView: View {
    @Environment(ProfileManager.self) private var profileManager
    @Environment(CourseManager.self) private var courseManager
    @Environment(\.dismiss) private var dismiss

    @State private var tempAccessKey: String = ""

    var isOnboarding: Bool = false
    var onContinue: (() -> Void)?

    var body: some View {
        VStack(spacing: 8) {
            Spacer()

            Image(systemName: "person.badge.key")
                .font(.largeTitle)
                .foregroundStyle(.tint)

            Text("Setup Access Token")
                .font(.largeTitle)
                .bold()

            Text("An Access Token is required to use the Canvas API and retrieve course information.")
                .multilineTextAlignment(.center)

            Spacer()

            VStack(spacing: 16) {
                HStack {
                    TextField("Access Token", text: $tempAccessKey)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal)

                // swiftlint:disable:next force_unwrapping
                Link("Generate Access Token on Canvas", destination: URL(string: "https://gatech.instructure.com/profile")!)
                    .font(.headline)
            }

            Spacer()
        }
        .fontDesign(.rounded)
        .padding()
        .onAppear {
            tempAccessKey = StorageKeys.accessTokenValue.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        .onDisappear {
            if !isOnboarding {
                Task {
                    StorageKeys.accessTokenValue = tempAccessKey.trimmingCharacters(in: .whitespacesAndNewlines)
                    await courseManager.getCourses()
                    await profileManager.getCurrentUserAndProfile()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    if isOnboarding {
                        StorageKeys.accessTokenValue = tempAccessKey.trimmingCharacters(in: .whitespacesAndNewlines)
                        onContinue?()
                    } else {
                        dismiss()
                    }
                }
                .disabled(tempAccessKey.isEmpty)
            }
        }
        .interactiveDismissDisabled(tempAccessKey.isEmpty)
    }
}
