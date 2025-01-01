//
//  CourseFilesView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/7/24.
//

import SwiftUI

struct CourseFilesView: View {
    let course: Course

    var body: some View {
        NavigationStack {
            FoldersPageView(course: course)
        }
    }
}
