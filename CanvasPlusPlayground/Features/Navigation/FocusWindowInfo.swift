//
//  Course+Page.swift
//  CanvasPlusPlayground
//
//  Created by Steven Liu on 9/1/25.
//
import Foundation

struct FocusWindowInfo: Codable, Hashable {
    let courseID: Course.ID
    let coursePage: NavigationModel.CoursePage
}
