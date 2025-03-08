//
//  SubmitAssignmentRequest.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 3/7/25.
//

import Foundation

struct SubmitAssignmentRequest: NoReturnAPIRequest {
    let courseID: String
    let assignmentID: String
    let submissionType: Assignment.SubmissionType
    
    let textComment: String?
    let groupComment: String?
    let body: String?
    let url: String?
    let fileIds: [Int]?
    let mediaCommentId: String?
    let mediaCommentType: String?
    let userId: Int?
    let annotatableAttachmentIds: Int?
    let submittedAt: Date?
    
    
    init(courseID: String,
         assignmentID: String,
         submissionType: Assignment.SubmissionType,
         textComment: String? = nil,
         groupComment: String? = nil,
         body: String? = nil,
         url: String? = nil,
         fileIds: [Int]? = nil,
         mediaCommentId: String? = nil,
         mediaCommentType: String? = nil,
         userId: Int? = nil,
         annotatableAttachmentIds: Int? = nil,
         submittedAt: Date? = nil,
         queryParameters: [QueryParameter] = []
    ) {
        self.courseID = courseID
        self.assignmentID = assignmentID
        self.submissionType = submissionType
        self.textComment = textComment
        self.groupComment = groupComment
        self.body = body
        self.url = url
        self.fileIds = fileIds
        self.mediaCommentId = mediaCommentId
        self.mediaCommentType = mediaCommentType
        self.userId = userId
        self.annotatableAttachmentIds = annotatableAttachmentIds
        self.submittedAt = submittedAt
        self.queryParameters = queryParameters
    }
    
    var path: String {
        "/api/v1/courses/\(courseID)/assignments/\(assignmentID)/submissions"
    }
    
    var queryParameters: [QueryParameter] = []
}
