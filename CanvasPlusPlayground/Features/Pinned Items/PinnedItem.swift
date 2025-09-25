//
//  PinnedItem.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 1/9/25.
//

import Foundation

@Observable
class PinnedItem: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let courseID: String
    let type: PinnedItemType
    var data: PinnedItemData?

    private var course: Course?
    private var modelData: PinnedItemData.ModelData?

    enum PinnedItemType: Int, Codable {
        case announcement, assignment, file, quiz, grade, module
        // TODO: Add more pinned item types

        var displayName: String {
            switch self {
            case .announcement:
                "Announcements"
            case .assignment:
                "Assignments"
            case .file:
                "Files"
			case .quiz:
				"Quizzes"
            case .grade:
                "Grades"
            case .module:
                "Modules"
            }

        }
    }

    func itemData() async {
        do {
//            try await fetchData()
//            // TODO: use new course infra
//            try await CanvasService.shared.loadAndSync(
//                CanvasRequest.getCourse(id: courseID)
//            ) { cachedCourse in
//                    guard let course = cachedCourse?.first else { return }
//                    setData(course: course)
//            }
			try await fetchData()
			try await CanvasService.shared.loadFirstThenSync(
				CanvasRequest.getCourse(id: courseID),
				onCacheReceive: { [weak self] cachedCourse in
					guard let self, let course = cachedCourse?.first else { return }
					self.setData(course: course)
				}, onSyncComplete: { [weak self] syncedCourse in
					guard let self, let course = syncedCourse?.first else { return }
					self.setData(course: course)
				}
			)
        } catch {
            LoggerService.main.error("Error fetching \(self.type.displayName)")
        }
    }

    private func fetchData() async throws {
        switch type {
        case .announcement:
//            let announcements = try await CanvasService.shared.loadAndSync(
//                CanvasRequest.getDiscussionTopics(courseId: courseID)
//            ) { cachedAnnouncements in
//                    guard let announcement = cachedAnnouncements?.first(where: { $0.id == id }) else { return }
//                    setData(modelData: .announcement(announcement))
//            }
//            guard let announcement = announcements.first(where: { $0.id == id }) else { return }
//            setData(modelData: .announcement(announcement))
			try await loadItemData(
				request: CanvasRequest.getDiscussionTopics(courseId: courseID),
				findItem: { $0?.first(where: { $0.id == self.id }) },
				createModelData: PinnedItemData.ModelData.announcement
			)
        case .assignment:
//            let assignments = try await CanvasService.shared.loadAndSync(
//                CanvasRequest.getAssignment(id: id, courseId: courseID)
//            ) { cachedAssignments in
//                    guard let assignment = cachedAssignments?.first else { return }
//                    setData(modelData: .assignment(assignment))
//            }
//            guard let assignment = assignments.first else { return }
//            setData(modelData: .assignment(assignment))
			try await loadItemData(
				request: CanvasRequest.getAssignment(id: id, courseId: courseID),
				findItem: { $0?.first },
				createModelData: PinnedItemData.ModelData.assignment
			)
			
		case .quiz:
//			let quizzes = try await CanvasService.shared.loadAndSync(
//				CanvasRequest.getQuiz(id: id, courseId: courseID)
//			) {cachedQuizzes in
//					guard let quiz  = cachedQuizzes?.first else { return }
//					setData(modelData: .quiz(quiz))
//			}
//			guard let quiz = quizzes.first else { return }
//			setData(modelData: .quiz(quiz))
			try await loadItemData(
				request: CanvasRequest.getQuiz(id: id, courseId: courseID),
				findItem: { $0?.first },
				createModelData: PinnedItemData.ModelData.quiz
			)

        case .file:
//            let files = try await CanvasService.shared.loadAndSync(
//                CanvasRequest.getFile(fileId: id)
//            ) { cachedFiles in
//                    guard let file = cachedFiles?.first else { return }
//                    setData(modelData: .file(file))
//            }
//            guard let file = files.first else { return }
//            setData(modelData: .file(file))
			try await loadItemData(
				request: CanvasRequest.getFile(fileId: id),
				findItem: { $0?.first },
				createModelData: PinnedItemData.ModelData.file
			)
        case .grade:
            try await loadItemData(
                request: CanvasRequest.getAssignment(id: id, courseId: courseID),
                findItem: { $0?.first },
                createModelData: PinnedItemData.ModelData.grade
            )
        case .module:
            try await loadItemData(
                request: CanvasRequest.getModuleItems(courseId: courseID, moduleId: id),
                findItem: { $0?.first },
                createModelData: PinnedItemData.ModelData.module
            )
        }

    }
	
	// A generic function for loading data from different types using loadfirstthensync
	private func loadItemData<Request: CacheableAPIRequest>(
			request: Request,
			findItem: @escaping ([Request.PersistedModel]?) -> Request.PersistedModel?,
			createModelData: @escaping (Request.PersistedModel) -> PinnedItemData.ModelData
		) async throws {
			let handler = { [weak self] (items: [Request.PersistedModel]?) in
				guard let self, let foundItem = findItem(items) else { return }
				self.setData(modelData: createModelData(foundItem))
			}
			try await CanvasService.shared.loadFirstThenSync(
				request,
				onCacheReceive: handler,
				onSyncComplete: handler
			)
		}
	
    func setData(course: Course? = nil, modelData: PinnedItemData.ModelData? = nil) {
        if course != nil {
            self.course = course
        }

        if modelData != nil {
            self.modelData = modelData
        }

        if self.course != nil && self.modelData != nil {
            self.data = .init(modelData: self.modelData, course: self.course)
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case courseID
        case type
    }

    init(id: String, courseID: String, type: PinnedItemType, data: PinnedItemData? = nil) {
        self.id = id
        self.courseID = courseID
        self.type = type
        self.data = data
    }

    static func == (lhs: PinnedItem, rhs: PinnedItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct PinnedItemData {
    enum ModelData {
        case announcement(DiscussionTopic)
        case assignment(Assignment)
        case file(File)
		case quiz(Quiz)
        case grade(Assignment)
        case module(ModuleItem)
        // TODO: Add more pinned item types
    }

    let modelData: ModelData
    let course: Course

    init?(modelData: ModelData?, course: Course?) {
        guard let modelData, let course else { return nil }

        self.modelData = modelData
        self.course = course
    }
	
}

