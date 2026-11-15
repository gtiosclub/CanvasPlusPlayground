import SwiftUI

struct EditCourseSectionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: CourseSectionStore
    let course: Course

    private var pagesToAdd: [NavigationModel.CoursePage] {
        NavigationModel.CoursePage.available(for: course).filter { !store.layout.pages.contains($0) }
    }

    // macOS draws list separators through a row's content, so its empty state sits above the list instead.
    private var showsSectionList: Bool {
        #if os(macOS)
        !store.layout.pages.isEmpty
        #else
        true
        #endif
    }

    var body: some View {
        List {
            if showsSectionList {
                Section("Sections") {
                    #if os(iOS)
                    if store.layout.pages.isEmpty {
                        ContentUnavailableView("No Sections", systemImage: "rectangle.stack")
                    }
                    #endif
                    ForEach(store.layout.pages, id: \.self) { page in
                        HStack {
                            Label(page.title, systemImage: page.systemImageIcon)
                            #if os(macOS)
                            // macOS rows here are not selectable, so onDelete has no trigger.
                            Spacer()
                            Button {
                                if let index = store.layout.pages.firstIndex(of: page) {
                                    store.layout.remove(at: IndexSet(integer: index))
                                }
                            } label: {
                                Label("Remove \(page.title)", systemImage: "minus.circle")
                                    .labelStyle(.iconOnly)
                            }
                            .buttonStyle(.borderless)
                            .help("Remove \(page.title)")
                            #endif
                        }
                    }
                    .onMove { store.layout.move(from: $0, to: $1) }
                    .onDelete { store.layout.remove(at: $0) }
                }
            }
            Section("Add Section") {
                if pagesToAdd.isEmpty {
                    Text(course.tabs.isEmpty ? "Course tabs have not loaded yet." : "All available sections are added.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    FlowLayout(spacing: 8) {
                        ForEach(pagesToAdd, id: \.self) { page in
                            Button {
                                store.layout.add(page)
                            } label: {
                                Label(page.title, systemImage: page.systemImageIcon)
                                    .labelStyle(.titleAndIcon)
                            }
                            .buttonStyle(.bordered)
                            .fixedSize()
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        #if os(iOS)
        .navigationTitle("Edit Sections")
        .environment(\.editMode, .constant(.active))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Reset") { store.layout.reset() }
                    .accessibilityLabel("Reset to Default")
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        #else
        .safeAreaInset(edge: .top) {
            VStack(alignment: .leading) {
                Text("Edit Sections")
                    .font(.headline)
                if store.layout.pages.isEmpty {
                    ContentUnavailableView("No Sections", systemImage: "rectangle.stack")
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding([.horizontal, .top])
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button("Reset to Default") { store.layout.reset() }
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        #endif
    }
}

/// Places subviews left to right and starts a new row when the next one would not fit.
private struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let frames = frames(for: subviews, maxWidth: proposal.width ?? .infinity)
        return CGSize(width: frames.map(\.maxX).max() ?? 0, height: frames.map(\.maxY).max() ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (subview, frame) in zip(subviews, frames(for: subviews, maxWidth: bounds.width)) {
            subview.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    /// - Parameters:
    ///   - subviews: The views to arrange, in order.
    ///   - maxWidth: The widest a row may get before the next view moves to a new row.
    /// - Returns: One frame per subview, relative to the layout's top-left corner.
    private func frames(for subviews: Subviews, maxWidth: CGFloat) -> [CGRect] {
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            // x > 0 keeps a view wider than maxWidth on its own row instead of wrapping forever.
            if x > 0 && x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return frames
    }
}
