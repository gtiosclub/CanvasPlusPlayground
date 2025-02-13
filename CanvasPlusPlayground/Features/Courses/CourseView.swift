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
                LinearGradient(colors: [color, color.opacity(0)], startPoint: .top, endPoint: .bottom)
                    .overlay {
                        LinearGradient(colors: [.white, .white.opacity(0)], startPoint: .center, endPoint: .bottom)
                            .blendMode(.overlay)
                            .opacity(0)
                    }
                    .opacity(0.5)
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
