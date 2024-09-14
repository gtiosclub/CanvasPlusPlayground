//
//  CourseGradeManager.swift
//  CanvasPlusPlayground
//
//  Created by Songyuan Liu on 9/13/24.
//

import Foundation

@Observable
class CourseGradeManager {
    var enrollments = [Enrollment]()
    
    func fetchEnrollments() async {
        guard let url = URL(string: "https://gatech.instructure.com//api/v1/users/self/enrollments?access_token=\(StorageKeys.accessTokenValue)&state[]=active") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("HTTP error: \(response)")
                return
            }
            
            let retEnrollments = try JSONDecoder().decode([Enrollment].self, from: data)
            
            self.enrollments = retEnrollments
            
            print("Fetch enrollment succeed: \(enrollments)")
        } catch {
            print("Failed to fetch enrollments: \(error)")
        }
    }
    
    
    
}
