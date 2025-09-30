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

    var body: some View {
        Label(course.displayName, systemImage: course.displaySymbol)
            .frame(alignment: .leading)
            .multilineTextAlignment(.leading)
            #if os(macOS)
            .padding(.vertical, 4)
            #endif
            .courseContextMenu(course: course)
    }
}
