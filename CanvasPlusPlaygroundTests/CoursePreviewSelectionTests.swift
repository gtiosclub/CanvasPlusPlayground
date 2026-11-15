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
