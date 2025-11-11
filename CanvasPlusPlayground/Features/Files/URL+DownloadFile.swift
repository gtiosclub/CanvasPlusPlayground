//
//  URL+DownloadFile.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 11/10/25.
//

import Foundation

extension URL {

    func downloadWebFile() async -> Data? {
        let request = URLRequest(url: self)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return nil
            }
#if DEBUG
            // for logging purposes in the request debug window
            NetworkRequestRecorder.shared.addRecord(request: request, response: response, responseBody: data)
#endif
            return data
        } catch {
            return nil
        }
    }
}
