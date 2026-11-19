//
//  RemindersManager.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 2/24/25.
//

import Foundation
import SwiftData
import UserNotifications

/// The student's own reminders. Each one is a local notification plus a `PersonalReminder`
/// record, so an item can have several, relative reminders can follow a moved due date, and
/// the "My Reminders" list can show and edit them. Nothing here ever writes to Canvas.
@MainActor
@Observable
final class RemindersManager: NSObject, UNUserNotificationCenterDelegate {
    static let userInfoReminderID = "reminderID"
    static let userInfoDeepLink = "deepLink"
    /// Past reminders stay in the list this long, then they're dropped.
    static let pastRetention: TimeInterval = 30 * 86_400

    /// Every saved reminder, soonest first.
    private(set) var personalReminders: [PersonalReminder] = []

    @ObservationIgnored private let scheduler: any NotificationScheduler
    @ObservationIgnored private let store: PersonalReminderStore
    @ObservationIgnored private let now: () -> Date

    init(
        scheduler: any NotificationScheduler = UNUserNotificationCenter.current(),
        store: PersonalReminderStore = .default,
        now: @escaping () -> Date = { .now }
    ) {
        self.scheduler = scheduler
        self.store = store
        self.now = now
        super.init()

        if let center = scheduler as? UNUserNotificationCenter {
            center.delegate = self
        }
        personalReminders = Self.sorted(store.load())
        loadItems()
    }

    // MARK: Reading

    var upcoming: [PersonalReminder] {
        personalReminders.filter { $0.fireDate > now() }
    }

    var past: [PersonalReminder] {
        personalReminders.filter { $0.fireDate <= now() }.reversed()
    }

    func reminders(for target: PersonalReminder.Target) -> [PersonalReminder] {
        personalReminders.filter { $0.target == target }
    }

    func itemHasReminder(_ item: ReminderType) -> Bool {
        reminders(for: item.target).contains { $0.fireDate > now() }
    }

    // MARK: Writing

    /// Saves `reminder` and schedules its notification.
    /// - Parameter dueDate: the item's due date, for the notification text.
    func add(_ reminder: PersonalReminder, dueDate: Date? = nil) async throws {
        try await schedule(reminder, dueDate: dueDate)
        personalReminders.removeAll { $0.id == reminder.id }
        personalReminders = Self.sorted(personalReminders + [reminder])
        store.save(personalReminders)
    }

    /// Replaces a saved reminder (same `id`) and reschedules it.
    func update(_ reminder: PersonalReminder, dueDate: Date? = nil) async throws {
        if let existing = personalReminders.first(where: { $0.id == reminder.id }) {
            scheduler.removePendingNotificationRequests(withIdentifiers: [existing.notificationIdentifier])
        }
        try await add(reminder, dueDate: dueDate)
    }

    func delete(_ reminder: PersonalReminder) {
        scheduler.removePendingNotificationRequests(withIdentifiers: [reminder.notificationIdentifier])
        personalReminders.removeAll { $0.id == reminder.id }
        store.save(personalReminders)
    }

    /// The old single-reminder API, kept for callers that set one absolute reminder on an item.
    func scheduleReminder(for item: ReminderType, at date: Date) async throws {
        try await add(
            PersonalReminder(target: item.target, title: item.title, timing: .absolute(date)),
            dueDate: item.dueDate
        )
    }

    /// Removes every reminder for `item`.
    func removeReminder(for item: ReminderType) {
        for reminder in reminders(for: item.target) {
            delete(reminder)
        }
    }

    // MARK: Relative reminders

    /// Moves relative reminders whose item's due date changed. A reminder whose new time has
    /// already passed is unscheduled but stays in the list.
    ///
    /// - Parameter dueDate: The item's current due date, or nil when it's unknown (left alone).
    /// - Returns: How many reminders moved.
    @discardableResult
    func refreshRelativeReminders(dueDate: (PersonalReminder.Target) -> Date?) async -> Int {
        var moved = 0

        for reminder in personalReminders where reminder.timing.isRelative {
            guard let newDue = dueDate(reminder.target) else { continue }
            let updated = reminder.reanchored(to: newDue)
            guard updated != reminder else { continue }

            moved += 1
            scheduler.removePendingNotificationRequests(withIdentifiers: [reminder.notificationIdentifier])
            if updated.fireDate > now() {
                try? await schedule(updated, dueDate: newDue)
            }
            personalReminders = personalReminders.map { $0.id == updated.id ? updated : $0 }
        }

        if moved > 0 {
            personalReminders = Self.sorted(personalReminders)
            store.save(personalReminders)
        }
        return moved
    }

