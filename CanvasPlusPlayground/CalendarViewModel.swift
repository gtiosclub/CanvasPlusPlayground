//
//  CalendarEventViewModel.swift
//  CanvasPlusPlayground
//
//  Created by Tejeshwar Natarajan on 10/4/24.
//

import Foundation

class CalendarEventViewModel: ObservableObject {
    @Published var parsedEvents: [CalendarEvent] = []
    @Published var eventsByDate: [Date?: [CalendarEvent]] = [:]
    
    func fetchEvents(from url: URL, completion: @escaping (Bool) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(false)
                return
            }
            print(String(data: data, encoding: .utf8) ?? "Unable to parse data")
//            var parsedEvents: [CalendarEvent] = []
            if let icsString = String(data: data, encoding: .utf8) {
                var events = self.parseICSData(icsString)
//                print(events)
                var eventUID: String = ""
                var eventsummary: String = ""
                var eventLocation : String = ""
                var eventStartDate : Date? = nil
                var eventEndDate : Date? = nil
                var eventLastUpdated : Date? = nil
                var eventDescription : String = ""
                for event in events {
                    
                    if let uid = event["UID"] {
                        eventUID = self.parseUID(from: uid)
                    }
                    
                    if let summary = event["SUMMARY"] {
                        eventsummary = self.parseSummary(from: summary)
                    }
                    if let location = event["LOCATION"] {
                        eventLocation = location
                    }
                    if let description = event["DESCRIPTION"] {
                        eventDescription = description
                    }
                    
                    if let startDate = event["DTSTART;VALUE=DATE;VALUE=DATE"] {
                        eventStartDate = self.parseDate(from: startDate)
                    }
                    
                    if let startDate = event["DTSTART"] {
                        eventStartDate = self.parseDate(from: startDate)
                    }
                    if let endDate = event["DTEND"] {
                        eventEndDate = self.parseDate(from: endDate)
                    }
                    
                    if let lastUpdated = event["DTSTAMP"] {
                        eventLastUpdated = self.parseDate(from: lastUpdated)
                    }
                    
                    let event = CalendarEvent(id: eventUID, lastUpdated: eventLastUpdated, eventName: eventsummary, startDate: eventStartDate, endDate: eventEndDate, location: eventLocation, description: eventDescription)
                    self.parsedEvents.append(event)
                }
            }
            
            for event in self.parsedEvents {
                print("Event: \(String(describing: event.eventName))")
                print("Start Date: \(String(describing: event.startDate))")
                print("End Date: \(String(describing: event.endDate))")
                print("Last Updated: \(String(describing: event.lastUpdated))")
                print("Event ID: \(String(describing: event.id))\n")
                var dates : [Date?] = []
                if (event.startDate != nil && event.endDate != nil) {
                    dates = event.startDate!.allDates(till: event.endDate!)
                } else if (event.startDate != nil) {
                    dates = event.startDate!.allDates(till: event.startDate!)
                } else if (event.endDate != nil) {
                    dates = event.endDate!.allDates(till: event.endDate!)
                } else {
                    dates = [nil]
                }

                for date in dates {
                    self.eventsByDate[date, default: []].append(event)
                }

            }
            print(self.eventsByDate)
            
            completion(true)
        }.resume()

    }
    
    func parseUID(from uid: String) -> String {
        return uid.replacingOccurrences(of: "event-assignment-", with: "")
    }
    
    func parseSummary(from summary: String) -> String {
        let pattern = "\\[.*"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(summary.startIndex..., in: summary)
        var modifiedSummary = regex.stringByReplacingMatches(in: summary, options: [], range: range, withTemplate: "")
        modifiedSummary = modifiedSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        return modifiedSummary
    }
        
    func parseDate(from dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmssZ"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC") // UTC time
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter.date(from: dateString)
    }
    
    func parseICSData(_ icsString: String) -> [[String: String]] {
        var inEvent : Bool = false
        var calendarEvents: [[String: String]] = []
        var currentEvent: [String: String] = [:]
        
        let lines = icsString.replacingOccurrences(of: "\r", with: "").components(separatedBy: "\n")
        for line in lines {
            if line.hasPrefix("BEGIN:VEVENT") {
                currentEvent = [:]
                inEvent = true
            } else if line.hasPrefix("END:VEVENT") {
                calendarEvents.append(currentEvent)
                inEvent = false
            } else if inEvent {
                let components = line.split(separator: ":", maxSplits: 1).map { String($0) }
                if components.count > 1 {
                    let key = components[0].trimmingCharacters(in: .whitespaces)
                    let value = components[1].trimmingCharacters(in: .whitespaces)
                    currentEvent[key] = value
                }
            }
        }
        
        return calendarEvents
    }
}
