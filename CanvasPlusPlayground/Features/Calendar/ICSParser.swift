//
//  Event.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 12/9/24.
//


import Foundation

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

    private static var groupingDateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        return dateFormatter
    }

    static func parseEvents(from icsURL: URL?) async -> [String: [CanvasCalendarEvent]] {
        guard let icsURL else { return [:] }

        let content = await fetchICSContentsFromURL(icsURL)

        var events = [String: [CanvasCalendarEvent]]()
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

                    let groupingDate = groupingDateFormatter.string(from: startDate)
                    events[groupingDate, default: []].append(event)
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

        return events
    }

    static private func fetchICSContentsFromURL(_ url: URL) async -> String {
        guard let data = try? await URLSession.shared.data(from: url).0 else {
            return ""
        }

        return String(decoding: data, as: UTF8.self)
    }
}

