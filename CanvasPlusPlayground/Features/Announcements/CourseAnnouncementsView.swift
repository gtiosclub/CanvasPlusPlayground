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
                    AnnouncementRow(announcement: announcement)
                }
                .tint(course.rgbColors?.color)
            }
            .overlay {
                if (announcementManager.announcements.count == 0) {
                    ContentUnavailableView("No announcements available within last 14 days", systemImage: "exclamationmark.bubble.fill")
                } else {
                    EmptyView()
                }
            }
            .task {
                await announcementManager.fetchAnnouncements()
            }
            .navigationTitle("Announcements")
        }
    }
}

private struct AnnouncementRow: View {
    let announcement: Announcement

    var body: some View {
        VStack(alignment: .leading) {
            header
            detail
        }
    }

    private var header: some View {
        HStack {
            if !(announcement.isRead ?? false) {
                Circle()
                    .fill(.tint)
                    .frame(width: unreadIndicatorWidth, height: unreadIndicatorWidth)
            } else {
                Spacer().frame(width: unreadIndicatorWidth)
            }

            Text(announcement.title ?? "")

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
                    Text(Image(systemName: "wand.and.sparkles")) + Text(summary)
                } else {
                    AsyncAttributedText(
                        announcement: announcement,
                        textOnly: true
                    )
                }
            }
            .lineLimit(2)
            .foregroundStyle(.secondary)
            .controlSize(.small)
        }
    }

    private let unreadIndicatorWidth: CGFloat = 10
}
