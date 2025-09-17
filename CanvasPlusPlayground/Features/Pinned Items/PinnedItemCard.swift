//
//  PinnedItemCard.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 1/10/25.
//

import SwiftUI

struct PinnedItemCard: View {
    var item: PinnedItem
	var onRemove: () -> Void
    var body: some View {
        Group {
            if let itemData = item.data {
                switch itemData.modelData {
                case .announcement(let announcement):
                    PinnedAnnouncementCard(
                        announcement: announcement,
                        course: itemData.course,
						onRemove: onRemove
                    )
                case .file(let file):
                    PinnedFileCard(
                        file: file,
                        course: itemData.course,
						onRemove: onRemove
                    )
                case .assignment(let assignment):
                    PinnedAssignmentCard(
                        assignment: assignment,
                        course: itemData.course,
						onRemove: onRemove
                    )
				case .quiz(let quiz):
					PinnedQuizCard(quiz: quiz, course: itemData.course, onRemove: onRemove)
                case .grade(let assignment):
                    PinnedGradeCard(
                        assignment: assignment,
                        course: itemData.course,
                        onRemove: onRemove
                    )
                case .module(let moduleitem):
                    PinnedModuleCard(
                        module: moduleitem,
                        course: itemData.course,
                        onRemove: onRemove
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
    let onRemove: () -> Void

    var body: some View {
        PinnedBaseCard(
            course: course,
            title: "",
            subtitle: announcement.message?.stripHTML().trimmingCharacters(in: .whitespacesAndNewlines),
            onRemove: onRemove,
            extraContent: { EmptyView() }
        )
    }
}


private struct PinnedFileCard: View {
    let file: File
    let course: Course
    let onRemove: () -> Void

    var body: some View {
        PinnedBaseCard(
            course: course,
            title: file.displayName,
            subtitle: nil,
            onRemove: onRemove,
            extraContent: { EmptyView() }
        )
    }
}


private struct PinnedAssignmentCard: View {
    let assignment: Assignment
    let course: Course
    let onRemove: () -> Void

    var body: some View {
        PinnedBaseCard(
            course: course,
            title: assignment.name,
            subtitle: nil,
            onRemove: onRemove,
            extraContent: { EmptyView() }
        )
    }
}


private struct PinnedQuizCard: View {
    let quiz: Quiz
    let course: Course
    let onRemove: () -> Void

    var body: some View {
        PinnedBaseCard(
            course: course,
            title: quiz.title,
            subtitle: nil,
            onRemove: onRemove
        ) {
            Group {
                if let dueDate = quiz.dueAt {
                    if dueDate < Date() {
                        Group {
                            Text("Due at \(dueDate.formatted())")
                                .strikethrough()
                                .foregroundColor(.gray)
                            Text("Past Due")
                                .bold()
                                .foregroundColor(.red)
                        }
                    } else {
                        Text("Due at \(dueDate.formatted())")
                    }
                } else {
                    Text("Due at Unknown")
                }
            }
        }
    }
}


private struct PinnedGradeCard: View {
    let assignment: Assignment
    let course: Course
    let onRemove: () -> Void

    var body: some View {
        PinnedBaseCard(
            course: course,
            title: assignment.name,
            subtitle: nil,
            onRemove: onRemove
        ) {
            Text(assignment.formattedGrade)
                .bold()
            + Text(" / \(assignment.formattedPointsPossible)")
        }
    }
}


private struct PinnedModuleCard: View {
    let module: ModuleItem
    let course: Course
    let onRemove: () -> Void

    var body: some View {
        PinnedBaseCard(
            course: course,
            title: module.title,
            subtitle: nil,
            onRemove: onRemove,
            extraContent: { EmptyView() }
        )
    }
}


extension View {
    func cardBackground(selected: Bool) -> some View {
        self
            .frame(width: 250)
			.frame(maxHeight: 100)
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 16.0)
                    .fill(.secondary.opacity(selected ? 0.30 : 0.15))
            }
    }
}


private struct PinnedBaseCard<Content: View>: View {
    @State private var isRemoving = false
    let course: Course
    let title: String
    let subtitle: String?
    let onRemove: () -> Void
    let extraContent: () -> Content

    var body: some View {
        ScrollView {
            HStack(spacing: 8) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isRemoving = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        onRemove()
                    }
                }) {
                    Image(systemName: isRemoving ? "circle.inset.filled" : "circle")
                        .foregroundStyle(course.rgbColors?.color ?? .accentColor)
                        .font(.title)
                }
                .buttonStyle(.plain)
                .disabled(isRemoving)

                VStack(alignment: .leading, spacing: 8) {
                    Text(course.displayName.uppercased())
                        .font(.caption)
                        .foregroundStyle(course.rgbColors?.color ?? .accentColor)

                    Text(title)
                        .font(.headline)
                        .fontDesign(.rounded)
                        .bold()

                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    extraContent()
                }

                Spacer()
            }
        }
    }
}
