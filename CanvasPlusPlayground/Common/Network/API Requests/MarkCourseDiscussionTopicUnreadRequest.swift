//
//  MarkDiscussionTopicUnreadRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 2/15/25.
//

struct MarkCourseDiscussionTopicUnreadRequest: NoReturnAPIRequest {
    let courseID: String
    let discussionID: String

    var path: String { "courses/\(courseID)/discussion_topics/discussion_topics/\(discussionID)/unread" }
    var method: RequestMethod { .DELETE }
    var queryParameters: [QueryParameter] { [] }
}
