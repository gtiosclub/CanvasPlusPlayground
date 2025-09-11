//
//  APIRequest+Network.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/21/24.
//

import Foundation

extension APIRequest {
    // MARK: Helpers
    private func decodeData(_ data: Data) throws -> QueryResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(QueryResult.self, from: data.isEmpty ? .emptyJSON : data)
    }
}

// MARK: Network Requests

extension APIRequest {
    /// To fetch data from the Canvas API in batches!
    func fetch(
        loadingMethod: LoadingMethod<Self>,
        onNewPage: ([Subject]) async -> Void = { _ in }
    ) async throws -> [Subject] {
        let fetched: [(data: Data, url: URLResponse)]

        switch loadingMethod {
        case .page(let order):
            fetched = [try await fetchResponse(at: order)]
        case .all:         // If the request is to be paginated
            fetched = try await fetchPages(
                onNewPage: { page in
                    guard let subjects = try decodeAsSubjects(page.data) else { return }
                    await onNewPage(subjects)
                }
            )
        }

        let result = try fetched.compactMap { data, _ in
            try decodeAsSubjects(data)
        }

        return result.reduce([], +)
    }

    /// Attempts to decode the given data into either `Subject` or `[Subject]`.
    private func decodeAsSubjects(_ data: Data) throws -> [Subject]? {
        if let page = try decodeData(data) as? [Subject] {
            return page
        } else if let page = try decodeData(data) as? Subject {
            return [page]
        } else {
            LoggerService.main.error("Failed to decode \(data) into [\(Subject.self)] or \(Subject.self).")
            return nil
        }
    }
}

extension APIRequest where QueryResult == Subject {
    /// To fetch data from the Canvas API, only!
    func fetch(
        loadingMethod: LoadingMethod<Self>,
        onNewPage: ([Subject]) async -> Void = { _ in }
    ) async throws -> [Subject] {
        let result = try await fetchResponse()

        let decoded = try decodeData(result.data)

        await onNewPage([decoded])
        return [decoded]
    }
}

extension APIRequest {
    func fetchResponse(at page: Int? = nil) async throws -> (data: Data, url: URLResponse) {
        var url = self.url
        if let page {
            url = url.appending(queryItems: [
                URLQueryItem(name: "page", value: "\(page)")
            ])
        }

        var urlRequest = URLRequest(url: url)

        urlRequest.httpMethod = self.method.rawValue
        urlRequest.httpBody = self.body
        urlRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(contentLength, forHTTPHeaderField: "Content-Length")
        urlRequest.setValue("Bearer \(StorageKeys.accessTokenValue)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        #if DEBUG
        // for logging purposes in the request debug window
        NetworkRequestRecorder.shared.addRecord(request: urlRequest, response: response, responseBody: data)
        #endif
        
        guard let httpResponse = response as? HTTPURLResponse else {
            LoggerService.main.error("HTTP error: $\(response)$")
            throw URLError(.badServerResponse)
        }

        guard httpResponse.status?.responseType == .success else {
           LoggerService.main.error("HTTP error: $\(httpResponse)$")
           throw httpResponse.status ?? .unknown
        }

       return (data, response)
    }

    func fetchPages(
        onNewPage: (((data: Data, url: URLResponse)) async throws -> Void)
    ) async throws -> [(data: Data, url: URLResponse)] {
        /*
         var currPage
         1) loop
            a) people, newUrl = fetch(currUrl)
            b) onNewPage(people)
            c) if nextPage == nil
                break
            c) currPage = nextPage
         */

        var returnData: [(data: Data, url: URLResponse)] = []
        var currPage: Int?
        while true {
            let (data, response) = try await fetchResponse(at: currPage)
            returnData.append((data, response))
            try await onNewPage((data, response))

            guard let httpResponse = response as? HTTPURLResponse, let linkValue = httpResponse.allHeaderFields["Link"] as? String else {
                LoggerService.main.error("No link field data")
                break
            }

            let regEx = /<([^>]+)>; rel="next"/

            // Parse for next page number
            guard let match = try regEx.firstMatch(in: linkValue),
                  let nextUrl = URL(string: String(match.output.1)),
                  let components = URLComponents(url: nextUrl, resolvingAgainstBaseURL: true),
                  let pageItem = components.queryItems?.first(where: { $0.name == "page" }),
                  let nextPage = Int(pageItem.value ?? "") else {
                LoggerService.main.error("No matching regex")
                break
            }

            currPage = nextPage
        }

        return returnData
    }
}
