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
        Set(listManager.toDoItems.compactMap(\.course))
            .sorted { $0.displayName < $1.displayName }
    }

    private var displayedResults: [ToDoItem] {
        if let filterCourse {
            listManager.displayedToDoItems.filter { $0.course == filterCourse }
        } else {
            listManager.displayedToDoItems
        }
    }

    var body: some View {
        List(displayedResults, selection: $selectedItem) { item in
            NavigationLink(value: itemTypeToDestination(for: item)) {
                ToDoItemRow(item: item) {
                    Task {
                        await listManager.ignoreToDoItem(item)
                        await loadItems()
                    }
                }
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
        .task(id: courseManager.activeCourses) {
            await loadItems()
        }
        .refreshable {
            await loadItems()
        }
        .overlay {
            if displayedResults.isEmpty {
                ContentUnavailableView("No To-Do Items", systemImage: "checklist.checked")
            }
        }
        .toolbar {
            if !displayedResults.isEmpty {
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
        await listManager.fetchToDoItems(courses: courseManager.activeCourses)
        isLoading = false
    }

    private func itemTypeToDestination(for item: ToDoItem) -> NavigationModel.Destination? {
        if let type = item.itemType {
            switch type {
            case .assignment(let assignment):
                return .assignment(assignment)
            case .quiz:
                // TODO: Support Quiz Detail View
                return nil
            }
        }

        return nil
    }
}

private struct ToDoItemRow: View {
    @Environment(ToDoListManager.self) private var listManager
    @Environment(NavigationModel.self) private var navigationModel

    let item: ToDoItem
    let onIgnoreItem: () -> Void

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
                    navigationModel.selectedNavigationPage = .course(id: course.id)
                }
            }

            ignoreItemButton
        }
        .swipeActions(edge: .trailing) {
            ignoreItemButton
        }
    }

    private var courseName: some View {
        Text(item.course?.displayName.uppercased() ?? "")
            .font(.caption)
            .foregroundStyle(item.course?.rgbColors?.color ?? .accentColor)
    }

    private var ignoreItemButton: some View {
        Button("Ignore Item", systemImage: "eye.slash", role: .destructive) {
            onIgnoreItem()
        }
    }
}
