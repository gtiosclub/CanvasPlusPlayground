//
//  MyRemindersView.swift
//  CanvasPlusPlayground
//

import SwiftUI

/// Every reminder the student has set: upcoming first, then recent ones that already fired.
/// Tap to edit, swipe to delete, + for a reminder that isn't tied to anything on Canvas.
struct MyRemindersView: View {
    @Environment(RemindersManager.self) private var reminderManager

    @State private var editing: PersonalReminder?
    @State private var showNew = false

    var body: some View {
        List {
            if !reminderManager.upcoming.isEmpty {
                Section("Upcoming") {
                    ForEach(reminderManager.upcoming) { reminder in
                        row(reminder)
                    }
                }
            }

            if !reminderManager.past.isEmpty {
                Section("Earlier") {
                    ForEach(reminderManager.past) { reminder in
                        row(reminder)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .overlay {
            if reminderManager.personalReminders.isEmpty {
                ContentUnavailableView {
                    Label("No Reminders", systemImage: "bell")
                } description: {
                    Text("Use the bell on an assignment or quiz, or add your own. Reminders only notify you and never change anything on Canvas.")
                } actions: {
                    Button("New Reminder") { showNew = true }
                }
            }
        }
        .navigationTitle("My Reminders")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("New Reminder", systemImage: "plus") { showNew = true }
            }
        }
        .sheet(isPresented: $showNew) {
            ReminderEditorSheet(context: .personal)
        }
        .sheet(item: $editing) { reminder in
            ReminderEditorSheet(context: .edit(reminder))
        }
    }

    private func row(_ reminder: PersonalReminder) -> some View {
        Button {
            editing = reminder
        } label: {
            ReminderRow(reminder: reminder, showsTitle: true)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .swipeActions {
            Button("Delete", role: .destructive) { reminderManager.delete(reminder) }
        }
        .contextMenu {
            Button("Edit", systemImage: "pencil") { editing = reminder }
            Button("Delete", systemImage: "trash", role: .destructive) { reminderManager.delete(reminder) }
        }
    }
}
