@testable import CanvasPlusPlayground
import Testing

@MainActor
struct CoursePeoplePreviewTests {
    @Test func loadsInstructorBeyondFirstSixtyUsers() async throws {
        let fixtures = SandboxData.dummyUsers(forCourseID: "12345")
        let student = try #require(fixtures.first { !$0.enrollmentRoles.contains(.teacher) })
        let teacher = try #require(fixtures.first { $0.enrollmentRoles.contains(.teacher) })
        let pages = [Array(repeating: student, count: 60), [teacher], []]
        var calls = 0
        var loaded: [User] = []
        try await CoursePeoplePreview.loadPages {
            let page = pages[calls]
            calls += 1
            loaded.append(contentsOf: page)
            return !page.isEmpty
        }
        #expect(calls == 3)
        #expect(CoursePreviewSelection.people(loaded).first?.id == teacher.id)
    }

    @Test func emptyPageTerminatesImmediately() async throws {
        var calls = 0
        try await CoursePeoplePreview.loadPages {
            calls += 1
            return false
        }
        #expect(calls == 1)
    }

    @Test func fetchErrorStopsPagination() async {
        var calls = 0
        do {
            try await CoursePeoplePreview.loadPages {
                calls += 1
                throw FetchFailure()
            }
            Issue.record("Expected fetch failure")
        } catch is FetchFailure {
            #expect(calls == 1)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func cancellationStopsBeforeNextFetch() async {
        var calls = 0
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await CoursePeoplePreview.loadPages {
                calls += 1
                return true
            }
        }
        do {
            try await task.value
            Issue.record("Expected cancellation")
        } catch is CancellationError {
            #expect(calls == 0)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}

private struct FetchFailure: Error {}
