//
//  CanvasSchemaV1.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 4/17/25.
//

import SwiftData

enum CanvasSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Course.self,
            Announcement.self,
            Assignment.self,
            AssignmentGroup.self,
            Enrollment.self,
            File.self,
            Folder.self,
            Quiz.self,
            Module.self,
            ModuleItem.self,
            Submission.self,
            User.self,
            Profile.self,
            DiscussionTopic.self,
            Page.self,
            CanvasGroup.self,
            GroupMembership.self,
            CanvasTab.self,
            ToDoItem.self,
            ToDoItemCount.self
        ]
    }
}
