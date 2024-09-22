//
//  PeopleManager.swift
//  CanvasPlusPlayground
//
//  Created by Max Ko on 9/22/24.
//

import SwiftUI

@Observable
class PeopleManager {
    private let courseID: Int?
    var enrollments = [Enrollment]()
    var users = [User] ()

    init(courseID: Int?) {
        self.courseID = courseID
        self.enrollments = []
        self.users = []
    }

    func fetchPeople() async {
        guard let courseID, let (data, response) = await CanvasService.shared.fetch(.getPeople(courseId: courseID, bookmark: "")) else {
            print("Failed to fetch files.")
            return
        }
        
        do {
            self.enrollments = try JSONDecoder().decode([Enrollment].self, from: data)
                        
            for enrollment in enrollments {
                if let user = enrollment.user {
                    users.append(user)
                }
            }
            
            print("Response: \(response)")
            
            // TODO: continue to query for next page and append to our lists
            
        } catch {
            print(error)
        }
    }
}
