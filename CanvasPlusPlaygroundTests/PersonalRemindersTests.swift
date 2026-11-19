//
//  PersonalRemindersTests.swift
//  CanvasPlusPlaygroundTests
//

import Foundation
import Testing
import UserNotifications
@testable import CanvasPlusPlayground

/// Records what would have been scheduled.
private final class FakeScheduler: NotificationScheduler, @unchecked Sendable {
    var granted = true
    var pending: [UNNotificationRequest] = []

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool { granted }

    func add(_ request: UNNotificationRequest) async throws {
        pending.removeAll { $0.identifier == request.identifier }
        pending.append(request)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        pending.removeAll { identifiers.contains($0.identifier) }
    }

    func pendingNotificationRequests() async -> [UNNotificationRequest] { pending }

    var identifiers: [String] { pending.map(\.identifier) }
}

private func tempStore() -> PersonalReminderStore {
    PersonalReminderStore(url: URL.temporaryDirectory.appending(path: "reminders-\(UUID()).json"))
}

private let now = Date(timeIntervalSince1970: 1_790_000_000)
private let assignment = PersonalReminder.Target.assignment(id: "42", courseID: "7")

@MainActor
private func makeManager(_ scheduler: FakeScheduler = FakeScheduler(), store: PersonalReminderStore = tempStore()) async -> RemindersManager {
    let manager = RemindersManager(scheduler: scheduler, store: store, now: { now })
    await Task.yield() // let loadItems() run
    return manager
}

struct PersonalReminderModelTests {
    @Test func relativeRemindersCountBackFromTheAnchor() {
        let due = now.addingTimeInterval(5 * 86_400)
        let reminder = PersonalReminder(target: assignment, title: "PS5", timing: .relative(offset: 86_400, anchor: due))
        #expect(reminder.fireDate == due.addingTimeInterval(-86_400))
        #expect(reminder.timing.relativeDescription == "1 day before due")
    }

    @Test func reanchoringMovesOnlyRelativeReminders() {
        let due = now.addingTimeInterval(86_400 * 3)
        let moved = due.addingTimeInterval(86_400)
        let relative = PersonalReminder(target: assignment, title: "PS5", timing: .relative(offset: 3_600, anchor: due))
        let absolute = PersonalReminder(target: assignment, title: "PS5", timing: .absolute(due))

        #expect(relative.reanchored(to: moved).fireDate == moved.addingTimeInterval(-3_600))
        #expect(absolute.reanchored(to: moved) == absolute)
    }

    @Test func identifiersAreUniquePerReminder() {
        let first = PersonalReminder(target: assignment, title: "PS5", timing: .absolute(now))
        let second = PersonalReminder(target: assignment, title: "PS5", timing: .absolute(now))
        #expect(first.notificationIdentifier.hasPrefix("assignment-42-"))
        #expect(first.notificationIdentifier != second.notificationIdentifier)
        #expect(PersonalReminder(target: .personal, title: "Call home", timing: .absolute(now)).notificationIdentifier.hasPrefix("personal-personal-"))
    }

    @Test func deepLinksMatchTheSpotlightFormat() {
        #expect(assignment.deepLinkIdentifier == "assignment:42")
        #expect(PersonalReminder.Target.quiz(id: "9", courseID: nil).deepLinkIdentifier == "quiz:9")
        #expect(PersonalReminder.Target.personal.deepLinkIdentifier == nil)
    }

    @Test func storeRoundTrips() {
        let store = tempStore()
        let reminders = [
            PersonalReminder(target: assignment, title: "PS5", note: "Start early", timing: .relative(offset: 7_200, anchor: now)),
            PersonalReminder(target: .personal, title: "Office hours", timing: .absolute(now)),
        ]
        store.save(reminders)
        #expect(store.load() == reminders)
    }
}

@MainActor
@Suite(.serialized)
struct RemindersManagerTests {
    @Test func anItemCanHaveSeveralReminders() async throws {
        let scheduler = FakeScheduler()
        let manager = await makeManager(scheduler)
        let due = now.addingTimeInterval(4 * 86_400)

        try await manager.add(PersonalReminder(target: assignment, title: "PS5", timing: .relative(offset: 86_400, anchor: due)), dueDate: due)
        try await manager.add(PersonalReminder(target: assignment, title: "PS5", timing: .relative(offset: 7_200, anchor: due)), dueDate: due)

        #expect(manager.reminders(for: assignment).count == 2)
        #expect(scheduler.pending.count == 2)
        #expect(Set(scheduler.identifiers).count == 2)
    }

    @Test func notificationsCarryTheDeepLinkAndADueText() async throws {
        let scheduler = FakeScheduler()
        let manager = await makeManager(scheduler)
        let due = now.addingTimeInterval(2 * 86_400)

        try await manager.add(PersonalReminder(target: assignment, title: "PS5", timing: .relative(offset: 86_400, anchor: due)), dueDate: due)

        let request = try #require(scheduler.pending.first)
        #expect(request.content.title == "Reminder: PS5")
        #expect(request.content.body.hasPrefix("Due in"))
        #expect(request.content.userInfo[RemindersManager.userInfoDeepLink] as? String == "assignment:42")
    }

