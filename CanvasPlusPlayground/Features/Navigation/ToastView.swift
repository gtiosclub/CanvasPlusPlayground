//
//  ToastView.swift
//  CanvasPlusPlayground
//
//  Created by João Pozzobon on 2/17/25.
//

import SwiftUI

struct ToastView: View {
    var toast: Toast

    @Namespace var animation

    var body: some View {
        HStack(spacing: 12) {
            Group {
                switch toast.type {
                case .download(let download):
                    DownloadGaugeView(model: .init(download: download))
                default:
                    Image(systemName: toast.type.systemImage)
                        .resizable()
                }
            }
            .frame(width: 17, height: 17)
            .font(.system(size: 17, weight: .bold))
            .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(toast.type.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .minimumScaleFactor(0.5)
                    .lineLimit(2)

                if let subtitle = toast.type.subtitle {
                    Text(subtitle)
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                        .bold()
                }
            }
        }
        .padding(8)
        .padding(.horizontal, 12)
        .clipShape(Capsule())
        .background {
            Capsule()
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 1)
                .overlay {
                    Capsule()
                        .fill(.linearGradient(colors: [.white, .white.opacity(0)], startPoint: .top, endPoint: .bottom))
                        .opacity(0.1)
                }
                .overlay {
                    Capsule()
                        .strokeBorder(Color(white: 0.9), style: .init(lineWidth: 1))
                        .blendMode(.overlay)
                }
                .compositingGroup()
        }
    }
}

@Observable
class DownloadGaugeViewModel {
    var download: Download

    init(download: Download) {
        self.download = download
    }
}

struct DownloadGaugeView: View {
    var model: DownloadGaugeViewModel

    var body: some View {
        ProgressView(value: model.download.progress, total: 1.0)
            .progressViewStyle(GaugeProgressStyle())
    }
}
