//
//  CalendarView.swift
//  CanvasPlusPlayground
//
//  Created by Jiyoon Lee on 9/14/24.
//

import SwiftUI

struct CalendarView: View {
    @Environment(CalendarManager.self) var calendarManager
    @State private var showSheet: Bool = false

    var body: some View {
        @Bindable var calendarManager = calendarManager
        NavigationStack {
            List(calendarManager.calendar, id: \.id) { event in
                VStack(alignment: .leading) {
                    Text(event.title)
                }
            }
            .navigationTitle("Calendar Events")
            .refreshable {
                await calendarManager.fetchCalendar()
            }
            .fullScreenCover(isPresented: $showSheet) {
                NavigationStack {
                    SetupView()
                }
                .onDisappear {
                    Task {
                        await calendarManager.fetchCalendar()
                    }
                }
            }
        }
        .task {
            if StorageKeys.needsAuthorization {
                showSheet = true
            } else {
                await calendarManager.fetchCalendar()
            }
        }
    }
}

#Preview {
    CalendarView()
        .environment(CalendarManager())
}
