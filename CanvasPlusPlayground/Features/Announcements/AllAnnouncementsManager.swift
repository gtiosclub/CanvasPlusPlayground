//
//  AllAnnouncementsManager.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 1/19/25.
//

import Foundation

@Observable class AllAnnouncementsManager: ListWidgetDataSource, BigNumberWidgetDataSource {
    struct CourseAnnouncement: Hashable, Identifiable {
        var id: String {
            announcement.id
        }
        let announcement: DiscussionTopic
        let course: Course?

        func hash(into hasher: inout Hasher) {
            hasher.combine(announcement.id)
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.announcement.id == rhs.announcement.id
        }
    }

    var courseAnnouncements = Set<CourseAnnouncement>()
    var displayedAnnouncements: [CourseAnnouncement] {
        get {
            courseAnnouncements
                .filter { $0.announcement.published }
                .sorted {
                    $0.announcement.date ?? .distantPast > $1.announcement.date ?? .distantPast
                }
        }
        set {
            self.courseAnnouncements = Set(newValue)
        }
    }

    // ListWidgetDataSource
    var widgetData: [ListWidgetData] {
        get {
            displayedAnnouncements.map {
                .init(
                    id: $0.id,
                    title: $0.announcement.title ?? "",
                    description: $0.announcement.message?
                        .stripHTML()
                        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                )
            }
        }
        set { }
    }
    var fetchStatus: WidgetFetchStatus = .loading

    func fetchAnnouncements(courses: [Course]) async {
        guard !courses.isEmpty else { return }

        let courseIds = courses.map { $0.id }

        await withTaskGroup(of: Void.self) { group in
            for courseId in courseIds {
                group.addTask(priority: .userInitiated) { [weak self] in
                    let request = CanvasRequest.getDiscussionTopics(
                        courseId: courseId,
                        orderBy: .position,
                        onlyAnnouncements: true,
                        perPage: 25
                    )

                    let announcements: [DiscussionTopic]? = try? await CanvasService.shared.loadAndSync(
                        request,
                        onCacheReceive: { (cached: [DiscussionTopic]?) in
                            guard let cached else { return }

                            self?.addAnnouncements(cached, courses: courses)
                        },
                        loadingMethod: .all(onNewPage: { batchAnnouncements in
                            self?.addAnnouncements(batchAnnouncements, courses: courses)
                        })
                    )

                    guard let announcements else {
                        LoggerService.main.error("Failed to fetch announcements.")
                        return
                    }

                    self?.addAnnouncements(announcements, courses: courses)
                }
            }
        }
    }

    private func addAnnouncements(_ announcements: [DiscussionTopic], courses: [Course]) {
        DispatchQueue.main.async {
            self.displayedAnnouncements += announcements.map { announcement in
                guard let courseId = announcement.courseId else {
                    return CourseAnnouncement(announcement: announcement, course: nil)
                }

                let course = courses.first(where: { course in
                    courseId == course.id
                })

                return CourseAnnouncement(announcement: announcement, course: course)
            }
        }
    }

    // MARK: - ListWidgetDataSource
    func fetchData(context: WidgetContext) async throws {
        guard let courseManager = context.courseManager else {
            fetchStatus = .error
            return
        }

        fetchStatus = .loading
        await fetchAnnouncements(courses: courseManager.favoritedCourses)
        fetchStatus = .loaded
    }

    func destinationView(for data: ListWidgetData) -> NavigationModel.Destination {
        guard let announcement = displayedAnnouncements.first(where: {
            $0.id == data.id
        })?.announcement else { return .allAnnouncements }

        return .announcement(announcement)
    }

    // MARK: - BigNumberWidgetDataSource

    // Only display the number of announcements from courses that are CURRENTLY active
    var bigNumber: Decimal? { Decimal(courseAnnouncements.count { announcement in
        announcement.announcement.readState == .unread &&
        !(announcement.course?.isPastEnrollment ?? false)
    })}
}
