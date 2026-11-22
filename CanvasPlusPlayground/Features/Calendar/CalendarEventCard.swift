//
//  CalendarEventCard.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 10/26/25.
//

import SwiftUI

struct CalendarEventCard: View {
    let event: CanvasCalendarEvent
    let destination: NavigationModel.Destination

    var body: some View {
        NavigationLink(value: destination) {
            VStack(alignment: .leading, spacing: 2) {
                Text(event.summary)
                    .bold()
                    .lineLimit(1)

                Group {
                    if event.startDate == event.endDate {
                        Text(event.startDate, style: .time)
                    } else {
                        Text("\(event.startDate, style: .time) – \(event.endDate, style: .time)")
                    }
                    if !event.location.isEmpty {
                        Text(event.location)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
            .font(.subheadline)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background {
                // Opaque base so timeline hour lines don't show through the tint.
                RoundedRectangle(cornerRadius: 6).fill(.background)
                RoundedRectangle(cornerRadius: 6).fill((event.course.rgbColors?.color ?? .accentColor).opacity(0.25))
            }
            .overlay(alignment: .leading) {
                UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 6)
                    .fill(event.course.rgbColors?.color ?? .accentColor)
                    .frame(width: 3)
            }
            .clipped()
        }
        .buttonStyle(.plain)
    }
}
