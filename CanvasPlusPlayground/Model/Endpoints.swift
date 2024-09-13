//
//  Endpoints.swift
//  CanvasPlusPlayground
//
//  Created by Max Ko on 9/13/24.
//

import Foundation

let access_token = ""

func callAPi(url: String, body: String?) {
    
    let request_url = URL(string: url)!
    var request = URLRequest(url: request_url)
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let httpResponse = response as? HTTPURLResponse {
            // Access the headers from the HTTP response
            if let linkHeader = httpResponse.allHeaderFields["Link"] as? String {
                print("Link Header: \(linkHeader)")
            } else {
                print("Link header not found")
            }
        }
        
        if let data = data {
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                    print(jsonArray) // This is your list of JSON objects
                } else {
                    print("Failed to parse JSON as array")
                }
            } catch {
                print("Failed to decode JSON: \(error)")
            }
        }
        if let error = error {
            print("HTTP Request Failed \(error)")
        }
    }

    task.resume()
    
}

func getEnrollements(course_id: Int) {

    var url = "https://gatech.instructure.com/api/v1/courses/\(course_id)/enrollments?&per_page=100&access_token=\(access_token)";
    callAPi(url: url, body: nil)
}
