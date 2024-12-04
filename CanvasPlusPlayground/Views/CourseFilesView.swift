//
//  CourseFilesView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/7/24.
//

import SwiftUI

struct CourseFilesView: View {
    let course: Course
    let folder: Folder?
    @State private var fileManager: CourseFileManager

    init(course: Course, folder: Folder? = nil) {
        self.course = course
        self.folder = folder
        _fileManager = .init(initialValue: CourseFileManager(courseID: course.id))
    }

    var body: some View {
        NavigationStack {
            
            List {
                ForEach(fileManager.files, id: \.id) { file in
                    if let url = file.url, let url = URL(string: url)  {
                        NavigationLink(destination: CoursePDFView(url: url)) {
                            Text(file.displayName ?? "Couldn't find file name.")
                        }
                    } else {
                        Text("File not available")
                    }
                }
                
                ForEach(fileManager.folders, id: \.id) { subFolder in
                    NavigationLink(destination: CourseFilesView(course: course, folder: subFolder)) {
                        Text(subFolder.name ?? "Couldn't find folder name.")
                    }
                }
                
            }
            .task {
                if let folder {
                    await fileManager.fetchContent(in: folder)
                } else {
                    await fileManager.fetchRoot()
                }
            }
            .navigationTitle("Files")
            
        }
    }
}
