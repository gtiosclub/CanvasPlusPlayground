//
//  CourseManager.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/24.
//

import SwiftUI

@Observable
class CourseManager {
    var courses = [Course]()

    func getCourses() async {
        guard let url = URL(string: "https://gatech.instructure.com//api/v1/courses?access_token=\(StorageKeys.accessTokenValue)&per_page=50&enrollment_state=active") else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("HTTP error: \(response)")
                return
            }

            let retCourses = try JSONDecoder().decode([Course].self, from: data)

            self.courses = retCourses
        } catch {
            print("Failed to fetch courses: \(error)")
        }
    }
}
