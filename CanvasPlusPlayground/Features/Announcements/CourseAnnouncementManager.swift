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
    var announcements: [Announcement]
    
    init(course: Course) {
        self.course = course
        self.announcements = []
    }
    
    func fetchAnnouncements() async {
        let announcements: [Announcement]? = try? await CanvasService.shared.loadAndSync(
            .getAnnouncements(courseId: courseId),
            descriptor: .init(sortBy: [.init(\.createdAt, order: .reverse)]),
            onCacheReceive: { (cached: [Announcement]?) in
                guard let cached else { return }
                
                self.announcements = cached
            }
        )
        
        guard let announcements else {
            print("Failed to fetch announcements.")
            return
        }
        
        self.announcements = announcements.reversed()
        
    }
}