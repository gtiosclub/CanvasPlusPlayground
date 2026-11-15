import SwiftUI

struct EditCourseSectionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: CourseSectionStore
    let course: Course

    private var pagesToAdd: [NavigationModel.CoursePage] {
        NavigationModel.CoursePage.available(for: course).filter { !store.layout.pages.contains($0) }
    }

    var body: some View {
        List {
            Section("Sections") {
                ForEach(store.layout.pages, id: \.self) { page in
                    Label(page.title, systemImage: page.systemImageIcon)
                }
                .onMove { store.layout.move(from: $0, to: $1) }
                .onDelete { store.layout.remove(at: $0) }
            }
            Section("Add Section") {
                ForEach(pagesToAdd, id: \.self) { page in
                    Button {
                        store.layout.add(page)
                    } label: {
                        Label(page.title, systemImage: "plus.circle")
                    }
                }
                if pagesToAdd.isEmpty {
                    Text(course.tabs.isEmpty ? "Course tabs have not loaded yet." : "All available sections are added.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Section {
                Button("Reset to Default") { store.layout.reset() }
            }
        }
        .navigationTitle("Edit Sections")
        #if os(iOS)
        .environment(\.editMode, .constant(.active))
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}
