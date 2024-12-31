//
//  APIRequest+Network.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/21/24.
//

import Foundation

extension APIRequest {
    // MARK: Helpers
    private func decodeData(arg: (Data, URLResponse)) throws -> QueryResult {
        let (data, _) = arg
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(QueryResult.self, from: data)
    }

}

// MARK: Network Requests

extension APIRequest {

    /// To fetch data from the Canvas API in batches!
    func fetch(
        onNewPage: ([Subject]) async -> Void = { _ in}
    ) async throws -> [Subject] {

        // If the request is to be paginated and fetched type T is a collection -> fetch batch by batch
        let fetched = try await fetchBatch(oneNewBatch: { batch in
            if let batch = try decodeData(arg: batch) as? [Subject] {
                await onNewPage(batch)
            } else if let batch = try decodeData(arg: batch) as? Subject {
                await onNewPage([batch])
            }
        }).map { batch in
            if let batch = try decodeData(arg: batch) as? [Subject] {
                return batch
            } else if let batch = try decodeData(arg: batch) as? Subject {
                return [batch]
            } else { throw NetworkError.failedToDecode(msg: "Batch decoding failed inside fetch()") }
        }

        let result = fetched.reduce([], +)
        return result
    }
}

extension APIRequest where QueryResult == Subject {

    /// To fetch data from the Canvas API, only!
    func fetch(
        onNewPage: ([Subject]) async -> Void = { _ in}
    ) async throws -> [Subject] {

        // API fetch
        let result = try await fetchResponse()

        let decoded = try decodeData(arg: result)

        await onNewPage([decoded])
        return [decoded]
    }
}

extension APIRequest {
    func fetchResponse() async throws -> (data: Data, response: URLResponse) {
        let url = self.url

        var urlRequest = URLRequest(url: url)

        urlRequest.httpMethod = "GET"

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw NetworkError.fetchFailed(msg: response.description)
            }

            return (data, response)
        } catch {
            throw NetworkError.fetchFailed(msg: error.localizedDescription)
        }
    }

    func fetchBatch(
        oneNewBatch: (((data: Data, url: URLResponse)) async throws -> Void)
    ) async throws -> [(data: Data, url: URLResponse)] {
        /*
         var currUrl =
         1) while loop
            a) people, newUrl = fetch(currUrl)
            b) onNewBatch(people)
            c) currUrl = newUrl
            d) if (newUrl = nil) break
         */

        var returnData: [(data: Data, url: URLResponse)] = []
        var currURL: URL? = self.url
        var count = 1
        while let url = currURL {
            var request = URLRequest(url: url)

            request.httpMethod = "GET"

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("HTTP error: $\(response)$")
                throw NetworkError.fetchFailed(msg: response.description)
            }
            returnData.append((data, response))

            try await oneNewBatch((data, response))

            guard let linkValue = httpResponse.allHeaderFields["Link"] as? String else {
                print("No link field data")
                break
            }

            let regEx = /<([^>]+)>; rel="next"/

            guard let match = try regEx.firstMatch(in: linkValue) else {
                print("No matching regex")
                break
            }

            let urlString = String(match.output.1).trimmingCharacters(in: .whitespacesAndNewlines)

            currURL = URL(string: urlString)
            currURL = currURL?.appending(queryItems: [
                URLQueryItem(name: "access_token", value: StorageKeys.accessTokenValue)
            ])

            count += 1
        }

        return returnData
    }
}
