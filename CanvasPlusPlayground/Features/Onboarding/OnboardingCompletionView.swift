//
//  OnboardingCompletionView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/11/25.
//

import SwiftUI

struct OnboardingCompletionView: View {
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("Welcome to Canvas Plus")
                .font(.largeTitle)
                .bold()

            Text("You're all set! Start exploring your courses and take advantage of all the powerful features Canvas Plus has to offer.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            #if os(iOS)
            SlideToCompleteView(text: "Slide to get started...", onComplete: onDismiss)
                .padding(.horizontal)
            #else
            Button {
                onDismiss()
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)
            #endif
        }
        .fontDesign(.rounded)
        .padding()
        .courseGradientBackground(courses: [], edge: .bottom)
    }
}

#if os(iOS)
private struct SlideToCompleteView: View {
    let text: String
    let onComplete: () -> Void

    @State private var dragOffset: CGFloat = 0
    @State private var trackWidth: CGFloat = 0
    @State private var isCompleted: Bool = false

    private let circleSize: CGFloat = 60
    private let trackHeight: CGFloat = 80

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.thinMaterial)
                    .stroke(.thickMaterial, lineWidth: 2)
                    .frame(height: trackHeight)

                if !isCompleted {
                    Text(text)
                        .foregroundStyle(.gray)
                        .frame(maxWidth: .infinity)
                        .shimmer(duration: 3.5)
                        .allowsHitTesting(false)
                }

                Image(systemName: isCompleted ? "checkmark" : "chevron.right")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.primary)
                    .frame(width: circleSize, height: circleSize)
                    .compatibleGlassEffect(.clear, in: .capsule)
                    .offset(x: dragOffset + 5)
                    .contentShape(.capsule)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let maxDrag = trackWidth - circleSize - 10
                                dragOffset = min(max(0, value.translation.width), maxDrag)
                            }
                            .onEnded { _ in
                                let threshold = (trackWidth - circleSize - 10) * 0.8
                                if dragOffset >= threshold {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        dragOffset = trackWidth - circleSize - 10
                                        isCompleted = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        onComplete()
                                    }
                                } else {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        dragOffset = 0
                                    }
                                }
                            }
                    )
            }
            .onAppear {
                trackWidth = geometry.size.width
            }
        }
        .frame(height: trackHeight)
    }
}
#endif

#Preview {
    OnboardingCompletionView(onDismiss: {})
}
