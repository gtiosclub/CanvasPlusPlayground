//
//  GetSubmissionsRequest.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 9/5/25.
//

import Foundation
import Playgrounds

struct GetSubmissionRequest: CacheableAPIRequest {
    typealias Subject = SubmissionAPI

    let courseId: String
    let assignmentId: String
    let userId: String
    let include: [Include] = [.submission_history, .submission_comments]
    
    var path: String { "/courses/\(courseId)/assignments/\(assignmentId)/submissions/\(userId)" }
    var queryParameters: [QueryParameter] {
        include.map { ("include[]", $0.rawValue) }

    }
    
    
    var requestId: String { "\(assignmentId)_\(userId)" }
    var requestIdKey: ParentKeyPath<Submission, String> { .createReadable(\.id) }
    var idPredicate: Predicate<Submission> {
        #Predicate<Submission> { submission in
            submission.id == requestId
        }
    }
    var customPredicate: Predicate<Submission> {
        .true
    }
}

extension GetSubmissionRequest {
    enum Include: String {
        case submission_history,
             submission_comments,
             rubric_assessment,
             full_rubric_assessment,
             visibility,
             course,
             user,
             read_status
    }
}
