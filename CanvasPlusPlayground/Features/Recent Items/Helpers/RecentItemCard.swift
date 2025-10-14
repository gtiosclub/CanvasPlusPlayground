//
//  RecentItemCard.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/11/25.
//

import SwiftUI

struct RecentItemCard: View {
    @Environment(CourseManager.self) private var courseManager

    var item: RecentItem

    private var course: Course? {
        courseManager.course(withID: item.courseID)
    }

    var body: some View {
        Group {
            if let data = item.data, let course {
                switch data {
                case .announcement(let announcement):
                    RecentAnnouncementCard(
                        announcement: announcement,
                        course: course
                    )
                case .assignment(let assignment):
                    RecentAssignmentCard(
                        assignment: assignment,
                        course: course
                    )
                case .file(let file):
                    RecentFileCard(
                        file: file,
                        course: course
                    )
                case .quiz(let quiz):
                    RecentQuizCard(
                        quiz: quiz,
                        course: course
                    )
                }
            } else {
                PlaceholderCard(course: course)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct GenericRecentCard: View {
    let icon: String
    let title: String
    let subtitle: String?
    let course: Course

    init(icon: String, title: String, subtitle: String? = nil, course: Course) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.course = course
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(course.rgbColors?.color ?? .accentColor)
                    .font(.caption)

                Text(course.displayName.uppercased())
                    .font(.caption)
                    .foregroundStyle(course.rgbColors?.color ?? .accentColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .fontDesign(.rounded)
                    .bold()
                    .lineLimit(2)

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }
}

private struct RecentAnnouncementCard: View {
    let announcement: DiscussionTopic
    let course: Course

    var body: some View {
        GenericRecentCard(
            icon: "bubble.fill",
            title: announcement.title ?? "",
            subtitle: announcement.message?
                .stripHTML()
                .trimmingCharacters(in: .whitespacesAndNewlines),
            course: course
        )
    }
}

private struct RecentAssignmentCard: View {
    let assignment: Assignment
    let course: Course

    var body: some View {
        GenericRecentCard(
            icon: "circle.inset.filled",
            title: assignment.name,
            subtitle: assignment.dueDate.map { "Due \($0.formatted(.relative(presentation: .named)))" },
            course: course
        )
    }
}

private struct RecentFileCard: View {
    let file: File
    let course: Course

    var body: some View {
        GenericRecentCard(
            icon: "doc.fill",
            title: file.displayName,
            course: course
        )
    }
}

private struct RecentQuizCard: View {
    let quiz: Quiz
    let course: Course

    var body: some View {
        GenericRecentCard(
            icon: "questionmark.circle.fill",
            title: quiz.title,
            subtitle: quiz.dueDate.map { "Due \($0.formatted(.relative(presentation: .named)))" },
            course: course
        )
    }
}

private struct PlaceholderCard: View {
    let course: Course?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let course {
                Text(course.displayName.uppercased())
                    .font(.caption)
                    .foregroundStyle(course.rgbColors?.color ?? .accentColor)
            }

            HStack {
                ProgressView()
                    .controlSize(.small)
                Text("Loading...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
