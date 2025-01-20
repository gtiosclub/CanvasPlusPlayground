//
//  AnnouncementRow.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 1/19/25.
//

import SwiftUI

struct AnnouncementRow: View {
    let course: Course?
    let announcement: Announcement
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

    private var header: some View {
        HStack {
            Group {
                if !(announcement.isRead ?? false) {
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

            if let createdAt = announcement.createdAt {
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
                            course?.rgbColors?.color ?? .accentColor
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
