//
//  ReminderButton.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 2/25/25.
//

import SwiftUI

struct ReminderButton: View {
    @Environment(RemindersManager.self) var reminderManager
    @State private var showDatePicker = false

    let item: ReminderType

    var reminderEnabled: Bool {
        withAnimation {
            reminderManager.itemHasReminder(item)
        }
    }

    var body: some View {
        Button {
            if reminderEnabled {
                reminderManager.removeReminder(for: item)
            } else {
                showDatePicker.toggle()
            }
        } label: {
            if #available(iOS 18.0, macOS 15.0, *) {
                Image(systemName: reminderEnabled ? "bell.fill" : "bell")
                    .symbolEffect(.wiggle, options: .speed(3), value: reminderEnabled) // no wiggles for the old phones :(
            } else {
                Image(systemName: reminderEnabled ? "bell.fill" : "bell")
            }
        }
        .sheet(isPresented: $showDatePicker) {
            ReminderDatePicker(item: item)
        }
    }
}

struct ReminderDatePicker: View {
    @Environment(RemindersManager.self) var reminderManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedDate: Date = .now
    @State private var alertMessage = ""
    @State private var showError = false

    let item: ReminderType

    // SF Symbol Icon Name, Color of SF Symbol, Date Interval Text, Date Interval
    let datePickerOptions: [(String, Color, String, Date)] =
    [
        ("bell", .yellow, "Tomorrow", .tomorrowAt8am),
        ("sofa", .purple, "This Weekend", .nextOrdinalAt8am(weekday: 7)),
        ("calendar.badge.clock", .green, "Next Week", .nextOrdinalAt8am(weekday: 2)) // Essentially, "next Monday"
    ]

    var body: some View {
        VStack {
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
                Button("Done", action: { scheduleReminder(date: selectedDate) })
            }
            .padding(.bottom, 15)
            Text("Set a Reminder")
                .font(.headline)
                .padding(.bottom, 15)
            ForEach(datePickerOptions, id: \.0) { imageName, color, text, date in
                QuickDateButton(
                    imageName: imageName,
                    imageColor: color,
                    text: text,
                    date: date,
                    action: { scheduleReminder(date: date) })
            }
            DatePicker("Set reminder for:", selection: $selectedDate, in: Date.now...)
            #if os(iOS)
                .datePickerStyle(.graphical)
            #endif
            Spacer()
        }
        .padding()
        .presentationDragIndicator(.visible)
        .alert(isPresented: $showError) {
            Alert(title: Text("Error setting reminder"), message: Text(alertMessage))
        }
    }

    func scheduleReminder(date: Date) {
        // Go ahead and strip out the seconds and milliseconds
        let date = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)) ?? Date.now
        Task {
            do {
                try await reminderManager.scheduleReminder(for: item, at: date)
                dismiss()
            } catch ReminderSchedulingError.invalidDate {
                alertMessage = "Please select a valid date."
                showError = true
            } catch ReminderSchedulingError.notificationsDisbled {
                alertMessage = "Please enable notifications in your device settings to receive reminders."
                showError = true
            }
        }
    }

    struct QuickDateButton: View {
        let imageName: String
        let imageColor: Color
        let text: String
        let date: Date
        let action: () -> Void

        var body: some View {
            Button {
                action()
            } label: {
                HStack {
                    Image(systemName: imageName)
                        .foregroundColor(imageColor)
                        .imageScale(.large)
                        .frame(maxWidth: 40)
                        .bold()
                    Text(text)
                        .bold()
                    Spacer()
                    Text(date.dayOfWeekString())
                        .textCase(.uppercase)
                        .font(.callout)
                        .opacity(0.75)
                }

                .padding([.leading], 5)
                .padding([.trailing], 10)
                .padding([.top, .bottom])
                .background(.quaternary)
                .cornerRadius(5)
            }
            .buttonStyle(.plain)
        }
    }
}

extension Date {
    func dayOfWeekString() -> String {
        let date = self
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    static var tomorrowAt8am: Date {
        let calendar = Calendar.current
        let now = Date.now

        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)  else {
            return Date.now
        }

        let tomorrowAt8AM = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: tomorrow)
        return tomorrowAt8AM ?? Date.now
    }

    static func nextOrdinalAt8am(weekday: Int) -> Date {
        if weekday < 1 || weekday > 7 {
            return .now
        }
        let calendar = Calendar.current
        let now = Date.now

        // Find the next ordinal day
        guard let nextDay = calendar.nextDate(after: now, matching: DateComponents(weekday: weekday), matchingPolicy: .nextTime) else {
            return Date.now
        }
        // Set the time to 8 AM
        return calendar.date(bySettingHour: 8, minute: 0, second: 0, of: nextDay) ?? Date.now
    }
}
