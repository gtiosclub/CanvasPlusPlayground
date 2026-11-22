//
//  CloudEgress.swift
//  CanvasPlusPlayground
//

import Foundation

/// The single place a Tier 2 request leaves the device.
///
/// Every request is checked against the student's settings (on, consented, has a key, every
/// course it draws from is opted in) and redacted before it's sent. `GeminiProvider` has no other
/// way to reach the network, so these rules can't be skipped by a feature.
struct CloudEgress: Sendable {
    typealias Transport = @Sendable (URLRequest) async throws -> (Data, URLResponse)

    let settings: CloudSettings
    /// Built fresh for each request, so names from rosters synced since the last request are covered.
    let makeRedactor: @Sendable () async -> EgressRedactor
    let transport: Transport
    /// How long one model gets before the next is tried.
    var requestTimeout: TimeInterval = 25

    init(
        settings: CloudSettings = .shared,
        makeRedactor: @escaping @Sendable () async -> EgressRedactor = { await EgressRedactor.fromCachedRosters() },
        transport: @escaping Transport = { try await URLSession.shared.data(for: $0) }
    ) {
        self.settings = settings
        self.makeRedactor = makeRedactor
        self.transport = transport
    }

    /// Checks the settings, redacts `request`, sends it and decodes the reply.
    ///
    /// - Parameter courseIDs: Every course whose content is in `request`. One that isn't opted in
    ///   refuses the whole request before anything is sent.
    func generateContent(_ request: GeminiAPI.Request, courseIDs: Set<String>) async throws -> GeminiAPI.Response {
        let apiKey = try authorize(courseIDs: courseIDs)
        let redactor = await makeRedactor()
        let body = try JSONEncoder().encode(request.redacted(with: redactor.redact))

        // The chosen model first, then the fast Flash-Lite alias if it's busy or slow. Flash models
        // can sit on a request for most of a minute under load; Flash-Lite usually answers in ~1 s.
        var models = [settings.model]
        if settings.model != CloudSettings.fallbackModel { models.append(CloudSettings.fallbackModel) }

        var data = Data()
        var status = 0
        for (index, model) in models.enumerated() {
            let url = GeminiAPI.baseURL.appending(path: "\(model):generateContent")
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.timeoutInterval = requestTimeout
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            // A header, not a query parameter, so the key never ends up in URL logs.
            urlRequest.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
            urlRequest.httpBody = body

            let isLast = index == models.count - 1
            do {
                let (responseData, response) = try await transport(urlRequest)
                data = responseData
                status = (response as? HTTPURLResponse)?.statusCode ?? 0
            } catch let error as URLError where error.code == .timedOut && !isLast {
                continue
            } catch let error as URLError where error.code == .timedOut {
                throw CloudEgressError.busy
            }

            if Self.isBusy(status), !isLast { continue }
            break
        }

        guard (200..<300).contains(status) else {
            let message = (try? JSONDecoder().decode(GeminiAPI.ErrorEnvelope.self, from: data))?.error.message
            throw CloudEgressError.http(status: status, message: message)
        }

        do {
            return try JSONDecoder().decode(GeminiAPI.Response.self, from: data)
        } catch {
            throw CloudEgressError.malformedResponse
        }
    }

    /// Overloaded, failing for a moment, or rate limited: worth trying another model.
    static func isBusy(_ status: Int) -> Bool {
        status == 503 || status == 500 || status == 429
    }

    /// The API key, if the settings allow a request drawing on `courseIDs`.
    func authorize(courseIDs: Set<String>) throws -> String {
        guard settings.isEnabled else { throw CloudEgressError.disabled }
        guard settings.consentAcceptedAt != nil else { throw CloudEgressError.consentRequired }
        guard let apiKey = settings.apiKey else { throw CloudEgressError.missingAPIKey }

        let blocked = courseIDs.subtracting(settings.optedInCourseIDs)
        guard blocked.isEmpty else { throw CloudEgressError.courseNotShared(blocked.sorted()) }

        return apiKey
    }
}

enum CloudEgressError: Error, Equatable, LocalizedError {
    case disabled
    case consentRequired
    case missingAPIKey
    case courseNotShared([String])
    case http(status: Int, message: String?)
    case malformedResponse
    /// Every model tried was overloaded or too slow.
    case busy

    var errorDescription: String? {
        switch self {
        case .disabled:
            "Cloud Intelligence is off. Turn it on in Settings to use it."
        case .consentRequired:
            "Review and accept how Cloud Intelligence uses your data in Settings first."
        case .missingAPIKey:
            "Add your Gemini API key in Settings → Cloud Intelligence."
        case .courseNotShared:
            "This uses a course you haven't shared with Cloud Intelligence. You can share it in Settings."
        case let .http(status, message):
            message.map { "Gemini returned an error (\(status)): \($0)" } ?? "Gemini returned an error (\(status))."
        case .malformedResponse:
            "Gemini sent a reply the app couldn't read."
        case .busy:
            "Gemini is busy right now. Try again in a minute."
        }
    }

    private static let rejectedKeyMessage = "Gemini didn't accept your API key. Check it in Settings → Cloud Intelligence."

    /// The provider-neutral error features already handle.
    var agentError: AgentModelError {
        switch self {
        case .disabled, .consentRequired, .missingAPIKey, .courseNotShared:
            .unavailable(errorDescription ?? "")
        case .http(429, _), .http(503, _), .busy:
            .rateLimited
        case .http(400, let message) where message?.localizedCaseInsensitiveContains("API key") == true:
            .unavailable(Self.rejectedKeyMessage)
        case .http(401, _), .http(403, _):
            .unavailable(Self.rejectedKeyMessage)
        case .http, .malformedResponse:
            .other(errorDescription ?? "")
        }
    }
}
