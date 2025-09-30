// CourseContextMenuModifier.swift
// A reusable ViewModifier for attaching the Course context menu to any SwiftUI view

import SwiftUI

struct CourseContextMenuModifier: ViewModifier {
    @Environment(CourseManager.self) private var courseManager
    let course: Course
    
    @State private var showCourseCustomizer = false
    @State private var showRenameTextField = false
    @State private var renameCourseFieldText: String = ""
    @State private var isLoadingFavorite: Bool = false
    
    func body(content: Content) -> some View {
        content
            .contextMenu {
                Button("Customize Course", systemImage: "paintbrush.fill") {
                    showCourseCustomizer = true
                }

                favCourseButton

                Button("Rename Course...", systemImage: "character.cursor.ibeam") {
                    renameCourseFieldText = course.nickname ?? ""
                    showRenameTextField = true
                }

                NewWindowButton(destination: .course(course))
            }
            .alert("Rename Course", isPresented: $showRenameTextField) {
                TextField(course.name ?? "", text: $renameCourseFieldText)

                Button("OK") { renameCourse() }

                Button("Cancel", role: .cancel) {
                    renameCourseFieldText = ""
                }
            } message: {
                Text("Rename \(course.name ?? "")?")
            }
            #if os(macOS)
            .popover(isPresented: $showCourseCustomizer) {
                customizeCourseView
            }
            #elseif os(iOS)
            .sheet(isPresented: $showCourseCustomizer) {
                customizeCourseView
            }
            #endif
    }
    
    private var customizeCourseView: some View {
        CustomizeCourseView(courseName: course.displayName, selectedSymbol: course.displaySymbol, selectedColor: course.rgbColors?.color ?? .accentColor, onDismiss: { (symbol, color) in
            course.rgbColors = .init(color: color)
            course.courseSymbol = symbol
        })
    }

    private var favCourseButton: some View {
        Button(
            course.isFavorite ? "Unfavorite Course" : "Favorite Course",
            systemImage: "star"
        ) {
            Task {
                await course.markIsFavorite(as: !course.isFavorite)
            }

        }
        .symbolVariant(!course.isFavorite ? .none : .slash)
        .tint(.gray)
    }

    private func renameCourse() {
        if renameCourseFieldText.isEmpty {
            course.nickname = nil
        } else {
            course.nickname = renameCourseFieldText
            renameCourseFieldText = ""
        }
    }
}

extension View {
    func courseContextMenu(course: Course) -> some View {
        self.modifier(CourseContextMenuModifier(course: course))
    }
}
