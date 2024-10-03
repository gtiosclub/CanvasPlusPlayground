//
//  IndividualCourseListView.swift
//  CanvasPlusPlayground
//
//  Created by Vamsi Putti on 10/3/24.
//

import SwiftUI

struct IndividualCourseListView: View {
    @Environment(CourseManager.self) var courseManager
    @State var isPref = false
    let course: Course
    
    var body: some View {
        @Bindable var courseManager = courseManager
        
        HStack {
            Button {
                isPref.toggle()
                if isPref {
                    withAnimation {
                        courseManager.addPref(course: course)
                    }
                } else {
                    withAnimation {
                        courseManager.removePref(course: course)
                    }
                }
            } label: {
                Image(systemName: isPref ? "star.fill" : "star")
            }
            NavigationLink(destination: CourseView(course: course), label: {
                Text(course.name ?? "")
                    .frame(alignment: .leading)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                
            })
            .foregroundStyle(.black)
            
        }
        .padding()
        .background(.white)
        .cornerRadius(15)
    }
    
    func addPreference() {
        
    }
}

#Preview {
//    IndividualCourseListView()
}
