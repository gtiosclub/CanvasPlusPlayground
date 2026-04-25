//
//  AnimatedMeshGradient.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/10/25.
//

import SwiftUI

struct DashboardMeshGradient: View {
    let colors: [Color]

    @Environment(\.colorScheme) private var colorScheme
    @State private var startTime = Date.now

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSince(startTime)

            MeshGradient(
                width: meshWidth,
                height: 3,
                points: animatedPoints(at: time),
                colors: meshColors
            )
        }
        .blur(radius: colorScheme == .dark ? 120 : 60)
        .opacity(colorScheme == .dark ? 0.2 : 0.6)
    }

    private var fallbackColors: [Color] {
        colorScheme == .dark
            ? [.c1, .c2, .c3, .c4, .c5]
            : [.c1, .c2, .c3, .c4]
    }

    private var meshWidth: Int {
        guard !colors.isEmpty else {
            return fallbackColors.count
        }
        return max(3, colors.count)
    }

    private var meshColors: [Color] {
        let actualColors = colors.isEmpty ? fallbackColors : colors
        let width = actualColors.count

        var result: [Color] = []
        for row in 0..<3 {
            for col in 0..<width {
                result.append(actualColors[(col + row) % actualColors.count])
            }
        }
        return result
    }

    private func animatedPoints(at time: TimeInterval) -> [SIMD2<Float>] {
        let width = meshWidth
        let speed: Float = 0.15

        var points: [SIMD2<Float>] = []

        for row in 0..<3 {
            for col in 0..<width {
                let xPos = Float(col) / Float(width - 1)
                let yPos = Float(row) / 2.0

                let timeOffset = Float(col + row) * 0.3
                let yFreq = speed * (0.8 + Float(row) * 0.15)

                let animatedY = yPos + sin(Float(time) * yFreq + timeOffset) * 0.08

                points.append(SIMD2(xPos, animatedY))
            }
        }

        return points
    }
}

enum DashboardGradientColors {
    static func getColors(from courses: [Course]) -> [Color] {
        let customColors = courses
            .compactMap { $0.rgbColors }
            .map { Color(rgbColors: $0) }

        // De-dupe while preserving order.
        var seen = Set<String>()
        let uniqueColors = customColors.filter { seen.insert($0.hexString).inserted }

        if uniqueColors.isEmpty {
            return [] // Let DashboardMeshGradient pick the right fallback based on color scheme
        }
        return uniqueColors
    }
}

#Preview {
    DashboardMeshGradient(colors: [])
        .frame(height: 400)
        .preferredColorScheme(.light)

    DashboardMeshGradient(colors: [])
        .frame(height: 400)
        .preferredColorScheme(.dark)
}
