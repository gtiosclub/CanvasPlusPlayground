//
//  ReminderButton.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 2/25/25.
//

import SwiftUI

/// Toolbar bell for an item. Filled when the item has an upcoming reminder; opens a sheet
/// listing its reminders and adding more.
struct ReminderButton: View {
    @Environment(RemindersManager.self) private var reminderManager
    @State private var showSheet = false

    let item: ReminderType

    var body: some View {
        let hasReminder = reminderManager.itemHasReminder(item)

        Button {
            showSheet = true
        } label: {
            Image(systemName: hasReminder ? "bell.fill" : "bell")
                .symbolEffect(.wiggle, options: .speed(3), value: hasReminder)
        }
        .accessibilityLabel(hasReminder ? "Reminders, on" : "Add reminder")
        .sheet(isPresented: $showSheet) {
            ReminderEditorSheet(context: .item(item))
        }
    }
}

/// What a reminder sheet is editing.
enum ReminderEditorContext {
    /// Add reminders to an item (and see the ones it already has).
    case item(ReminderType)
    /// A new reminder not tied to anything.
    case personal
    /// Change one saved reminder.
    case edit(PersonalReminder)
}

struct ReminderEditorSheet: View {
    @Environment(RemindersManager.self) private var reminderManager
    @Environment(\.dismiss) private var dismiss

    let context: ReminderEditorContext

    @State private var title = ""
    @State private var note = ""
    @State private var selectedDate = Date.now.addingTimeInterval(3_600)
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                if case .item = context, !existing.isEmpty {
                    Section("Set") {
                        ForEach(existing) { reminder in
                            ReminderRow(reminder: reminder)
                                .swipeActions {
                                    Button("Delete", role: .destructive) { reminderManager.delete(reminder) }
                                }
                                .contextMenu {
                                    Button("Delete", systemImage: "trash", role: .destructive) { reminderManager.delete(reminder) }
                                }
                        }
                    }
                }

                if needsTitle {
                    Section("Reminder") {
                        TextField("What to remember", text: $title)
                        TextField("Note (optional)", text: $note, axis: .vertical)
                    }
                }

                if let dueDate, isAdding {
                    Section {
                        ForEach(PersonalReminder.relativePresets, id: \.offset) { preset in
                            let fireDate = dueDate.addingTimeInterval(-preset.offset)
                            Button {
                                save(.relative(offset: preset.offset, anchor: dueDate))
                            } label: {
                                LabeledContent(preset.label, value: fireDate.formatted(date: .abbreviated, time: .shortened))
                            }
                            .disabled(fireDate <= .now)
                        }
                    } header: {
                        Text("Before It's Due")
                    } footer: {
                        Text("These move with the due date if your instructor changes it.")
                    }
                }

                if isAdding {
                    Section("Quick Options") {
                        quickButton("bell", .yellow, "Tomorrow", .tomorrowAt8am)
                        quickButton("sofa", .purple, "This Weekend", .nextOrdinalAt8am(weekday: 7))
                        quickButton("calendar.badge.clock", .green, "Next Week", .nextOrdinalAt8am(weekday: 2))
                    }
                }

