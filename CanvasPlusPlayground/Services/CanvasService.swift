//
//  CanvasService.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 9/14/24.
//

import Foundation

struct CanvasService {
    static let shared = CanvasService()
    
    func fetch(_ request: CanvasRequest) async -> (data: Data, response: URLResponse)? {
        guard let url = request.url else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("HTTP error: \(response)")
                return nil
            }
            
            return (data, response)
        } catch {
            print("Fetch error: \(error)")
            return nil
        }
    }
}