    @Test func refusesPastTimesAndDeniedNotifications() async {
        let scheduler = FakeScheduler()
        let manager = await makeManager(scheduler)

        await #expect(throws: ReminderSchedulingError.invalidDate) {
            try await manager.add(PersonalReminder(target: .personal, title: "x", timing: .absolute(now.addingTimeInterval(-60))))
        }

        scheduler.granted = false
        await #expect(throws: ReminderSchedulingError.notificationsDisbled) {
            try await manager.add(PersonalReminder(target: .personal, title: "x", timing: .absolute(now.addingTimeInterval(60))))
        }
        #expect(manager.personalReminders.isEmpty)
    }

    @Test func deletingRemovesTheNotificationAndTheRecord() async throws {
        let scheduler = FakeScheduler()
        let store = tempStore()
        let manager = await makeManager(scheduler, store: store)
        let reminder = PersonalReminder(target: .personal, title: "Office hours", timing: .absolute(now.addingTimeInterval(600)))

        try await manager.add(reminder)
        manager.delete(reminder)

        #expect(scheduler.pending.isEmpty)
        #expect(manager.personalReminders.isEmpty)
        #expect(store.load().isEmpty)
    }

    @Test func relativeRemindersFollowAMovedDueDate() async throws {
        let scheduler = FakeScheduler()
        let manager = await makeManager(scheduler)
        let due = now.addingTimeInterval(3 * 86_400)
        let later = due.addingTimeInterval(2 * 86_400)

        try await manager.add(PersonalReminder(target: assignment, title: "PS5", timing: .relative(offset: 86_400, anchor: due)), dueDate: due)
        try await manager.add(PersonalReminder(target: assignment, title: "PS5", timing: .absolute(now.addingTimeInterval(3_600))))

        let moved = await manager.refreshRelativeReminders { $0 == assignment ? later : nil }

        #expect(moved == 1)
        let relative = try #require(manager.personalReminders.first { $0.timing.isRelative })
        #expect(relative.fireDate == later.addingTimeInterval(-86_400))
        #expect(scheduler.pending.count == 2)
        let trigger = try #require(scheduler.pending.first { $0.identifier == relative.notificationIdentifier }?.trigger as? UNCalendarNotificationTrigger)
        // Triggers fire on the minute.
        let triggerDate = try #require(Calendar.current.date(from: trigger.dateComponents))
        #expect(abs(triggerDate.timeIntervalSince(relative.fireDate)) < 60)
    }

    @Test func aReminderMovedIntoThePastIsUnscheduledButKept() async throws {
        let scheduler = FakeScheduler()
        let manager = await makeManager(scheduler)
        let due = now.addingTimeInterval(3 * 86_400)

        try await manager.add(PersonalReminder(target: assignment, title: "PS5", timing: .relative(offset: 86_400, anchor: due)), dueDate: due)
        await manager.refreshRelativeReminders { _ in now.addingTimeInterval(3_600) }

        #expect(scheduler.pending.isEmpty)
        #expect(manager.past.count == 1)
        #expect(manager.upcoming.isEmpty)
    }

    @Test func bringsInLegacySingleReminders() async throws {
        let scheduler = FakeScheduler()
        let content = UNMutableNotificationContent()
        content.title = "REMINDER: Problem Set 4"
        let fire = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: Date.now.addingTimeInterval(86_400 * 2))
        scheduler.pending = [
            UNNotificationRequest(identifier: "assignment-1234", content: content, trigger: UNCalendarNotificationTrigger(dateMatching: fire, repeats: false)),
            UNNotificationRequest(identifier: "something-else", content: UNMutableNotificationContent(), trigger: nil),
        ]

        let manager = RemindersManager(scheduler: scheduler, store: tempStore())
        for _ in 0..<20 where manager.personalReminders.isEmpty { await Task.yield() }

        let migrated = try #require(manager.personalReminders.first)
        #expect(migrated.title == "Problem Set 4")
        #expect(migrated.target == .assignment(id: "1234", courseID: nil))
        #expect(!scheduler.identifiers.contains("assignment-1234"))
        #expect(scheduler.identifiers.contains(migrated.notificationIdentifier))
        #expect(scheduler.identifiers.contains("something-else"))
    }

    @Test func dropsRemindersLongPast() async {
        let store = tempStore()
        store.save([
            PersonalReminder(target: .personal, title: "old", timing: .absolute(now.addingTimeInterval(-40 * 86_400))),
            PersonalReminder(target: .personal, title: "recent", timing: .absolute(now.addingTimeInterval(-86_400))),
        ])

        let manager = RemindersManager(scheduler: FakeScheduler(), store: store, now: { now })
        for _ in 0..<20 where manager.personalReminders.count == 2 { await Task.yield() }

        #expect(manager.personalReminders.map(\.title) == ["recent"])
        #expect(store.load().map(\.title) == ["recent"])
    }
}
