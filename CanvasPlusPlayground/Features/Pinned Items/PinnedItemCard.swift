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
		ScrollView {
			HStack(alignment: .top, spacing: 8) {
				Button(action: onRemove) {
					Image(systemName: "circle")
						.foregroundStyle(course.rgbColors?.color ?? .accentColor)
						.font(.title)
				}
				.buttonStyle(.plain)
				
				VStack(alignment: .leading, spacing: 8) {
					Text(course.displayName.uppercased())
						.font(.caption)
						.foregroundStyle(course.rgbColors?.color ?? .accentColor)
					
					VStack(alignment: .leading, spacing: 3) {
						Text(announcement.title ?? "No Title")
							.font(.headline)
							.fontDesign(.rounded)
							.bold()
							.lineLimit(1)
						
						Text(
							announcement.message?
								.stripHTML()
								.trimmingCharacters(in: .whitespacesAndNewlines)
							?? ""
						)
						.font(.subheadline)
						.foregroundStyle(.secondary)
						.lineLimit(2) 
					}
				}
				
				Spacer()
			}
		}
	}
}

private struct PinnedFileCard: View {
    let file: File
    let course: Course
	let onRemove: () -> Void
    var body: some View {
		ScrollView {
			HStack(spacing: 8) {
				Button(action: onRemove) {
					Image(systemName: "circle")
						.foregroundStyle(course.rgbColors?.color ?? .accentColor)
						.font(.title)
				}
				.buttonStyle(.plain)
				
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
}

private struct PinnedAssignmentCard: View {
    let assignment: Assignment
    let course: Course
	let onRemove: () -> Void
    var body: some View {
		ScrollView {
			HStack(spacing: 8) {
				Button(action: onRemove) {
					Image(systemName: "circle")
						.foregroundStyle(course.rgbColors?.color ?? .accentColor)
						.font(.title)
				}
				.buttonStyle(.plain)
				
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
}

private struct PinnedQuizCard: View {
	let quiz: Quiz
	let course: Course
	let onRemove: () -> Void
	var body: some View {
		ScrollView {
			HStack(spacing: 8) {
				Button(action: onRemove) {
					Image(systemName: "circle")
						.foregroundStyle(course.rgbColors?.color ?? .accentColor)
						.font(.title)
				}
				.buttonStyle(.plain)
				
				VStack(alignment: .leading, spacing: 8) {
					Text(course.displayName.uppercased())
						.font(.caption)
						.foregroundStyle(course.rgbColors?.color ?? .accentColor)
					
					Text(quiz.title)
						.font(.headline)
						.fontDesign(.rounded)
						.bold()
					if let dueDate = quiz.dueAt {
						if dueDate < Date() {
							Text("Due at \(dueDate.formatted(Date.FormatStyle()))")
								.strikethrough()
								.foregroundColor(.gray)
							Text("Past Due")
								.bold()
								.foregroundColor(.red)
						} else {
							Text("Due at \(dueDate.formatted(Date.FormatStyle()))")
						}
					} else {
						Text("Due at Unknown")
					}
				}
				
				Spacer()
			}
		}
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
