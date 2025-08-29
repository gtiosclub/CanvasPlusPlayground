//
//  CourseListCell.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 12/28/24.
//

import SwiftUI

struct CourseListCell: View {
    @Environment(CourseManager.self) private var courseManager

    let course: Course

    @State private var showColorPicker = false
    @State private var resolvedCourseColor: Color = .accentColor

    @State private var showRenameTextField = false
    @State private var renameCourseFieldText: String = ""

    @State private var isLoadingFavorite: Bool = false

    var body: some View {
        Label(course.displayName, systemImage: "book.pages")
            .frame(alignment: .leading)
            .multilineTextAlignment(.leading)
            #if os(macOS)
            .padding(.vertical, 4)
            #endif
            .onAppear {
                resolvedCourseColor = course.rgbColors?.color ?? .accentColor
            }
            .swipeActions(edge: .trailing) {
                favCourseButton
            }
            .contextMenu {
                Button("Change Color", systemImage: "paintbrush.fill") {
                    showColorPicker = true
                }

                favCourseButton

                Button("Rename Course...", systemImage: "character.cursor.ibeam") {
                    renameCourseFieldText = course.nickname ?? ""
                    showRenameTextField = true
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
            #if os(macOS)
            .popover(isPresented: $showColorPicker) {
                ColorPicker(selection: $resolvedCourseColor) { }
                    .onDisappear {
                        course.rgbColors = .init(color: resolvedCourseColor)
                    }
            }
            #elseif os(iOS)
            .colorPickerSheet(
                isPresented: $showColorPicker,
                selection: $resolvedCourseColor
            ) {
                course.rgbColors = .init(color: resolvedCourseColor)
            }
            #endif
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
