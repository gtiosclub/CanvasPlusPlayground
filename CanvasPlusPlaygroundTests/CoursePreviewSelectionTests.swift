@testable import CanvasPlusPlayground
import Foundation
import Testing

struct CoursePreviewSelectionTests {
    @Test func syllabusHandlesNilEmptyHTMLAndBlocks() {
        #expect(CoursePreviewSelection.syllabusExcerpt(nil).isEmpty)
        #expect(CoursePreviewSelection.syllabusExcerpt("  ").isEmpty)
        #expect(CoursePreviewSelection.syllabusExcerpt("<p>&nbsp;</p>").isEmpty)
        #expect(CoursePreviewSelection.syllabusExcerpt("<h2>Welcome!</h2><p>A &amp; B<br>C</p>") == "Welcome! A & B C")
    }

    @Test func syllabusCapsLongUnicodeText() {
        let result = CoursePreviewSelection.syllabusExcerpt(String(repeating: "👩🏽‍💻", count: 400))
        #expect(result.count == 280)
        #expect(result.hasSuffix("…"))
    }

    @Test func pagesPreferFrontThenRecentAndCap() {
        let pages = (1...5).map { page($0) }
        pages[0].frontPage = true
        #expect(CoursePreviewSelection.pages(pages).map(\.id) == ["1", "5", "4"])
    }

    @Test func pagesWithoutFrontSortNilDatesAndTies() {
        let pages = (1...4).map { page($0) }
        pages[0].updatedAt = nil
        pages[1].updatedAt = pages[2].updatedAt
        #expect(CoursePreviewSelection.pages(pages).map(\.id) == ["4", "2", "3"])
        #expect(CoursePreviewSelection.pages([]).isEmpty)
        #expect(CoursePreviewSelection.pages([pages[0]]).count == 1)
    }

    @Test func gradesHandleMissingAndNonfiniteScores() {
        #expect(CoursePreviewSelection.gradeSummary(score: "87", grade: "B+") == "87% · B+")
        #expect(CoursePreviewSelection.gradeSummary(score: "--", grade: "A") == "A")
        #expect(CoursePreviewSelection.gradeSummary(score: "92", grade: "--") == "92%")
        #expect(CoursePreviewSelection.gradeSummary(score: "nan", grade: "--") == "No grade available")
        #expect(CoursePreviewSelection.gradeSummary(score: "inf", grade: "") == "No grade available")
        #expect(CoursePreviewSelection.gradeSummary(score: "--", grade: "--") == "No grade available")
    }

    @Test func gradeCardOnlyHidesForVisibleGradesSection() {
        #expect(CoursePreviewSelection.showsGradeCard(pages: []))
        #expect(CoursePreviewSelection.showsGradeCard(pages: [.assignments]))
        #expect(!CoursePreviewSelection.showsGradeCard(pages: [.grades]))
    }

    @Test func modulesPreferStartedThenUnlockedThenIncompleteThenFirst() throws {
        let modules = SandboxData.dummyModules(forCourseID: "67890")
        let blocks = modules.map { ModulesViewModel.ModuleBlock(module: $0, items: []) }.reversed()
        modules[0].state = .unlocked
        modules[1].state = .started
        #expect(CoursePreviewSelection.currentModule(Array(blocks))?.module.id == modules[1].id)
        modules[1].state = .completed
        modules[0].state = nil
        #expect(CoursePreviewSelection.currentModule(Array(blocks))?.module.id == modules[0].id)
        modules[0].state = .completed
        #expect(CoursePreviewSelection.currentModule(Array(blocks))?.module.id == modules[2].id)
        modules[2].state = .completed
        #expect(CoursePreviewSelection.currentModule(Array(blocks))?.module.id == modules[0].id)
        #expect(CoursePreviewSelection.currentModule([]) == nil)
        let block = try #require(CoursePreviewSelection.currentModule(Array(blocks)))
        #expect(CoursePreviewSelection.moduleItems(block).isEmpty)
        #expect(block.module.itemsCount == 3)
    }

    @Test func moduleItemsUsePositionAndCap() throws {
        let module = try #require(SandboxData.dummyModules(forCourseID: "67890").first)
        let items = SandboxData.dummyModuleItems(forCourseID: "67890")
        let block = ModulesViewModel.ModuleBlock(module: module, items: Array(items.reversed()))
        let selected = CoursePreviewSelection.moduleItems(block)
        #expect(selected.count == 3)
        #expect(selected.map(\.position) == items.map(\.position).sorted().prefix(3).map { $0 })
    }

    @Test func filesUseDateFallbackStableTiesAndCap() {
        let files = SandboxData.dummyFiles(forCourseID: "12345")
        for file in files { file.updatedAt = nil; file.createdAt = nil }
        files[0].createdAt = Date(timeIntervalSince1970: 100)
        files[1].updatedAt = Date(timeIntervalSince1970: 200)
        files[2].updatedAt = files[1].updatedAt
        #expect(CoursePreviewSelection.files(files).map(\.id) == [files[1].id, files[2].id, files[0].id])
        #expect(CoursePreviewSelection.files([]).isEmpty)
    }

    @Test func quizzesKeepOverdueFirstAndUndatedLast() {
        let quizzes = SandboxData.dummyQuizzes(forCourseID: "12345")
        quizzes[0].dueAt = nil
        quizzes[1].dueAt = Date(timeIntervalSince1970: 100)
        quizzes[2].dueAt = Date(timeIntervalSince1970: -100)
        #expect(CoursePreviewSelection.quizzes(quizzes).map(\.id) == [quizzes[2].id, quizzes[1].id, quizzes[0].id])
        quizzes[2].dueAt = quizzes[1].dueAt
        #expect(CoursePreviewSelection.quizzes(quizzes).first?.id == quizzes[1].id)
        #expect(CoursePreviewSelection.quizzes([]).isEmpty)
        #expect(CoursePreviewSelection.quizzes(quizzes + SandboxData.dummyQuizzes(forCourseID: "67890")).count == 3)
    }

    @Test func peoplePutTeachersFirstAndCap() throws {
        let users = SandboxData.dummyUsers(forCourseID: "12345")
        let selected = CoursePreviewSelection.people(Array(users.reversed()))
        #expect(selected.count == 5)
        #expect(try #require(selected.first).enrollmentRoles.contains(.teacher))
        let others = users.filter { !$0.enrollmentRoles.contains(.teacher) }
        #expect(CoursePreviewSelection.people(others).map(\.sortableName) == others.map(\.sortableName).sorted().prefix(5).map { $0 })
        #expect(CoursePreviewSelection.people([]).isEmpty)
    }

    @Test func groupsKeepDisplayedOrderAndCap() {
        let groups = SandboxData.dummyGroups(forCourseID: "12345") + SandboxData.dummyGroups(forCourseID: "67890")
        let displayed = Array(groups.reversed())
        #expect(CoursePreviewSelection.groups(displayed).map(\.id) == displayed.prefix(3).map(\.id))
        #expect(CoursePreviewSelection.groups([]).isEmpty)
    }

    private func page(_ id: Int) -> Page {
        Page(pageAPI: PageAPI(
            page_id: id,
            url: "page-\(id)",
            title: "Page \(id)",
            created_at: nil,
            updated_at: Date(timeIntervalSince1970: Double(id)),
            body: nil,
            published: true,
            publish_at: nil,
            front_page: false
        ))
    }
}
