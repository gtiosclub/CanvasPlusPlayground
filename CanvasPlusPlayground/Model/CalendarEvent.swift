//
//  CalendarEvent.swift
//  CanvasPlusPlayground
//
//  Created by Tejeshwar Natarajan on 10/4/24.
//

import Foundation

struct CalendarEvent : Identifiable {
    var id: String?
    var lastUpdated: Date?
    var eventName : String?
    var startDate: Date?
    var endDate: Date?
    var location : String?
    var description : String?
}
