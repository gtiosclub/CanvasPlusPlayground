//
//  ChangeBaseline.swift
//  CanvasPlusPlayground
//
//  Created by Kareem Alaiwat on 11/1/26.
//

struct ChangeBaseline: Codable, Hashable, Sendable {
    let courseID: String
    let family: ChangeResourceFamily
}

enum ChangeResourceFamily: String, Codable, CaseIterable, Sendable {
    case assignments
    case announcements
}
