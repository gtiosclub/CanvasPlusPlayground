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

    @State private var showCourseCustomizer = false
    @State private var showRenameTextField = false
    @State private var renameCourseFieldText: String = ""

    @State private var isLoadingFavorite: Bool = false

    var body: some View {
        Label(course.displayName, systemImage: course.displaySymbol)
            .frame(alignment: .leading)
            .multilineTextAlignment(.leading)
            #if os(macOS)
            .padding(.vertical, 4)
            #endif
            .swipeActions(edge: .trailing) {
                favCourseButton
            }
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
                CustomizeCourseView(courseName: course.displayName, selectedSymbol: course.displaySymbol, selectedColor: course.rgbColors?.color ?? .accentColor, onDismiss: { (symbol, color) in
                    course.rgbColors = .init(color: color)
                    course.courseSymbol = symbol
                })
            }
            #elseif os(iOS)
            .sheet(isPresented: $showCourseCustomizer) {
                CustomizeCourseView(courseName: course.displayName, selectedSymbol: course.displaySymbol, selectedColor: course.rgbColors?.color ?? .accentColor, onDismiss: { (symbol, color) in
                    course.rgbColors = .init(color: color)
                    course.courseSymbol = symbol
                })
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
