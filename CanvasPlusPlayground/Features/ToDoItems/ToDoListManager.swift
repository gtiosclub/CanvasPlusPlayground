//
//  ToDoListManager.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 3/24/25.
//

import SwiftUI
import Combine
import SwiftData

@Observable
class ToDoListManager: ListWidgetDataSource, BigNumberWidgetDataSource {
    var toDoItems: Set<ToDoItem> = []
    var toDoItemCount: Int?
    var errorMessage: String?

    var displayedToDoItems: [ToDoItem] {
        Array(toDoItems).sorted { $0.dueDate ?? Date() < $1.dueDate ?? Date() }
    }

    // ListWidgetDataSource
    var fetchStatus: WidgetFetchStatus = .loading
    var widgetData: [ListWidgetData] {
        get {
            displayedToDoItems.map {
                .init(
                    id: $0.id,
                    title: $0.title,
                    description: "Due \($0.dueDate?.formatted(date: .abbreviated, time: .omitted) ?? "-")"
                )
            }
        }
        set { }
    }

    func fetchToDoItemCount() async {
        let request = CanvasRequest.getToDoItemCount(
            include: [.ungradedQuizzes]
        )

        do {
            let count: [ToDoItemCount]? = try await CanvasService.shared
                .loadAndSync(
                    request
                )

            // TODO: If we support grading assignments, add that count
            self.toDoItemCount = count?.first?.assignmentsNeedingSubmitting
        } catch {
            LoggerService.main.error("Failed to fetch to-do item count: \(error)")
        }
    }

    func fetchToDoItems(courses: [Course]) async {
        let request = CanvasRequest.getToDoItems(include: [.ungradedQuizzes])

        do {
            // Only load from network, not cache
            let items: [ToDoItem] = try await CanvasService.shared
                .syncWithAPI(
                    request,
                    loadingMethod: .all(onNewPage: { items in
                        Task { @MainActor in
                            self.addItems(items, courses: courses)
                        }
                    })
                )

            Task { @MainActor in
                self.addItems(
                    items,
                    courses: courses,
                    replaceExisting: true
                )
                self.errorMessage = nil
            }
        } catch {
            LoggerService.main.error("Failed to fetch to-do items: \(error)")
            Task { @MainActor in
                self.errorMessage = "Failed to load to-do items: \(error.localizedDescription)"
            }
        }

        Task { @MainActor in
            self.loadUserCreatedItems(courses: courses)
        }
    }

    func ignoreToDoItem(_ item: ToDoItem) async {
        // We can either use the ignoreURL or the ignorePermanentlyURL.
        // ignoreURL will add the item back if the item is updated in the future.
        // ignorePermanentlyURL will remove the item from the list forever.

        let request = CanvasRequest.ignoreToDoItem(ignoreURL: item.ignoreURL)

        do {
            try await CanvasService.shared.fetch(request)
        } catch {
            LoggerService.main.error("Failed to ignore todo item: \(error)")
        }
    }

    private func addItems(
        _ newItems: [ToDoItem],
        courses: [Course],
        replaceExisting: Bool = false
    ) {
        // TODO: If we support grading assignments, do not filter.
        let newItems = newItems.filter { $0.type == .submitting }

        newItems.forEach { item in
            item.course = courses.first { $0.id == item.courseID.asString }
        }

        if replaceExisting {
            // Keep any locally-created items — they don't come back from the API.
            let userCreated = self.toDoItems.filter { $0.isUserCreated }
            self.toDoItems = Set(newItems).union(userCreated)
        } else {
            self.toDoItems.formUnion(newItems)
        }
    }

    /// Persists a user-created item to SwiftData and adds it to the live set.
    @MainActor
    func addUserCreatedItem(_ item: ToDoItem, course: Course?) {
        item.course = course
        ModelContext.shared.insert(item)
        try? ModelContext.shared.save()
        toDoItems.insert(item)
    }

    /// Loads user-created items persisted in SwiftData into the live set.
    @MainActor
    func loadUserCreatedItems(courses: [Course]) {
        let descriptor = FetchDescriptor<ToDoItem>(
            predicate: #Predicate { $0.isUserCreated == true }
        )
        guard let items = try? ModelContext.shared.fetch(descriptor) else { return }
        items.forEach { item in
            item.course = courses.first { $0.id == item.courseID.asString }
        }
        toDoItems.formUnion(items)
    }

    // MARK: ListWidgetDataSource
    func fetchData(context: WidgetContext) async throws {
        guard let courseManager = context.courseManager else {
            fetchStatus = .error
            return
        }

        fetchStatus = .loading

        async let fetchItems =  fetchToDoItems(courses: courseManager.favoritedCourses)
        async let fetchCount = fetchToDoItemCount()

        await fetchItems
        await fetchCount
        
        fetchStatus = .loaded
    }

    func destinationView(for data: ListWidgetData) -> NavigationModel.Destination {
        return if let item = displayedToDoItems.first(where: { $0.id == data.id }) {
            item.navigationDestination() ?? .allToDos
        } else {
            .allToDos
        }
    }

    // MARK: - BigNumberWidgetDataSource

    var bigNumber: Decimal? {
        guard let toDoItemCount else { return nil }
        return Decimal(toDoItemCount)
    }
}
