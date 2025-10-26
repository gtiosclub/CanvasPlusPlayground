//
//  ICalView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 10/26/25.
//

import SwiftUI

struct ICalView: View {

    let weekdays: [Locale.Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday]

    let events: [Locale.Weekday: [Event]]

    var body: some View {
        HStack(spacing: 16) {
            ForEach(Array(weekdays.enumerated()), id: \.element) { index, day in
                VStack {
                    Text(day.rawValue)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                    // EventsListView // commented out until Events type is defined
                    Spacer()
                }
                if index < weekdays.count - 1 {
                    Divider()
                }
            }
        }
        .padding()
    }

    private struct EventsListView: View {
         let events: [Event]

        var body: some View {

        }
    }
}
struct Event {

}

#Preview {
    ICalView(events: [:])
}
