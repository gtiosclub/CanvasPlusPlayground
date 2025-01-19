//
//  AllAnnouncementsManager.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 1/19/25.
//

import Foundation

@Observable class AllAnnouncementsManager {
    var announcements: [Announcement] = []

    func fetchAnnouncements(courses: [Course]) async {
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
                guard announcement.course == nil,
                let contextCode = announcement.contextCode else {
                    return announcement
                }

                announcement.course = courses.first(where: { course in
                    contextCode.contains(course.id)
                })

                return announcement
            }.sorted { $0.createdAt ?? Date() > $1.createdAt ?? Date() }
        }
    }

    private func setBatchAnnouncements(
        _ announcements: [Announcement],
        courses: [Course]
    ) {
        let newAnnouncements = self.announcements + announcements.filter {
            !self.announcements.contains($0)
        }

        setAnnouncements(newAnnouncements, courses: courses)
    }
}
