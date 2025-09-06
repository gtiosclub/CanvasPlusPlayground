//
//  GetSubmissionsRequest.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox  on 9/5/25.
//

import Foundation
import Playgrounds

struct GetSubmissionsRequest: APIRequest {
    typealias Subject = SubmissionAPI

    let courseId: String
    let assignmentId: String
    let userId: String
    let include: [Include] = [.submission_history, .submission_comments]
    
    var path: String { "/courses/\(courseId)/assignments/\(assignmentId)/submissions/\(userId)" }
    var queryParameters: [QueryParameter] {
        [
    
        ]
        + include.map { ("include[]", $0.rawValue) }

    }
}

extension GetSubmissionsRequest {
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


#Playground {
    
    
        
    
}

