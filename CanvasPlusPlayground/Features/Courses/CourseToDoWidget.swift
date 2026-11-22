//
//  CourseToDoWidget.swift
//  CanvasPlusPlayground
//

import SwiftUI

/// Course Home widget: the next 3 to-do items for this course, each with a checkbox that marks it done.
struct CourseToDoWidget: View {
    @Environment(ToDoListManager.self) private var toDoListManager
    @Environment(CourseManager.self) private var courseManager
    @Environment(NavigationModel.self) private var navigationModel

    let course: Course

    private var items: [ToDoItem] {
        Array(toDoListManager.displayedToDoItems.filter { $0.courseID.asString == course.id }.prefix(3))
    }

    var body: some View {
        CourseWidgetCard(
            title: "To-Do",
            systemImage: "checkmark.circle",
            accessoryTitle: "View All",
            destination: .allToDos
        ) {
            if items.isEmpty {
                Text("Nothing to do")
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        if item.id != items.first?.id {
                            Divider()
                        }
                        row(item)
                    }
                }
                .animation(.default, value: items.map(\.id))
            }
        }
        .task(id: course.id) {
            await toDoListManager.fetchToDoItems(courses: courseManager.activeCourses)
        }
    }

    private func row(_ item: ToDoItem) -> some View {
        HStack(spacing: 12) {
            Button {
                Task { await toDoListManager.complete(item) }
            } label: {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(.secondary, lineWidth: 1.5)
                    .frame(width: 28, height: 28)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Mark \(item.title) as done")

            Button {
                if let destination = item.navigationDestination() {
                    navigationModel.push(destination)
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.title3)
                            .lineLimit(1)
                        if let dueDate = item.dueDate {
                            Text("Due: \(dueDate.formatted(.dateTime.month(.abbreviated).day().hour().minute()))")
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10)
    }
}