    /// Due dates of cached assignments and quizzes, for `refreshRelativeReminders`.
    static func cachedDueDate(in context: ModelContext) -> (PersonalReminder.Target) -> Date? {
        { target in
            switch target {
            case .assignment(let id, _):
                let assignment = try? context.fetch(FetchDescriptor<Assignment>(predicate: #Predicate { $0.id == id })).first
                return assignment?.dueAt == nil ? nil : assignment?.dueDate
            case .quiz(let id, _):
                return (try? context.fetch(FetchDescriptor<Quiz>(predicate: #Predicate { $0.id == id })).first)?.dueAt
            default:
                return nil
            }
        }
    }

    // MARK: Loading

    /// Brings in reminders set before reminders had their own records (one notification per
    /// assignment, identifier `assignment-<id>`), and drops reminders long past.
    func loadItems() {
        Task {
            let pending = await scheduler.pendingNotificationRequests()
            var changed = false

            for request in pending {
                guard let legacy = Self.legacyReminder(from: request) else { continue }
                scheduler.removePendingNotificationRequests(withIdentifiers: [request.identifier])
                try? await schedule(legacy, dueDate: nil)
                personalReminders.append(legacy)
                changed = true
            }

            let cutoff = now().addingTimeInterval(-Self.pastRetention)
            let kept = personalReminders.filter { $0.fireDate >= cutoff }
            if kept.count != personalReminders.count || changed {
                personalReminders = Self.sorted(kept)
                store.save(personalReminders)
            }
        }
    }

    static func legacyReminder(from request: UNNotificationRequest) -> PersonalReminder? {
        let parts = request.identifier.split(separator: "-")
        guard parts.count == 2, parts[0] == "assignment", parts[1].allSatisfy(\.isNumber),
              let trigger = request.trigger as? UNCalendarNotificationTrigger,
              let fireDate = trigger.nextTriggerDate() else {
            return nil
        }

        let title = request.content.title.replacingOccurrences(of: "REMINDER: ", with: "")
        return PersonalReminder(
            target: .assignment(id: String(parts[1]), courseID: nil),
            title: title.isEmpty ? "Assignment" : title,
            timing: .absolute(fireDate)
        )
    }

    // MARK: Notifications

    private func schedule(_ reminder: PersonalReminder, dueDate: Date?) async throws {
        let fireDate = reminder.fireDate
        guard fireDate > now() else {
            throw ReminderSchedulingError.invalidDate
        }

        do {
            guard try await scheduler.requestAuthorization(options: [.alert, .sound, .badge]) else {
                throw ReminderSchedulingError.notificationsDisbled
            }
        } catch {
            LoggerService.main.error("Error requesting authorization: \(error)")
            throw ReminderSchedulingError.notificationsDisbled
        }

        try await scheduler.add(Self.request(for: reminder, dueDate: dueDate))
        LoggerService.main.debug("Scheduled reminder \(reminder.notificationIdentifier) for \(fireDate.description)")
    }

    static func request(for reminder: PersonalReminder, dueDate: Date?) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "Reminder: \(reminder.title)"
        content.body = reminder.notificationBody(dueDate: dueDate ?? Self.anchor(of: reminder))
        content.sound = .default

        var userInfo: [String: String] = [userInfoReminderID: reminder.id.uuidString]
        userInfo[userInfoDeepLink] = reminder.target.deepLinkIdentifier
        content.userInfo = userInfo

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(identifier: reminder.notificationIdentifier, content: content, trigger: trigger)
    }

    private static func anchor(of reminder: PersonalReminder) -> Date? {
        if case .relative(_, let anchor) = reminder.timing { anchor } else { nil }
    }

    private static func sorted(_ reminders: [PersonalReminder]) -> [PersonalReminder] {
        reminders.sorted { $0.fireDate != $1.fireDate ? $0.fireDate < $1.fireDate : $0.createdAt < $1.createdAt }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.badge, .banner, .sound])
    }

    /// Tapping a reminder opens its item through the same deep-link path Spotlight uses.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let deepLink = response.notification.request.content.userInfo[Self.userInfoDeepLink] as? String
        if let deepLink {
            Task { @MainActor in
                NotificationCenter.default.post(
                    name: .openSpotlightDeepLink,
                    object: nil,
                    userInfo: [SpotlightDeepLinkUserInfoKey.identifier: deepLink]
                )
            }
        }
        completionHandler()
    }
}

/// The parts of `UNUserNotificationCenter` reminders use, so tests can stand in a fake.
protocol NotificationScheduler: AnyObject {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
    func pendingNotificationRequests() async -> [UNNotificationRequest]
}

extension UNUserNotificationCenter: NotificationScheduler {}

/// Something a reminder can be attached to from its detail screen.
enum ReminderType: Equatable {
    case assignment(Assignment)
    case quiz(Quiz)
    case calendarEvent(CanvasCalendarEvent, courseID: String?)
    case toDo(ToDoItem)
    case announcement(DiscussionTopic)

    var target: PersonalReminder.Target {
        switch self {
        case .assignment(let assignment):
            .assignment(id: assignment.id, courseID: assignment.courseId?.asString)
        case .quiz(let quiz):
            .quiz(id: quiz.id, courseID: quiz.courseID)
        case let .calendarEvent(event, courseID):
            .calendarEvent(uid: event.id, courseID: courseID)
        case .toDo(let item):
            .toDo(id: item.id)
        case .announcement(let topic):
            .announcement(id: topic.id, courseID: topic.courseId)
        }
    }

    var title: String {
        switch self {
        case .assignment(let assignment): assignment.name
        case .quiz(let quiz): quiz.title
        case .calendarEvent(let event, _): event.summary
        case .toDo(let item): item.title
        case .announcement(let topic): topic.title ?? "Announcement"
        }
    }

    /// The date relative reminders count back from: due date, or start time for events.
    var dueDate: Date? {
        switch self {
        case .assignment(let assignment): assignment.dueAt == nil ? nil : assignment.dueDate
        case .quiz(let quiz): quiz.dueAt
        case .calendarEvent(let event, _): event.startDate
        case .toDo(let item): item.dueDate
        case .announcement: nil
        }
    }
}

enum ReminderSchedulingError: Error {
    case notificationsDisbled
    case invalidDate
}
