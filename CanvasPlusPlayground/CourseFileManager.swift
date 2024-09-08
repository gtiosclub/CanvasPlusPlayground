//
//  CourseFileManager.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/8/24.
//

import SwiftUI

@Observable
class CourseFileManager {
    private let courseID: Int?
    var files = [File]()

    init(courseID: Int?) {
        self.courseID = courseID
    }

    func fetchFiles() async {
        guard let courseID else { return }

        guard let url = URL(string: "https://gatech.instructure.com/api/v1/courses/\(courseID)/files?access_token=\(StorageKeys.accessTokenValue)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("HTTP error: \(response)")
                return
            }

            let retFiles = try JSONDecoder().decode([File].self, from: data)

            self.files = retFiles
        } catch {
            print("Failed to fetch files: \(error)")
        }
    }
}
