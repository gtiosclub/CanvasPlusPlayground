//
//  MarkDiscussionTopicReadRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 2/15/25.
//

struct MarkCourseDiscussionTopicReadRequest: NoReturnAPIRequest {
    let courseID: String
    let discussionID: String

    var path: String { "courses/\(courseID)/discussion_topics/discussion_topics/\(discussionID)/read" }
    var method: RequestMethod { .PUT }
    var queryParameters: [QueryParameter] { [] }
}
