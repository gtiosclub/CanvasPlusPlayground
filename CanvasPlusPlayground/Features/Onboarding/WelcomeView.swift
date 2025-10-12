//
//  WelcomeView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/11/25.
//

import SwiftUI

struct WelcomeView: View {
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "graduationcap.fill")
                .font(.system(size: 80))
                .foregroundStyle(.tint)

            Text("Welcome")
                .font(.largeTitle)
                .bold()

            Text("Canvas Plus is a powerful companion app for Canvas LMS that enhances your learning experience with advanced features, intelligence-powered tools, and a beautiful interface.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            Button {
                onContinue()
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .compatibleGlassProminentButton()
            .controlSize(.large)
            .padding(.horizontal)
        }
        .fontDesign(.rounded)
        .padding()
    }
}

#Preview {
    WelcomeView(onContinue: {})
}
