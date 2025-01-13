//
//  CourseAnnouncementsView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 9/13/24.
//

import SwiftUI

struct CourseAnnouncementsView: View {
    let course: Course
    @State private var announcementManager: CourseAnnouncementManager

    @State private var isLoadingAnnouncements: Bool = true

    init(course: Course) {
        self.course = course
        self.announcementManager = CourseAnnouncementManager(course: course)
    }

    var body: some View {
        NavigationStack {
            List(announcementManager.announcements, id:\.id) { announcement in
                NavigationLink {
                    CourseAnnouncementDetailView(announcement: announcement)
                } label: {
                    AnnouncementRow(course: course, announcement: announcement)
                }
                .tint(course.rgbColors?.color)
            }
            .overlay {
                if (announcementManager.announcements.isEmpty) {
                    ContentUnavailableView("No announcements available", systemImage: "exclamationmark.bubble.fill")
                } else {
                    EmptyView()
                }
            }
            .task {
                await loadAnnouncements()
            }
            .refreshable {
                await loadAnnouncements()
            }
            .statusToolbarItem(
                "Announcements",
                isVisible: isLoadingAnnouncements
            )
            .navigationTitle("Announcements")
        }
    }

    private func loadAnnouncements() async {
        isLoadingAnnouncements = true
        await announcementManager.fetchAnnouncements()
        isLoadingAnnouncements = false
    }
}

private struct AnnouncementRow: View {
    let course: Course
    let announcement: Announcement

    // MARK: Drawing Constants
    private let unreadIndicatorWidth: CGFloat = 10

    var body: some View {
        VStack(alignment: .announcementRowAlignment) {
            header
            detail
        }
        .contextMenu {
            PinButton(
                itemID: announcement.id,
                courseID: course.id,
                type: .announcement
            )
        }
        .swipeActions(edge: .leading) {
            PinButton(
                itemID: announcement.id,
                courseID: course.id,
                type: .announcement
            )
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
                            course.rgbColors?.color ?? .accentColor
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
