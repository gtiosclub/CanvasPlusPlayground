//
//  ToastView.swift
//  CanvasPlusPlayground
//
//  Created by João Pozzobon on 2/17/25.
//

import SwiftUI

struct ToastView: View {
    var toast: Toast

    @GestureState var drag = CGSize.zero

    @Environment(NavigationModel.self) private var navigationModel

    @Namespace var animation

    var body: some View {
        Button(action: {
            toast.type.action(navigationModel)
        }, label: {
            content
        })
        .buttonStyle(ElasticButtonStyle())
    }

    var offset: CGSize {
        var drag = drag

        if drag.height < 0 {
            drag.height = (drag.height / pow(2, abs(drag.height) / 2))
        }

        drag.width = (drag.width / pow(2, abs(drag.width) / 2))

        return drag
    }

    var content: some View {
        HStack(spacing: 16) {
            Group {
                switch toast.type {
                case .download(let download), .downloadFinished(let download):
                    DownloadButtonView(model: .init(download: download))
                }
            }
            .frame(width: 17, height: 17)
            .font(.system(size: 17, weight: .bold))
            .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(toast.type.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .allowsTightening(true)
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
                        .opacity(0.05)
                }
                .overlay {
                    Capsule()
                        .strokeBorder(Color(white: 0.9), style: .init(lineWidth: 1))
                        .blendMode(.overlay)
                }
                .compositingGroup()
        }
        .offset(offset)
        .gesture(DragGesture(minimumDistance: 0)
            .updating($drag) { value, state, _ in
                state = value.translation
            })
    }
}
