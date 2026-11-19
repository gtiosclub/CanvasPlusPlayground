//
//  PersonalReminder.swift
//  CanvasPlusPlayground
//

import Foundation

/// A reminder the student set for themselves. It schedules a local notification and never
/// changes anything on Canvas.
///
/// An item can have any number of reminders. Each one has its own notification identifier,
/// `<kind>-<item id>-<uuid>`, and its details live in `PersonalReminderStore`.
struct PersonalReminder: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var target: Target
    /// What the reminder is about, e.g. the assignment's name or the student's own text.
    var title: String
    var note: String?
    var timing: Timing
    let createdAt: Date

    init(
        id: UUID = UUID(),
        target: Target,
        title: String,
        note: String? = nil,
        timing: Timing,
        createdAt: Date = .now
    ) {
        self.id = id
        self.target = target
        self.title = title
        self.note = note
        self.timing = timing
        self.createdAt = createdAt
    }

    var fireDate: Date { timing.fireDate }

    var notificationIdentifier: String {
        "\(target.kind)-\(target.itemID ?? "personal")-\(id.uuidString)"
    }

    /// The thing a reminder is about. `.personal` isn't tied to anything on Canvas.
    enum Target: Codable, Hashable, Sendable {
        case assignment(id: String, courseID: String?)
        case quiz(id: String, courseID: String?)
        case calendarEvent(uid: String, courseID: String?)
        case toDo(id: String)
        case announcement(id: String, courseID: String?)
        case personal

        var kind: String {
            switch self {
            case .assignment: "assignment"
            case .quiz: "quiz"
            case .calendarEvent: "event"
            case .toDo: "todo"
            case .announcement: "announcement"
            case .personal: "personal"
            }
        }

        var itemID: String? {
            switch self {
            case .assignment(let id, _), .quiz(let id, _), .announcement(let id, _), .toDo(let id):
                id
            case .calendarEvent(let uid, _):
                uid
            case .personal:
                nil
            }
        }

        /// What tapping the notification opens, in the format `HomeView.handleSpotlightDeepLink` reads.
        /// Calendar events and personal reminders just open the app.
        var deepLinkIdentifier: String? {
            switch self {
            case .assignment(let id, _): "assignment:\(id)"
            case .quiz(let id, _): "quiz:\(id)"
            case .announcement(let id, _): "announcement:\(id)"
            case .toDo(let id): "todo:\(id)"
            case .calendarEvent, .personal: nil
            }
        }

        var systemImage: String {
            switch self {
            case .assignment: "doc.text"
            case .quiz: "questionmark.circle"
            case .calendarEvent: "calendar"
            case .toDo: "checklist"
            case .announcement: "megaphone"
            case .personal: "person.crop.circle"
            }
        }
    }

    enum Timing: Codable, Hashable, Sendable {
        case absolute(Date)
        /// `offset` before `anchor`, the item's due (or start) date. When the due date moves,
        /// the anchor moves with it and the reminder is rescheduled.
        case relative(offset: TimeInterval, anchor: Date)

        var fireDate: Date {
            switch self {
            case .absolute(let date): date
            case let .relative(offset, anchor): anchor.addingTimeInterval(-offset)
            }
        }

        var isRelative: Bool {
            if case .relative = self { true } else { false }
        }

        /// "1 day before due", "2 hours before due", or nil for absolute reminders.
        var relativeDescription: String? {
            guard case .relative(let offset, _) = self else { return nil }
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.day, .hour, .minute]
            formatter.unitsStyle = .full
            formatter.maximumUnitCount = 2
            return formatter.string(from: offset).map { "\($0) before due" }
        }
    }
}

extension PersonalReminder {
    /// Relative presets offered next to an item with a due date.
    static let relativePresets: [(label: String, offset: TimeInterval)] = [
        ("3 days before", 3 * 86_400),
        ("1 day before", 86_400),
        ("2 hours before", 2 * 3_600),
        ("30 minutes before", 30 * 60),
    ]

    /// Moves a relative reminder to follow `newAnchor`. Absolute reminders and unchanged anchors
    /// come back as they were.
    func reanchored(to newAnchor: Date) -> PersonalReminder {
        guard case let .relative(offset, anchor) = timing, anchor != newAnchor else { return self }
        var copy = self
        copy.timing = .relative(offset: offset, anchor: newAnchor)
        return copy
    }

    /// The notification body: the student's note, or how long until the item is due.
    func notificationBody(dueDate: Date?) -> String {
        if let note, !note.isEmpty { return note }
        guard let dueDate, dueDate > fireDate else { return "" }
        return "Due in \(Date.timeDeltaString(from: fireDate, to: dueDate))"
    }
}

/// Saves reminders as one JSON file in Application Support.
struct PersonalReminderStore: Sendable {
    let url: URL

    static let `default` = PersonalReminderStore(
        url: URL.applicationSupportDirectory.appending(path: "personal-reminders.json")
    )

    func load() -> [PersonalReminder] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        do {
            return try JSONDecoder().decode([PersonalReminder].self, from: data)
        } catch {
            LoggerService.main.error("[Reminders] Couldn't read saved reminders: \(error)")
            return []
        }
    }

    func save(_ reminders: [PersonalReminder]) {
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(reminders).write(to: url, options: .atomic)
        } catch {
            LoggerService.main.error("[Reminders] Couldn't save reminders: \(error)")
        }
    }
}
