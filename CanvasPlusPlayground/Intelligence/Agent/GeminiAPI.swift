//
//  GeminiAPI.swift
//  CanvasPlusPlayground
//

import Foundation

/// The parts of Gemini's `generateContent` REST API the provider uses.
/// https://ai.google.dev/api/generate-content
enum GeminiAPI {
    static let baseURL = URL(string: "https://generativelanguage.googleapis.com/v1beta/models")!

    struct Request: Codable, Hashable, Sendable {
        var systemInstruction: Content?
        var contents: [Content]
        var tools: [ToolSet]?
        var generationConfig: GenerationConfig?
    }

    struct Content: Codable, Hashable, Sendable {
        /// "user" or "model".
        var role: String?
        var parts: [Part]

        static func user(_ text: String) -> Content {
            Content(role: "user", parts: [Part(text: text)])
        }
    }

    struct Part: Codable, Hashable, Sendable {
        var text: String?
        var functionCall: FunctionCall?
        var functionResponse: FunctionResponse?

        init(text: String? = nil, functionCall: FunctionCall? = nil, functionResponse: FunctionResponse? = nil) {
            self.text = text
            self.functionCall = functionCall
            self.functionResponse = functionResponse
        }
    }

    struct FunctionCall: Codable, Hashable, Sendable {
        var name: String
        var args: JSONValue?
    }

    struct FunctionResponse: Codable, Hashable, Sendable {
        var name: String
        var response: JSONValue
    }

    struct ToolSet: Codable, Hashable, Sendable {
        var functionDeclarations: [FunctionDeclaration]
    }

    struct FunctionDeclaration: Codable, Hashable, Sendable {
        var name: String
        var description: String
        var parametersJsonSchema: JSONValue?
    }

    struct GenerationConfig: Codable, Hashable, Sendable {
        var temperature: Double?
        var responseMimeType: String?
        var responseJsonSchema: JSONValue?
    }

    struct Response: Codable, Hashable, Sendable {
        var candidates: [Candidate]?
        var usageMetadata: UsageMetadata?
        var promptFeedback: PromptFeedback?

        /// The first candidate's parts.
        var parts: [Part] {
            candidates?.first?.content?.parts ?? []
        }

        var text: String {
            parts.compactMap(\.text).joined()
        }
    }

    struct Candidate: Codable, Hashable, Sendable {
        var content: Content?
        var finishReason: String?
    }

    struct UsageMetadata: Codable, Hashable, Sendable {
        var promptTokenCount: Int?
        var candidatesTokenCount: Int?
        var totalTokenCount: Int?
    }

    struct PromptFeedback: Codable, Hashable, Sendable {
        var blockReason: String?
    }

    /// The error body Gemini returns with a non-2xx status.
    struct ErrorEnvelope: Codable, Sendable {
        struct Detail: Codable, Sendable {
            var code: Int?
            var message: String?
            var status: String?
        }

        var error: Detail
    }
}

// MARK: - JSON

/// Any JSON value, for schemas and function arguments whose shape isn't known at compile time.
enum JSONValue: Codable, Hashable, Sendable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            self = .object(try container.decode([String: JSONValue].self))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case .bool(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .string(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        }
    }

    init(jsonData: Data) throws {
        self = try JSONDecoder().decode(JSONValue.self, from: jsonData)
    }

    /// Compact JSON text.
    var jsonString: String {
        let data = (try? JSONEncoder().encode(self)) ?? Data("null".utf8)
        return String(decoding: data, as: UTF8.self)
    }

    /// Applies `transform` to every string, keys excluded.
    func mapStrings(_ transform: (String) -> String) -> JSONValue {
        switch self {
        case .string(let value): .string(transform(value))
        case .array(let values): .array(values.map { $0.mapStrings(transform) })
        case .object(let values): .object(values.mapValues { $0.mapStrings(transform) })
        default: self
        }
    }
}

// MARK: - Redaction

extension GeminiAPI.Request {
    /// The same request with `redact` applied to every piece of text it carries: instructions,
    /// messages, function arguments and function results. Schemas and names are left alone.
    func redacted(with redact: (String) -> String) -> GeminiAPI.Request {
        var copy = self
        copy.systemInstruction = systemInstruction?.redacted(with: redact)
        copy.contents = contents.map { $0.redacted(with: redact) }
        return copy
    }
}

extension GeminiAPI.Content {
    func redacted(with redact: (String) -> String) -> GeminiAPI.Content {
        GeminiAPI.Content(role: role, parts: parts.map { part in
            var part = part
            part.text = part.text.map(redact)
            if var call = part.functionCall {
                call.args = call.args?.mapStrings(redact)
                part.functionCall = call
            }
            if let response = part.functionResponse {
                part.functionResponse = .init(name: response.name, response: response.response.mapStrings(redact))
            }
            return part
        })
    }
}
