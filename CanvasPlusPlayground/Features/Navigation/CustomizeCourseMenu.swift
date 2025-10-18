//
//  CustomizeCourseMenu.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 10/1/25.
//

import SwiftUI


enum CourseCustomizationMenuPlacement {
    case contextMenu
    case toolbar
}

private struct CustomizeCourseMenu: ViewModifier {
    @Environment(PickerService.self) private var pickerService: PickerService?
    @Environment(CourseManager.self) private var courseManager
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    let course: Course
    let placement: CourseCustomizationMenuPlacement

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

    func body(content: Content) -> some View {
        content
            .contextMenu {
                if placement == .contextMenu {
                    courseActions
                }
            }
            .toolbar {
                if placement == .toolbar && pickerService == nil {
                    courseActionsMenu
                    #if os(macOS)
                        .popover(isPresented: $showCourseCustomizer) {
                            customizeCourseView
                        }
                    #endif
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
            #if os(iOS)
            .sheet(isPresented: $showCourseCustomizer) {
                customizeCourseView
            }
            #endif
    }

    private var customizeCourseView: some View {
        CustomizeCourseView(courseName: course.displayName, selectedSymbol: course.displaySymbol, selectedColor: course.rgbColors?.color, onDismiss: { symbol, color in
            DispatchQueue.main.async {
                if let color {
                    course.rgbColors = .init(color: color)
                } else {
                    course.rgbColors = nil
                }

                course.courseSymbol = symbol
            }
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
    func customizeCourseMenu(course: Course, placement: CourseCustomizationMenuPlacement) -> some View {
        self.modifier(CustomizeCourseMenu(course: course, placement: placement))
    }
}
