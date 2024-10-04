//
//  Syllabus.swift
//  CanvasPlusPlayground
//
//  Created by Songyuan Liu on 10/4/24.
//

import Foundation

struct Metadata: Codable {
    let clientIP: String
    let eventName: String
    let eventTime: String
    let hostname: String
    let httpMethod: String
    let producer: String
    let referrer: String
    let requestId: String
    let rootAccountId: String
    let rootAccountLTIGuid: String
    let rootAccountUUID: String
    let sessionId: String
    let timeZone: String
    let url: String
    let userAccountId: String
    let userAgent: String
    let userId: String
    let userLogin: String
    let userSISId: String

    enum CodingKeys: String, CodingKey {
        case clientIP = "client_ip"
        case eventName = "event_name"
        case eventTime = "event_time"
        case hostname
        case httpMethod = "http_method"
        case producer
        case referrer
        case requestId = "request_id"
        case rootAccountId = "root_account_id"
        case rootAccountLTIGuid = "root_account_lti_guid"
        case rootAccountUUID = "root_account_uuid"
        case sessionId = "session_id"
        case timeZone = "time_zone"
        case url
        case userAccountId = "user_account_id"
        case userAgent = "user_agent"
        case userId = "user_id"
        case userLogin = "user_login"
        case userSISId = "user_sis_id"
    }
}

// Model for body
struct Body: Codable {
    let courseId: String
    let oldSyllabusBody: String
    let syllabusBody: String

    enum CodingKeys: String, CodingKey {
        case courseId = "course_id"
        case oldSyllabusBody = "old_syllabus_body"
        case syllabusBody = "syllabus_body"
    }
}

struct SyllabusUpdate: Codable {
    let metadata: Metadata
    let body: Body
}
