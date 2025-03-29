//
//  ToDoListView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 3/24/25.
//

import SwiftUI

struct ToDoListView: View {
    @Environment(CourseManager.self) private var courseManager
    @Environment(ToDoListManager.self) private var listManager

    @State private var selectedItem: ToDoItem?
    @State private var isLoading = false
    @State private var filterCourse: Course?

    private var filterCourseOptions: [Course] {
        listManager.toDoItems.compactMap(\.course)
    }

    private var displayedResults: [ToDoItem] {
        if let filterCourse {
            listManager.toDoItems.filter { $0.course == filterCourse }
        } else {
            listManager.toDoItems
        }
    }

    var body: some View {
        List(displayedResults, selection: $selectedItem) { item in
            NavigationLink(value: itemTypeToDestination(for: item)) {
                ToDoItemRow(item: item)
            }
            .tag(item)
        }
        #if os(iOS)
        .onAppear {
            selectedItem = nil
        }
        #endif
        .navigationTitle("To-Do List")
        .listStyle(.inset)
        .task(id: courseManager.allCourses) {
            await loadItems()
        }
        .refreshable {
            await loadItems()
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                #if os(iOS)
                Menu {
                    courseFilterPicker
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .symbolVariant(filterCourse != nil ? .fill : .none)
                }
                #else
                courseFilterPicker
                #endif
            }
        }
        .statusToolbarItem("To-Dos", isVisible: isLoading)
    }

    private var courseFilterPicker: some View {
        Picker(
            selection: $filterCourse.animation()
        ) {
            Text("All Items").tag(Optional<Course>.none)

            ForEach(filterCourseOptions) { course in
                Text(course.displayName).tag(course)
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .symbolVariant(filterCourse != nil ? .fill : .none)
        }
        .labelStyle(.iconOnly)
    }

    private func loadItems() async {
        isLoading = true
        await listManager.fetchToDoItemCount()
        await listManager.fetchToDoItems(courses: courseManager.allCourses)
        isLoading = false
    }

    private func itemTypeToDestination(for item: ToDoItem) -> NavigationModel.Destination? {
        if let type = item.itemType {
            switch type {
            case .assignment(let assignment):
                return .assignment(assignment)
            case .quiz(let _):
                // TODO: Support Quiz Detail View
                return nil
            }
        }

        return nil
    }
}

private struct ToDoItemRow: View {
    @Environment(NavigationModel.self) private var navigationModel
    let item: ToDoItem

    var body: some View {
        VStack(alignment: .leading) {
            courseName

            Text(item.title)
                .bold()

            if let dueDate = item.dueDate {
                Text("Due ")
                    .fontWeight(.semibold)
                +
                Text(dueDate, style: .date)
                +
                Text(" at ")
                +
                Text(dueDate, style: .time)
            }
        }
        .contextMenu {
            if let course = item.course {
                Button("Go to Course...", systemImage: "folder") {
                    navigationModel.navigationPath.append(
                        NavigationModel.Destination.course(course)
                    )
                }
            }
        }
    }

    private var courseName: some View {
        Text(item.course?.displayName.uppercased() ?? "")
            .font(.caption)
            .foregroundStyle(item.course?.rgbColors?.color ?? .accentColor)
    }
}
