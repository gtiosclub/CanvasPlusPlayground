//
//  MarkDiscussionTopicUnreadRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 2/15/25.
//
import Foundation

struct MarkCourseDiscussionTopicUnreadRequest: NoReturnAPIRequest {
    let courseID: String
    let discussionID: String

    var path: String { "courses/\(courseID)/discussion_topics/\(discussionID)/read" }
    var method: RequestMethod { .DELETE }
    var queryParameters: [QueryParameter] { [] }
    var body: Data? { nil }
}
