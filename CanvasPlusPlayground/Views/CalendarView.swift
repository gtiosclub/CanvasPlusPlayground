//
//  CalendarView.swift
//  CanvasPlusPlayground
//
//  Created by Jiyoon Lee on 9/19/24.
//

import SwiftUI

struct CalendarView: View {
let course: Course
   var body: some View {
       if let icsURL = course.calendar?.ics, let url = URL(string: icsURL) {
        Link("Open in Calendar", destination: url)
       } else {
           Text("No calendar available")
       }
   }
}
