//
//  RemindersManager.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 2/24/25.
//

import Foundation
import UserNotifications

@Observable
class RemindersManager: NSObject, UNUserNotificationCenterDelegate {
    var reminders: [UNNotificationRequest] = []
    var center: UNUserNotificationCenter

    override init() {
        center = UNUserNotificationCenter.current()
        super.init()
        center.delegate = self
        loadItems()
    }

    func scheduleReminder(for item: ReminderType, at date: Date) async throws {
        let title: String
        let body: String

        switch item {
        case .assignment(let assignment):
            title = "REMINDER: \(assignment.name)"
            // we want to let the user know how much time left if the assignment has a due date
            if let dueDate = assignment.dueDate {
                let deltaText = Date.timeDeltaString(from: dueDate, to: date)
                body = "Assignment is due in \(deltaText)"
            } else {
                body = ""
            }
        }

        try await scheduleReminder(identifier: item.reminderIdentifier, title: title, body: body, at: date)
    }

    /// Schedules a local notification. Used directly for reminders that aren't tied to a
    /// `ReminderType`, such as ones the agent proposes and the student approves.
    func scheduleReminder(identifier: String, title: String, body: String, at date: Date) async throws {
        if date < Date.now { // scheduling a reminder for the past
            throw ReminderSchedulingError.invalidDate
        }
        do {
            try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            LoggerService.main.error("Error requesting authorization: \(error)")
            throw ReminderSchedulingError.notificationsDisbled
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await center.add(request)
            self.reminders.append(request)

            LoggerService.main.debug("Scheduling a reminder \(identifier) for \(date.description)")
        } catch {
            LoggerService.main.error("Error adding notification: \(error)")
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

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        reminders.removeAll { request in
            notification.request.identifier == request.identifier
        }
        completionHandler([.badge, .banner])
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

enum ReminderSchedulingError: Error {
    case notificationsDisbled
    case invalidDate
}
