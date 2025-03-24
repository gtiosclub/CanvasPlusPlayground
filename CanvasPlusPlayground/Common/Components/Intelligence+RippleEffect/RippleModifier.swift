//
//  RippleModifier.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 3/23/25.
//

import SwiftUI

/// A modifier that applies a ripple effect to its content.
struct RippleModifier: ViewModifier {
    var origin: CGPoint

    var elapsedTime: TimeInterval

    var duration: TimeInterval

    var amplitude: Double
    var frequency: Double
    var decay: Double
    var speed: Double
    var effectValue: Double

    func body(content: Content) -> some View {
        let shader = ShaderLibrary.Ripple(
            .float2(origin),
            .float(elapsedTime),

            // Parameters
            .float(amplitude),
            .float(frequency),
            .float(decay),
            .float(speed),
            .float(effectValue)
        )

        let maxSampleOffset = maxSampleOffset
        let elapsedTime = elapsedTime
        let duration = duration

        content.visualEffect { view, _ in
            view.layerEffect(
                shader,
                maxSampleOffset: maxSampleOffset,
                isEnabled: 0 < elapsedTime && elapsedTime < duration
            )
        }
    }

    var maxSampleOffset: CGSize {
        CGSize(width: amplitude, height: amplitude)
    }
}

struct RippleEffect<T: Equatable>: ViewModifier {
    var origin: CGPoint
    var trigger: T
    var amplitude: Double
    var frequency: Double
    var decay: Double
    var speed: Double
    var effectValue: Double

    init(at origin: CGPoint, trigger: T, amplitude: Double = 12, frequency: Double = 15, decay: Double = 8, speed: Double = 1200, effectValue: Double = 0) {
        self.origin = origin
        self.trigger = trigger
        self.amplitude = amplitude
        self.frequency = frequency
        self.decay = decay
        self.speed = speed
        self.effectValue = effectValue
    }

    func body(content: Content) -> some View {
        let origin = origin
        let duration = duration
        let amplitude = amplitude
        let frequency = frequency
        let decay = decay
        let speed = speed
        let effectValue = effectValue

        content.keyframeAnimator(
            initialValue: 0,
            trigger: trigger
        ) { view, elapsedTime in
            view.modifier(RippleModifier(
                origin: origin,
                elapsedTime: elapsedTime,
                duration: duration,
                amplitude: amplitude,
                frequency: frequency,
                decay: decay,
                speed: speed,
                effectValue: effectValue
            ))
        } keyframes: { _ in
            MoveKeyframe(0)
            LinearKeyframe(duration, duration: duration)
        }
    }

    var duration: TimeInterval { 3 }
}
