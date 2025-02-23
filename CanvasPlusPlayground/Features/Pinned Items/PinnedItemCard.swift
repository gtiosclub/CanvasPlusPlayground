//
//  PinnedItemCard.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 1/10/25.
//

import SwiftUI

struct PinnedItemCard: View {
    @State var item: PinnedItem

    var body: some View {
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
            }
        } else {
            Text("Loading...")
        }
//        .buttonStyle(.plain)
    }
}

private struct PinnedAnnouncementCard: View {
    let announcement: Announcement
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
        .cardBackground()
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
        .cardBackground()
    }
}

private struct PinnedAssignmentCard: View {
    let assignment: AssignmentAPI
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
        .cardBackground()
    }
}

extension View {
    fileprivate func cardBackground() -> some View {
        self
            .frame(width: 250)
            .frame(maxHeight: .infinity)
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 16.0)
                    .fill(.secondary.opacity(0.15))
            }
    }
}
