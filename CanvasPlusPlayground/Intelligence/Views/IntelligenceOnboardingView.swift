//
//  IntelligenceOnboardingView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/31/24.
//

import SwiftUI

struct IntelligenceOnboardingView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            header

            Spacer()
        }
        .padding()
        .multilineTextAlignment(.center)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
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

    private var descriptionText: String {
        """
        Canvas Plus can leverage on-device LLMs to enable intelligence capabilities, \
        such as summarizing announcements, \
        performing intelligent grade calculations, \
        and more. \
        Simply download and install a model to get started.
        """
    }
}

#Preview {
    NavigationStack {
        IntelligenceOnboardingView()
    }
}
