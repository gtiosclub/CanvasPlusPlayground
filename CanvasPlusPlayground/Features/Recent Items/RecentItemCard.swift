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

private struct RecentAnnouncementCard: View {
    let announcement: DiscussionTopic
    let course: Course

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bubble.fill")
                    .foregroundStyle(course.rgbColors?.color ?? .accentColor)
                    .font(.caption)

                Text(course.displayName.uppercased())
                    .font(.caption)
                    .foregroundStyle(course.rgbColors?.color ?? .accentColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(announcement.title ?? "")
                    .font(.headline)
                    .fontDesign(.rounded)
                    .bold()
                    .lineLimit(2)

                Text(
                    announcement.message?
                        .stripHTML()
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                    ?? ""
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            }
        }
    }
}

private struct RecentAssignmentCard: View {
    let assignment: Assignment
    let course: Course

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "circle.inset.filled")
                    .foregroundStyle(course.rgbColors?.color ?? .accentColor)
                    .font(.caption)

                Text(course.displayName.uppercased())
                    .font(.caption)
                    .foregroundStyle(course.rgbColors?.color ?? .accentColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(assignment.name)
                    .font(.headline)
                    .fontDesign(.rounded)
                    .bold()
                    .lineLimit(2)

                if let dueDate = assignment.dueDate {
                    Text("Due \(dueDate.formatted(.relative(presentation: .named)))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct RecentFileCard: View {
    let file: File
    let course: Course

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.fill")
                    .foregroundStyle(course.rgbColors?.color ?? .accentColor)
                    .font(.caption)

                Text(course.displayName.uppercased())
                    .font(.caption)
                    .foregroundStyle(course.rgbColors?.color ?? .accentColor)
            }

            Text(file.displayName)
                .font(.headline)
                .fontDesign(.rounded)
                .bold()
                .lineLimit(2)
        }
    }
}

private struct RecentQuizCard: View {
    let quiz: Quiz
    let course: Course

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundStyle(course.rgbColors?.color ?? .accentColor)
                    .font(.caption)

                Text(course.displayName.uppercased())
                    .font(.caption)
                    .foregroundStyle(course.rgbColors?.color ?? .accentColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(quiz.title)
                    .font(.headline)
                    .fontDesign(.rounded)
                    .bold()
                    .lineLimit(2)

                if let dueDate = quiz.dueDate {
                    Text("Due \(dueDate.formatted(.relative(presentation: .named)))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
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
