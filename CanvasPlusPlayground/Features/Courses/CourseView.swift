//
//  CourseView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/8/24.
//

import SwiftUI

struct CourseView: View {
    @Environment(NavigationModel.self) private var navigationModel
    let course: Course

    var body: some View {
        @Bindable var navigationModel = navigationModel

        List(NavigationModel.CoursePage.allCases, id: \.self, selection: $navigationModel.selectedCoursePage) { page in
            NavigationLink(value: page) {
                Label(page.title, systemImage: page.systemImageIcon)
            }
        }
        .tint(course.rgbColors?.color)
        .navigationTitle(course.displayName)
        .scrollContentBackground(course.rgbColors?.color == nil ? .automatic : .hidden)
        .background(alignment: .top) {
            if let color = course.rgbColors?.color {
                color
                    .overlay {
                        LinearGradient(colors: [color, color.opacity(0)], startPoint: .top, endPoint: .bottom)
                            .hueRotation(.degrees(35))
                            .blendMode(.overlay)
                    }
                    .mask {
                        LinearGradient(colors: [.black.opacity(0.5), .black.opacity(0)], startPoint: .top, endPoint: .bottom)
                    }
                    .frame(height: 200)
                    .ignoresSafeArea()
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.sidebar)
        #endif
    }
}
