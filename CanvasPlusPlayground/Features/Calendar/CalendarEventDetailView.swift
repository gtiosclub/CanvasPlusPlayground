//
//  CalendarEventDetailView.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 10/15/25.
//

import SwiftUI

struct CalendarEventDetailView: View {
    let event: CanvasCalendarEvent
    let course: Course?

    private var timeRangeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let startTime = formatter.string(from: event.startDate)
        let endTime = formatter.string(from: event.endDate)
        return "\(startTime) - \(endTime)"
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: event.startDate)
    }

    private var duration: String {
        let interval = event.endDate.timeIntervalSince(event.startDate)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var body: some View {
        Form {
            if let course {
                Section {
                    HStack {
                        if let color = course.rgbColors?.color {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(color)
                                .frame(width: 4)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(course.displayName)
                                .font(.headline)

                            if let courseCode = course.courseCode {
                                Text(courseCode)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Event Details") {
                LabeledContent("Title", value: event.summary)

                LabeledContent("Date", value: dateString)

                LabeledContent("Time", value: timeRangeString)

                LabeledContent("Duration", value: duration)

                if event.location != "-" {
                    LabeledContent("Location", value: event.location)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Event")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
