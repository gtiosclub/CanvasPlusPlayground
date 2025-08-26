//
//  DownloadButtonView.swift
//  CanvasPlusPlayground
//
//  Created by João Pozzobon on 3/14/25.
//

import SwiftUI

struct DownloadButtonView: View {
    let model: DownloadButtonViewModel

    var completed: Bool {
        model.download?.localURL != nil
    }

    var failed: Bool {
        !completed && model.download?.downloadTask == nil
    }

    var body: some View {
        DownloadIcon(progress: model.download?.progress, completed: completed, failed: failed)
    }
}

@Observable
class DownloadButtonViewModel {
    var download: Download?

    init(download: Download?) {
        self.download = download
    }
}

struct DownloadIcon: View {
    var progress: Double?
    var completed: Bool
    var failed: Bool

#if os(iOS)
    var size: CGFloat = 26.0
#else
    var size: CGFloat = 18.0
#endif

    var body: some View {
        ProgressView(value: failed ? 0 : progress, total: 1.0)
            .progressViewStyle(GaugeProgressStyle(strokeWidth: size / 12.0))
            .opacity(failed ? 0 : 1)
            .overlay {
                Image(systemName: "arrow.down")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .offset(x: 0, y: progress == nil ? 0 : size)
                    .opacity(progress == nil ? 1 : 0)
                    .foregroundStyle(.secondary)
            }
            .overlay {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.4, weight: .bold))
                    .offset(x: 0, y: progress == 1 ? 0 : size)
                    .opacity(progress == 1 ? 1 : 0)
                    .foregroundColor(.white)
            }
            .overlay {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: size * 0.9, weight: .bold))
                    .offset(x: 0, y: failed ? 0 : -size)
                    .opacity(failed ? 1 : 0)
            }
            .clipShape(Circle())
            .animation(.default, value: completed)
            .animation(.default, value: progress)
            .frame(width: size, height: size)
            .font(.system(size: size, weight: .bold))
    }

    struct GaugeProgressStyle: ProgressViewStyle {
        var strokeColor = Color.accentColor
        var strokeWidth = 2.5

        func makeBody(configuration: Configuration) -> some View {
            let fractionCompleted = configuration.fractionCompleted

            return Circle()
                .trim(from: 0, to: fractionCompleted ?? 0.0)
                .stroke(strokeColor, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .overlay {
                    if fractionCompleted == 1.0 {
                        Circle()
                            .fill(strokeColor)
                    }
                }
                .background {
                    if fractionCompleted == nil {
                        Circle()
                            .stroke(.secondary, style: .init(lineWidth: strokeWidth, lineCap: .butt, lineJoin: .round, dash: [2], dashPhase: 1))
                    }
                }
                .background {
                    if fractionCompleted != nil {
                        Circle()
                            .stroke(.secondary, lineWidth: strokeWidth)
                    }
                }
                .padding(strokeWidth)
                .animation(.default, value: fractionCompleted)
        }
    }
}
