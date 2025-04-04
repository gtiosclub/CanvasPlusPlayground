//
//  AnnouncementRow.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 1/19/25.
//

import SwiftUI

struct AnnouncementRow: View {
    let course: Course?
    let announcement: DiscussionTopic
    var showCourseName = false

    // MARK: Drawing Constants
    private let unreadIndicatorWidth: CGFloat = 10

    var body: some View {
        VStack(alignment: .announcementRowAlignment) {
            if showCourseName {
                courseName
            }
            header
            detail
        }
        .contextMenu {
            PinButton(
                itemID: announcement.id,
                courseID: course?.id,
                type: .announcement
            )

            toggleReadButton
        }
        .swipeActions(edge: .leading) {
            PinButton(
                itemID: announcement.id,
                courseID: course?.id,
                type: .announcement
            )
        }
        .id(announcement.id)
    }

    private var courseName: some View {
        Text(course?.displayName.uppercased() ?? "")
            .font(.caption)
            .foregroundStyle(course?.rgbColors?.color ?? .accentColor)
            .alignmentGuide(.announcementRowAlignment) { context in
                context[.leading]
            }
    }

    private var toggleReadButton: some View {
        Button(announcement.readActionLabel) {
            Task {
                try await announcement.toggleReadState()
            }
        }
    }

    private var header: some View {
        HStack {
            Group {
                if !(announcement.isRead) {
                    Circle()
                        .fill(.tint)
                } else {
                    Spacer().frame(width: unreadIndicatorWidth)
                }
            }
            .frame(width: unreadIndicatorWidth, height: unreadIndicatorWidth)

            Text(announcement.title ?? "")
                .alignmentGuide(.announcementRowAlignment) { context in
                    context[.leading]
                }

            Spacer()

            if let createdAt = announcement.date {
                Text(createdAt.formatted(.relative(presentation: .named)))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var detail: some View {
        HStack {
            Spacer().frame(width: unreadIndicatorWidth)

            Group {
                if let summary = announcement.summary {
                    Text(Image(systemName: "wand.and.sparkles"))
                        .foregroundStyle(
                            .intelligenceGradient()
                        )
                    +
                    Text(summary)
                } else {
                    Text(
                        announcement.message?
                            .stripHTML()
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                        ?? ""
                    )
                }
            }
            .lineLimit(2)
            .foregroundStyle(.secondary)
            .controlSize(.small)
            .alignmentGuide(.announcementRowAlignment) { context in
                context[.leading]
            }
        }
    }
}

extension HorizontalAlignment {
    private struct AnnouncementRowAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[HorizontalAlignment.center]
        }
    }

    fileprivate static let announcementRowAlignment = HorizontalAlignment(
        AnnouncementRowAlignment.self
    )
}
