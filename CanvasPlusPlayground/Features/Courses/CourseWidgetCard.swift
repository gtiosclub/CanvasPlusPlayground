//
//  CourseWidgetCard.swift
//  CanvasPlusPlayground
//

import SwiftUI

/// Full-width card on the course Home screen: `[icon] Title ······ View All >` header over custom content.
struct CourseWidgetCard<Content: View>: View {
    let title: String
    let systemImage: String
    var accessoryTitle: String?
    let destination: NavigationModel.Destination
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink(value: destination) {
                HStack {
                    Label(title, systemImage: systemImage)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    HStack(spacing: 6) {
                        if let accessoryTitle {
                            Text(accessoryTitle)
                        }
                        Image(systemName: "chevron.right")
                    }
                    .font(.body)
                    .foregroundStyle(.secondary)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: .rect(cornerRadius: 24))
    }
}
