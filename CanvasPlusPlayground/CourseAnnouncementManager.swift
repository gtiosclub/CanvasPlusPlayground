//
//  CourseAnnouncementManager.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 9/12/24.
//

import Foundation

@Observable class CourseAnnouncementManager {
    let courseId: Int?
    var announcements: [Announcement]
    
    init(courseId: Int?) {
        self.courseId = courseId
        self.announcements = []
    }
    
    func fetchAnnouncements() async {
        guard let url = URL(string: "https://gatech.instructure.com/api/v1/announcements?access_token=\(StorageKeys.accessTokenValue)&context_codes[]=course_\(courseId ?? 0)") else {
            return
        }
        
        let request = URLRequest(url: url)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { fatalError("Error while fetching data") }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            var announcements = try decoder.decode(([Announcement]).self, from: data)
            
            self.announcements = announcements
            announcements.sort { first, second in
                first.createdAt ?? Date() < second.createdAt ?? Date()
            }
            print("found \(announcements.count) announcements")
            
        } catch {
            print("Error requesting announcements: \(error)")
        }
    }
}
