//
//  CourseAnnouncementManager.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 9/12/24.
//

import Foundation

@Observable class CourseAnnouncementManager {
    let course: Course
    var courseId: String { course.id }

    var announcements: Set<DiscussionTopic>
    var displayedAnnouncements: [DiscussionTopic] {
        announcements
            .filter { $0.published }
            .sorted {
                $0.date ?? .distantPast > $1.date ?? .distantPast
            }
    }

    init(course: Course) {
        self.course = course
        self.announcements = []
    }

    func fetchAnnouncements() async {
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

                self.setAnnouncements(cached)
            },
            loadingMethod: .all(onNewPage: { topics in
                self.addAnnouncements(topics)
            })
        )

        guard let announcements else {
            LoggerService.main.error("Failed to fetch announcements.")
            return
        }

        setAnnouncements(announcements)
    }

    func setAnnouncements(_ announcements: [DiscussionTopic]) {
        DispatchQueue.main.async {
            self.announcements = Set(announcements)
        }
    }

    func addAnnouncements(_ announcements: [DiscussionTopic]) {
        DispatchQueue.main.async {
            self.announcements.formUnion(announcements)
        }
    }
}
