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
                if let modelData = itemData.modelData {
                    switch modelData {
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
                    case .quiz(let quiz):
                        PinnedQuizCard(
                            quiz: quiz,
                            course: itemData.course
                        )
                    case .grade(let enrollment):
                        PinnedGradeCard(
                            enrollment: enrollment,
                            course: itemData.course
                        )
                    }
                } else {
                    // Course tab without specific model data
                    PinnedCourseTabCard(
                        type: item.type,
                        course: itemData.course
                    )
                }
            } else {
                Text("Loading...")
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                PinnedItemsManager.shared.removePinnedItem(
                    itemID: item.id,
                    courseID: item.courseID,
                    type: item.type
                )
            } label: {
                Label("Unpin", systemImage: "pin.slash")
            }
        }
    }
}

// MARK: - Base Card View
private struct BasePinnedItemCard<Content: View>: View {
    let course: Course?
    let icon: String?
    let title: String
    let additionalContent: () -> Content

    init(
        course: Course?,
        icon: String? = nil,
        title: String,
        @ViewBuilder additionalContent: @escaping () -> Content = { EmptyView() }
    ) {
        self.course = course
        self.icon = icon
        self.title = title
        self.additionalContent = additionalContent
    }

    var body: some View {
        HStack(spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .foregroundStyle(course?.rgbColors?.color ?? .accentColor)
                    .font(.title)
            }

            VStack(alignment: .leading, spacing: 8) {
                if let course {
                    Text(course.displayName.uppercased())
                        .font(.caption)
                        .foregroundStyle(course.rgbColors?.color ?? .accentColor)
                        .lineLimit(1)
                }

                Text(title)
                    .font(.headline)
                    .fontDesign(.rounded)
                    .bold()
                    .lineLimit(2)

                additionalContent()
            }

            Spacer()
        }
    }
}

// MARK: - Specific Card Views
private struct PinnedAnnouncementCard: View {
    let announcement: DiscussionTopic
    let course: Course

    var body: some View {
        BasePinnedItemCard(
            course: course,
            icon: nil,
            title: announcement.title ?? ""
        ) {
            Text(
                announcement.message?
                    .stripHTML()
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                ?? ""
            )
            .lineLimit(2)
        }
    }
}

private struct PinnedFileCard: View {
    let file: File
    let course: Course

    var body: some View {
        BasePinnedItemCard(
            course: course,
            icon: "document",
            title: file.displayName
        )
    }
}

private struct PinnedAssignmentCard: View {
    let assignment: Assignment
    let course: Course

    var body: some View {
        BasePinnedItemCard(
            course: course,
            icon: "book",
            title: assignment.name
        )
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
        BasePinnedItemCard(
            course: course,
            icon: "calendar",
            title: event.summary
        ) {
            Text(timeString)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

private struct PinnedQuizCard: View {
    let quiz: Quiz
    let course: Course

    var body: some View {
        BasePinnedItemCard(
            course: course,
            icon: "questionmark.circle",
            title: quiz.title
        ) {
            HStack(spacing: 8) {
                if let pointsPossible = quiz.pointsPossible?.truncatingTrailingZeros {
                    Text("\(pointsPossible) pts")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let questionCount = quiz.questionCount {
                    Text("\(questionCount) Questions")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct PinnedGradeCard: View {
    let enrollment: Enrollment
    let course: Course

    var body: some View {
        BasePinnedItemCard(
            course: course,
            icon: "chart.bar.fill",
            title: "Course Grade"
        ) {
            HStack(spacing: 8) {
                if let currentScore = enrollment.grades?.current_score?.truncatingTrailingZeros {
                    Text("\(currentScore)%")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let currentGrade = enrollment.grades?.current_grade {
                    Text(currentGrade)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct PinnedCourseTabCard: View {
    let type: PinnedItem.PinnedItemType
    let course: Course

    var body: some View {
        BasePinnedItemCard(
            course: course,
            icon: type.coursePage?.systemImageIcon,
            title: type.displayName
        )
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
    
    func pinnedItemBadge(isVisible: Bool) -> some View {
        Group {
            if isVisible {
                HStack(spacing: 4) {
                    self
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            } else {
                self
            }
        }
    }
}
    
