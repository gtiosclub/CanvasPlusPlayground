//
//  ToastView.swift
//  CanvasPlusPlayground
//
//  Created by João Pozzobon on 2/17/25.
//

import SwiftUI

struct ToastView: View {
    var toast: Toast

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.down.circle")
                .font(.title)
                .foregroundColor(.accentColor)

            VStack(alignment: .leading) {
                Text(toast.title)
                    .font(.body)
                    .fontWeight(.medium)

                if let subtitle = toast.subtitle {
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
        .background {
            Capsule()
                .fill(.background)
                .shadow(color: .primary.opacity(0.2), radius: 4, x: 0, y: 1)
        }
    }
}
