//
//  Event.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 12/9/24.
//

import Foundation

enum ICSParser {
    private static var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")

        return dateFormatter
    }

    static func parseEvents(
        from icsURL: URL?,
        for course: Course
    ) async -> [CanvasCalendarEventGroup] {
        guard let icsURL else { return [] }

        guard let content = try? await fetchICSContentsFromURL(icsURL) else {
            LoggerService.main.error("Error fetching ICS contents")
            return []
        }

        var events = [CanvasCalendarEvent]()

        // Normalize line endings and split properly
        let normalizedContent = content.replacingOccurrences(of: "\r\n", with: "\n")
                                       .replacingOccurrences(of: "\r", with: "\n")
        let lines = normalizedContent.components(separatedBy: "\n")

        var currentEvent: [String: String] = [:]

        // Unfold lines according to RFC 5545
        var unfoldedLines = [String]()
        var currentLine = ""

        for (index, line) in lines.enumerated() {
            if line.hasPrefix(" ") || line.hasPrefix("\t") {
                // This is a continuation line - remove the leading whitespace and append
                let continuation = String(line.dropFirst())
                currentLine += continuation
            } else {
                // This is a new line
                if !currentLine.isEmpty {
                    unfoldedLines.append(currentLine)
                }
                currentLine = line
            }
        }

        if !currentLine.isEmpty {
            unfoldedLines.append(currentLine)
        }

        for line in unfoldedLines {
            if line.hasPrefix("BEGIN:VEVENT") {
                currentEvent = [:]
            } else if line.hasPrefix("END:VEVENT") {

                if let id = currentEvent["UID"],
                   let summary = currentEvent["SUMMARY"],
                   let startDateString = currentEvent["DTSTART"],
                   let endDateString = currentEvent["DTEND"],
                   let startDate = dateFormatter.date(from: startDateString),
                   let endDate = dateFormatter.date(from: endDateString) {
                    let location = currentEvent["LOCATION"] ?? "-"

                    let event = CanvasCalendarEvent(
                        id: id,
                        course: course,
                        summary: unescapeICSValue(summary),
                        startDate: startDate,
                        endDate: endDate,
                        location: unescapeICSValue(location)
                    )
                    events.append(event)
                }
            } else {
                let components = line.components(separatedBy: ":")
                if components.count > 1 {
                    // Extract the property name (before any semicolon for parameters)
                    let keyWithParams = components[0]
                    let key = keyWithParams.components(separatedBy: ";")[0]
                    let value = components[1...].joined(separator: ":")
                    currentEvent[key] = value
                }
            }
        }

        return groupEvents(events)
    }

    private static func unescapeICSValue(_ value: String) -> String {
        return value
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\,", with: ",")
            .replacingOccurrences(of: "\\;", with: ";")
            .replacingOccurrences(of: "\\\\", with: "\\")
    }

    private static func groupEvents(_ events: [CanvasCalendarEvent]) -> [CanvasCalendarEventGroup] {
        let groupedEvents = Dictionary(grouping: events) { event in
            Calendar.current.dateComponents(
                [.day, .year, .month],
                from: event.startDate
            )
        }

        return groupedEvents
            .compactMap { dateComponents, events in
                guard let date = Calendar.current.date(from: dateComponents) else {
                    return nil
                }

                return CanvasCalendarEventGroup(
                    date: date,
                    events: events
                )
            }
            .sorted { $0.date > $1.date }
    }

    private static func fetchICSContentsFromURL(_ url: URL) async throws -> String {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw HTTPStatusCode.unknown
            }

            if let str = String(data: data, encoding: .utf8) {
                return str
            } else {
                throw HTTPStatusCode.unknown
            }
        } catch {
            throw HTTPStatusCode.unknown
        }
    }
}

struct CanvasCalendarEventGroup: Identifiable {
    let id: String = UUID().uuidString
    let date: Date
    let events: [CanvasCalendarEvent]

    var displayDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeZone = .current

        return dateFormatter.string(from: date)
    }
}

struct CanvasCalendarEvent: Identifiable, Hashable {
    let id: String
    let course: Course
    let summary: String
    let startDate: Date
    let endDate: Date
    let location: String
}
