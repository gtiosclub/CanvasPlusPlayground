//
//  PinnedItemCard.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 1/10/25.
//

import SwiftUI

struct PinnedItemCard: View {
    var item: PinnedItem

    var body: some View {
        Group {
            if let itemData = item.data {
                switch itemData.modelData {
                case .announcement(let announcement):
                    PinnedAnnouncementCard(
                        announcement: announcement,
                        course: itemData.course
                    )
                case .file(let file):
                    PinnedFileCard(
                        file: file,
                        course: itemData.course
                    )
                case .assignment(let assignment):
                    PinnedAssignmentCard(
                        assignment: assignment,
                        course: itemData.course
                    )
                case .calendarEvent(let event):
                    PinnedCalendarEventCard(
                        event: event,
                        course: itemData.course
                    )
                }
            } else {
                Text("Loading...")
            }
        }
        .buttonStyle(.plain)
    }
}

private struct PinnedAnnouncementCard: View {
    let announcement: DiscussionTopic
    let course: Course

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(course.displayName.uppercased())
                .font(.caption)
                .foregroundStyle(course.rgbColors?.color ?? .accentColor)

            VStack(alignment: .leading, spacing: 3) {
                Text(announcement.title ?? "")
                    .font(.headline)
                    .fontDesign(.rounded)
                    .bold()

                Text(
                    announcement.message?
                        .stripHTML()
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                    ?? ""
                )
                .lineLimit(2)
            }
        }
    }
}

private struct PinnedFileCard: View {
    let file: File
    let course: Course

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "document")
                .foregroundStyle(course.rgbColors?.color ?? .accentColor)
                .font(.title)

            VStack(alignment: .leading, spacing: 8) {
                Text(course.displayName.uppercased())
                    .font(.caption)
                    .foregroundStyle(course.rgbColors?.color ?? .accentColor)

                Text(file.displayName)
                    .font(.headline)
                    .fontDesign(.rounded)
                    .bold()
            }

            Spacer()
        }
    }
}

private struct PinnedAssignmentCard: View {
    let assignment: Assignment
    let course: Course

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "circle")
                .foregroundStyle(course.rgbColors?.color ?? .accentColor)
                .font(.title)

            VStack(alignment: .leading, spacing: 8) {
                Text(course.displayName.uppercased())
                    .font(.caption)
                    .foregroundStyle(course.rgbColors?.color ?? .accentColor)

                Text(assignment.name)
                    .font(.headline)
                    .fontDesign(.rounded)
                    .bold()
            }

            Spacer()
        }
    }
}

private struct PinnedCalendarEventCard: View {
    let event: CanvasCalendarEvent
    let course: Course?

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: event.startDate)
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar")
                .foregroundStyle(course?.rgbColors?.color ?? .blue)
                .font(.title)

            VStack(alignment: .leading, spacing: 8) {
                if let course {
                    Text(course.displayName.uppercased())
                        .font(.caption)
                        .foregroundStyle(course.rgbColors?.color ?? .blue)
                }

                Text(event.summary)
                    .font(.headline)
                    .fontDesign(.rounded)
                    .bold()

                Text(timeString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

extension View {
    func cardBackground(selected: Bool) -> some View {
        self
            .frame(width: 250)
            .frame(maxHeight: .infinity)
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 16.0)
                    .fill(.secondary.opacity(selected ? 0.30 : 0.15))
            }
    }
}
