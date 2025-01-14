//
//  Event.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 12/9/24.
//

import Foundation

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

struct CanvasCalendarEvent: Identifiable {
    let id: String
    let summary: String
    let startDate: Date
    let endDate: Date
    let location: String
}

struct ICSParser {
    private static var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")

        return dateFormatter
    }

    static func parseEvents(
        from icsURL: URL?
    ) async -> [CanvasCalendarEventGroup] {
        guard let icsURL else { return [] }

        guard let content = try? await fetchICSContentsFromURL(icsURL) else {
            print("Error fetching ICS contents")
            return []
        }

        var events = [CanvasCalendarEvent]()
        let lines = content.components(separatedBy: .newlines)
        var currentEvent: [String: String] = [:]

        for line in lines {
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
                        summary: summary,
                        startDate: startDate,
                        endDate: endDate,
                        location: location
                    )

                    events.append(event)
                }
            } else {
                let components = line.components(separatedBy: ":")
                if components.count > 1 {
                    let key = components[0]
                    let value = components[1...].joined(separator: ":")
                    currentEvent[key] = value
                }
            }
        }

        return groupEvents(events)
    }

    private static func groupEvents(_ events: [CanvasCalendarEvent]) -> [CanvasCalendarEventGroup] {
        let groupedEvents = Dictionary(grouping: events) { event in
            let date = Calendar.current.dateComponents(
                [.day, .year, .month],
                from: event.startDate
            )

            return date
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
                throw NetworkError.fetchFailed(msg: response.description)
            }

            return String(decoding: data, as: UTF8.self)
        } catch {
            throw NetworkError.fetchFailed(msg: error.localizedDescription)
        }
    }
}
