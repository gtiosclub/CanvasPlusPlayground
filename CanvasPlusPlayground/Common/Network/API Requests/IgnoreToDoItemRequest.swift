//
//  MarkCourseDiscussionTopicUnreadRequest 2.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 3/29/25.
//

struct IgnoreToDoItemRequest: NoReturnAPIRequest {
    let ignoreURL: String

    var path: String { "" }
    var forceURL: String? { ignoreURL }
    var method: RequestMethod { .DELETE }
    var queryParameters: [QueryParameter] { [] }
}
