//
//  SetupView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/7/24.
//

import SwiftUI

struct SetupView: View {
    @Environment(ProfileManager.self) var profileManager
    @Environment(CourseManager.self) var courseManager
    @Environment(\.dismiss) var dismiss

    @State private var tempAccessKey: String = ""

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

                Link("Generate Access Token on Canvas", destination: URL(string: "https://gatech.instructure.com/profile")!)
                    .font(.headline)
            }

            Spacer()
        }
        .fontDesign(.rounded)
        .padding()
        .onAppear {
            tempAccessKey = StorageKeys.accessTokenValue
        }
        .onDisappear {
            Task {
                StorageKeys.accessTokenValue = tempAccessKey
                await courseManager.getCourses()
                await profileManager.getCurrentUserAndProfile()
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
                .disabled(tempAccessKey.isEmpty)
            }
        }
        .interactiveDismissDisabled(tempAccessKey.isEmpty)
    }
}
