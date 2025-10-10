//
//  CustomizeCourseMenu.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 10/1/25.
//

import SwiftUI

struct CustomizeCourseMenu: ViewModifier {
    @Environment(CourseManager.self) private var courseManager
    let course: Course

    @State private var showCourseCustomizer = false
    @State private var showRenameTextField = false
    @State private var renameCourseFieldText: String = ""
    @State private var isLoadingFavorite: Bool = false

    /// The Course actions menu used in context menu and toolbar
    private var courseActionsMenu: some View {
        Menu {
            courseActions
        } label: {
            Label("Course Actions", systemImage: "ellipsis")
        }
    }

    // FYI, these buttons are wrapped in a menu on the macos toolbar button, on iOS it's just a group
    private var courseActions: some View {
        Group {
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
    }

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    func body(content: Content) -> some View {
        content
            .contextMenu {
                if horizontalSizeClass != .regular {
                    courseActions
                }
            }
            .toolbar {
                if horizontalSizeClass == .regular {
                    courseActionsMenu
                }
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
            .sheet(isPresented: $showCourseCustomizer) {
                CustomizeCourseView(courseName: course.displayName, selectedSymbol: course.displaySymbol, selectedColor: course.rgbColors?.color ?? .accentColor, onDismiss: { symbol, color in
                    course.rgbColors = .init(color: color)
                    course.courseSymbol = symbol
                })
            }
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
    /// Adds the course customization context menu/toolbar button to a view.
    /// Is applied as a toolbar button in macOS, otherwise, context menu
    func customizeCourseMenu(course: Course) -> some View {
        self.modifier(CustomizeCourseMenu(course: course))
    }
}
