//
//  AllAnnouncementsManager.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 1/19/25.
//

import Foundation

@Observable class AllAnnouncementsManager {
    var announcements: [(Announcement, Course?)] = []

    func fetchAnnouncements(courses: [Course]) async {
        guard !courses.isEmpty else { return }

        let courseIds = courses.map { $0.id }

        let announcements: [Announcement]? = try? await CanvasService.shared.loadAndSync(
            CanvasRequest.getAnnouncements(courseIds: courseIds),
            onCacheReceive: { (cached: [Announcement]?) in
                guard let cached else { return }

                setAnnouncements(cached, courses: courses)
            },
            onNewBatch: { batchAnnouncements in
                setBatchAnnouncements(batchAnnouncements, courses: courses)
            }
        )

        guard let announcements else {
            print("Failed to fetch announcements.")
            return
        }

        setAnnouncements(announcements, courses: courses)
    }

    private func setAnnouncements(_ announcements: [Announcement], courses: [Course]) {
        DispatchQueue.main.async {
            self.announcements = announcements.map { announcement in
                guard let contextCode = announcement.contextCode else {
                    return (announcement, nil)
                }

                let course = courses.first(where: { course in
                    contextCode.contains(course.id)
                })

                return (announcement, course)
            }.sorted { $0.0.createdAt ?? Date() > $1.0.createdAt ?? Date() }
        }
    }

    private func setBatchAnnouncements(
        _ announcements: [Announcement],
        courses: [Course]
    ) {
        let newAnnouncements = self.announcements.map(\.0) + announcements.filter {
            !self.announcements.map(\.0).contains($0)
        }

        setAnnouncements(newAnnouncements, courses: courses)
    }
}