                Section {
                    DatePicker("Remind me at", selection: $selectedDate, in: Date.now...)
                        #if os(iOS)
                        .datePickerStyle(.graphical)
                        #endif
                } header: {
                    Text(isAdding ? "Custom" : "Time")
                } footer: {
                    Text("Reminders are personal. They only notify you on this device and never change anything on Canvas.")
                }
            }
            .navigationTitle(navigationTitle)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .formStyle(.grouped)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isAdding ? "Add" : "Save") {
                        if case .edit(let reminder) = context, reminder.timing.isRelative, let dueDate {
                            // Keep it relative: work out the new offset from the picked time.
                            save(.relative(offset: max(dueDate.timeIntervalSince(selectedDate), 0), anchor: dueDate))
                        } else {
                            save(.absolute(selectedDate))
                        }
                    }
                    .disabled(needsTitle && title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: prefill)
        }
        .presentationDragIndicator(.visible)
        .alert("Couldn't Set Reminder", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: Context

    private var item: ReminderType? {
        if case .item(let item) = context { item } else { nil }
    }

    private var isAdding: Bool {
        if case .edit = context { false } else { true }
    }

    private var needsTitle: Bool {
        switch context {
        case .personal: true
        case .edit(let reminder): reminder.target == .personal
        case .item: false
        }
    }

    private var existing: [PersonalReminder] {
        item.map { reminderManager.reminders(for: $0.target) } ?? []
    }

    private var dueDate: Date? {
        switch context {
        case .item(let item): item.dueDate
        case .edit(let reminder):
            if case .relative(_, let anchor) = reminder.timing { anchor } else { nil }
        case .personal: nil
        }
    }

    private var navigationTitle: String {
        switch context {
        case .item(let item): item.title
        case .personal: "New Reminder"
        case .edit: "Edit Reminder"
        }
    }

    private func prefill() {
        guard case .edit(let reminder) = context else { return }
        title = reminder.title
        note = reminder.note ?? ""
        selectedDate = max(reminder.fireDate, .now)
    }

    // MARK: Saving

    private func quickButton(_ image: String, _ color: Color, _ text: String, _ date: Date) -> some View {
        Button {
            save(.absolute(date))
        } label: {
            HStack {
                Image(systemName: image)
                    .foregroundStyle(color)
                    .imageScale(.large)
                    .frame(width: 32)
                    .bold()
                Text(text).bold()
                Spacer()
                Text(date.dayOfWeekString())
                    .textCase(.uppercase)
                    .font(.callout)
                    .opacity(0.75)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private func save(_ timing: PersonalReminder.Timing) {
        let timing = Self.minutePrecision(timing)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        let reminder: PersonalReminder
        switch context {
        case .item(let item):
            reminder = PersonalReminder(target: item.target, title: item.title, timing: timing)
        case .personal:
            reminder = PersonalReminder(target: .personal, title: title.trimmingCharacters(in: .whitespaces), note: trimmedNote.isEmpty ? nil : trimmedNote, timing: timing)
        case .edit(var edited):
            edited.timing = timing
            if edited.target == .personal {
                edited.title = title.trimmingCharacters(in: .whitespaces)
                edited.note = trimmedNote.isEmpty ? nil : trimmedNote
            }
            reminder = edited
        }

        Task {
            do {
                if case .edit = context {
                    try await reminderManager.update(reminder, dueDate: dueDate)
                } else {
                    try await reminderManager.add(reminder, dueDate: dueDate)
                }
                dismiss()
            } catch ReminderSchedulingError.invalidDate {
                errorMessage = "Pick a time in the future."
            } catch ReminderSchedulingError.notificationsDisbled {
                errorMessage = "Turn on notifications for Canvas Plus in Settings to get reminders."
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    /// Notifications fire on the minute, so drop seconds.
    static func minutePrecision(_ timing: PersonalReminder.Timing) -> PersonalReminder.Timing {
        switch timing {
        case .absolute(let date):
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            return .absolute(Calendar.current.date(from: components) ?? date)
        case .relative:
            return timing
        }
    }
}

/// One reminder: when, and what it's for.
struct ReminderRow: View {
    let reminder: PersonalReminder
    var showsTitle = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: reminder.target.systemImage)
                .foregroundStyle(.tint)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                if showsTitle {
                    Text(reminder.title)
                        .font(.headline)
                        .lineLimit(2)
                }
                Text(reminder.fireDate.formatted(date: .abbreviated, time: .shortened))
                    .font(showsTitle ? .subheadline : .body)
                if let relative = reminder.timing.relativeDescription {
                    Text(relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let note = reminder.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }
}
