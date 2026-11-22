//
//  AnnouncementOverviewView.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 4/20/26.
//

import SwiftUI

/// Course Home widget: the 3 most recent announcements, with "View All" to the course's announcements page.
struct AnnouncementOverviewView: View {
    @Environment(NavigationModel.self) private var navigationModel

    let course: Course

    @State private var announcementManager: CourseAnnouncementManager

    init(course: Course) {
        self.course = course
        self._announcementManager = State(initialValue: CourseAnnouncementManager(course: course))
    }

    private var recentAnnouncements: [DiscussionTopic] {
        Array(announcementManager.displayedAnnouncements.prefix(3))
    }

    var body: some View {
        CourseWidgetCard(
            title: "Announcements",
            systemImage: "megaphone",
            accessoryTitle: "View All",
            destination: .coursePage(.announcements, course)
        ) {
            if recentAnnouncements.isEmpty {
                Text("No announcements")
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(recentAnnouncements) { announcement in
                        if announcement.id != recentAnnouncements.first?.id {
                            Divider()
                        }
                        row(announcement)
                    }
                }
            }
        }
        .task(id: course.id) {
            if announcementManager.course.id != course.id {
                announcementManager = CourseAnnouncementManager(course: course)
            }
            await announcementManager.fetchAnnouncements()
        }
    }

    private func row(_ announcement: DiscussionTopic) -> some View {
        Button {
            navigationModel.push(.announcement(announcement))
        } label: {
            HStack(spacing: 12) {
                authorCircle(for: announcement)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(announcement.title ?? "")
                            .font(.title3)
                            .lineLimit(1)
                        Spacer()
                        if let date = announcement.date {
                            Text(date, format: .dateTime.month(.abbreviated).day())
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text(announcement.message?.stripHTML().trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 10)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private func authorCircle(for announcement: DiscussionTopic) -> some View {
        let name = announcement.author?.display_name ?? announcement.userName ?? ""

        return Text(name.first.map { String($0).uppercased() } ?? "")
            .font(.headline)
            .foregroundStyle(.secondary)
            .frame(width: 40, height: 40)
            .background(.quaternary, in: .circle)
            .overlay(Circle().stroke(.tertiary, lineWidth: 1))
            .accessibilityHidden(true)
    }
}
