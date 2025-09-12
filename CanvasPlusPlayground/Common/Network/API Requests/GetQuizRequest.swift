//
//  GetQuizRequest.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 9/11/25.
//


//
//  GetQuizRequest.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 9/4/25.
//


import Foundation

struct GetQuizRequest: CacheableAPIRequest {
	typealias Subject = QuizAPI

	let quizId: String
	let courseId: String

	var path: String { "courses/\(courseId)/quizzes/\(quizId)" }
	var queryParameters: [QueryParameter] {
		[]
	}

	init(
		quizId: String,
		courseId: String
	) {
		self.quizId = quizId
		self.courseId = courseId
	}

	var requestId: String { quizId }
	var requestIdKey: ParentKeyPath<Quiz, String> { .createReadable(\.id) }
	var idPredicate: Predicate<Quiz> {
		#Predicate<Quiz> { quiz in
			quiz.id == requestId
		}
	}
	var customPredicate: Predicate<Quiz> {
		.true
	}
}