//
//  RemindersManager.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 2/24/25.
//

import Foundation
import UserNotifications

let logger = LoggerService.main

@Observable
class RemindersManager {
    var reminders: [UNNotificationRequest] = []
    var center = UNUserNotificationCenter.current()

    
    init() {
        loadItems()
    }
    
    func scheduleReminder(for item: ReminderType, at date: Date) async {
        do {
            try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            logger.error("Error requesting authorization: \(error)")
        }

        let content = UNMutableNotificationContent()
        
        switch item {
            case .assignment(let assignment):
            content.title = "REMINDER: \(assignment.name)"
            // if the assignment has a due date, we want to let the user know how much time left
            if let dueDate = assignment.dueDate {
                let deltaText = timeDeltaString(from: dueDate, to: date)
                content.body = "Assignment is due in \(deltaText)"
            } else {
                content.body = ""
            }
        }
        
        
        content.sound = .default
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: item.reminderIdentifier, content: content, trigger: trigger)

        do {
            try await center.add(request)
            self.reminders.append(request)
        } catch {
            logger.error("Error adding notification: \(error)")
        }
    }

    func removeReminder(for item: ReminderType) {
        center.removePendingNotificationRequests(withIdentifiers: [item.reminderIdentifier])
        reminders.removeAll { request in
            request.identifier == item.reminderIdentifier
        }
    }

    func loadItems() {
        Task {
            self.reminders = await center.pendingNotificationRequests()
        }
    }
    
    func itemHasReminder(_ item: ReminderType) -> Bool {
        reminders.contains { request in
            request.identifier == item.reminderIdentifier
        }
    }
}

enum ReminderType: Equatable {
    case assignment(Assignment)

    var reminderIdentifier: String {
        switch self {
        case .assignment(let assignment):
            return "assignment-\(assignment.id)"
        }
    }
}

func timeDeltaString(from startDate: Date, to endDate: Date) -> String {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .full // Use .short or .abbreviated for different styles
    formatter.allowedUnits = [.day, .hour]
    return formatter.string(from: startDate, to: endDate) ?? "N/A"
}
