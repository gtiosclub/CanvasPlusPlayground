//
//  Calendar.swift
//  CanvasPlusPlayground
//
//  Created by Jiyoon Lee on 9/14/24.
//

import Foundation

struct Calendar: Identifiable, Codable {
    let id: Int
    let title: String
    let startAt: String
    let endAt: String
    let description: String?
    let locationName: String?
    let locationAddress: String?
    let contextCode: String
    let contextName: String
    let allContextCodes: String
    let workflowState: String
    let hidden: Bool
    let parentEventId: Int?
    let childEventsCount: Int
    let childEvents: [Calendar]?
    let url: String
    let htmlUrl: String
    let allDayDate: String?
    let allDay: Bool
    let createdAt: String
    let updatedAt: String
    let appointmentGroupId: Int?
    let appointmentGroupUrl: String?
    let ownReservation: Bool
    let reserveUrl: String?
    let reserved: Bool
    let participantType: String
    let participantsPerAppointment: Int?
    let availableSlots: Int?
    let user: User?
    let group: Group?
    let importantDates: Bool
    let seriesUuid: String?
    let rrule: String?
    let seriesHead: Bool?
    let seriesNaturalLanguage: String?
    let blackoutDate: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case startAt = "start_at"
        case endAt = "end_at"
        case description
        case locationName = "location_name"
        case locationAddress = "location_address"
        case contextCode = "context_code"
        case contextName = "context_name"
        case allContextCodes = "all_context_codes"
        case workflowState = "workflow_state"
        case hidden
        case parentEventId = "parent_event_id"
        case childEventsCount = "child_events_count"
        case childEvents = "child_events"
        case url
        case htmlUrl = "html_url"
        case allDayDate = "all_day_date"
        case allDay = "all_day"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case appointmentGroupId = "appointment_group_id"
        case appointmentGroupUrl = "appointment_group_url"
        case ownReservation = "own_reservation"
        case reserveUrl = "reserve_url"
        case reserved
        case participantType = "participant_type"
        case participantsPerAppointment = "participants_per_appointment"
        case availableSlots = "available_slots"
        case user
        case group
        case importantDates = "important_dates"
        case seriesUuid = "series_uuid"
        case rrule
        case seriesHead = "series_head"
        case seriesNaturalLanguage = "series_natural_language"
        case blackoutDate = "blackout_date"
    }
}

struct Group: Codable, Equatable, Hashable {
    let id: Int
    let name: String
    let description: String?
    let isPublic: Bool
    let followedByUser: Bool
    let joinLevel: String
    let membersCount: Int
    let avatarURL: URL
    let contextType: String
    let courseID: Int
    let role: String?
    let groupCategoryID: Int
    let sisGroupID: String?
    let sisImportID: Int?
    let storageQuotaMB: Int
    let permissions: Permissions?
    let users: [User]?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case isPublic = "is_public"
        case followedByUser = "followed_by_user"
        case joinLevel = "join_level"
        case membersCount = "members_count"
        case avatarURL = "avatar_url"
        case contextType = "context_type"
        case courseID = "course_id"
        case role
        case groupCategoryID = "group_category_id"
        case sisGroupID = "sis_group_id"
        case sisImportID = "sis_import_id"
        case storageQuotaMB = "storage_quota_mb"
        case permissions
        case users
    }
}

