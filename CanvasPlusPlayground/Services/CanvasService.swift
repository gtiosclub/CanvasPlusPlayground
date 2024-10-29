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
    
    // TODO: new method + dispatch queue for multiple concurrent requests - Aziz
    
    func fetchBatch(_ requst: CanvasRequest) async -> [(data: Data, response: URLResponse)]? {
        
        
        var returnData:[(Data, URLResponse)] = []
        var currURL = requst.url;
        var count = 1
        while let url = currURL {
            var request = URLRequest(url: url)
            
            request.httpMethod = "GET"
            do {
                
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    print("HTTP error: $\(response)$")
                    return nil
                }
                
                returnData.append((data, response))
                
                guard let linkValue = httpResponse.allHeaderFields["Link"] as? String else {
                    print("No link field data")
                    break
                }
                
                let r = /<([^>]+)>; rel="next"/
                
                guard let match = try r.firstMatch(in: linkValue) else {
                    print("No matching regex")
                    break
                }
                
                let urlString = String(match.output.1).trimmingCharacters(in: .whitespacesAndNewlines)
                
                currURL = URL(string: urlString)
                currURL = currURL?.appending(queryItems: [
                    URLQueryItem(name: "access_token", value: StorageKeys.accessTokenValue)
                ])
                print("Fetch \(count) \(urlString)! ")
                count += 1
            } catch {
                print("Batch fetch error: \(error)")
                return nil
            }
        }
        
        return returnData
    }
}
