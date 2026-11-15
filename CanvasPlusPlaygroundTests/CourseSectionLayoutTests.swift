@testable import CanvasPlusPlayground
import Foundation
import Testing

struct CourseSectionLayoutTests {
    @Test func defaultsForNewCourse() {
        #expect(CourseSectionLayout().pages == [.assignments, .announcements, .calendar])
    }

    @Test func addIsUniqueAndAppends() {
        var layout = CourseSectionLayout()
        layout.add(.home)
        layout.add(.assignments)
        #expect(layout.pages == [.assignments, .announcements, .calendar, .home])
    }

    @Test func removeAllowsEverySection() {
        var layout = CourseSectionLayout()
        layout.remove(at: IndexSet([0, 1, 2, 99]))
        #expect(layout.pages.isEmpty)
    }

    @Test func movePreservesOrderAndIgnoresInvalidOffsets() {
        var layout = CourseSectionLayout()
        layout.move(from: IndexSet(integer: 0), to: 3)
        #expect(layout.pages == [.announcements, .calendar, .assignments])
        layout.move(from: IndexSet([0, 2]), to: 1)
        #expect(layout.pages == [.announcements, .assignments, .calendar])
        let before = layout
        layout.move(from: IndexSet(integer: 99), to: 0)
        layout.move(from: IndexSet(integer: 0), to: -1)
        #expect(layout == before)
    }

    @Test func resetRestoresDefaultOrder() {
        var layout = CourseSectionLayout()
        layout.remove(at: IndexSet(integer: 0))
        layout.add(.home)
        layout.reset()
        #expect(layout.pages == CourseSectionLayout.defaultPages)
    }

    @Test func roundTripPreservesOrderAndEmptyList() {
        var layout = CourseSectionLayout()
        layout.add(.home)
        layout.move(from: IndexSet(integer: 3), to: 0)
        #expect(CourseSectionLayout(data: layout.encoded()) == layout)
        layout.remove(at: IndexSet(integersIn: 0..<4))
        #expect(CourseSectionLayout(data: layout.encoded()).pages.isEmpty)
    }

    @Test func unknownAndDuplicateRawValuesAreTolerated() {
        let data = Data(#"["home","future","home","pages","assignments"]"#.utf8)
        #expect(CourseSectionLayout(data: data).pages == [.home, .pages, .assignments])
        #expect(CourseSectionLayout(data: Data(#"["future"]"#.utf8)).pages.isEmpty)
    }

    @Test(arguments: ["broken", "{}", #"["home",3]"#, "null"])
    func corruptDataUsesDefaults(_ raw: String) {
        #expect(CourseSectionLayout(data: Data(raw.utf8)).pages == CourseSectionLayout.defaultPages)
    }

    @Test func unavailablePagesAreFilteredWithoutMutation() {
        let layout = CourseSectionLayout()
        #expect(layout.visiblePages(available: [.calendar], tabsLoaded: true) == [.calendar])
        #expect(layout.pages == CourseSectionLayout.defaultPages)
    }

    @Test func emptyTabsKeepStoredPagesVisible() {
        let layout = CourseSectionLayout()
        #expect(layout.visiblePages(available: [], tabsLoaded: false) == layout.pages)
        #expect(layout.visiblePages(available: [], tabsLoaded: true).isEmpty)
    }

    @Test @MainActor func perCourseIsolationAndPersistentRoundTrip() throws {
        let suite = "CourseSectionLayoutTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let first = CourseSectionStore(courseID: "12345", defaults: defaults)
        let second = CourseSectionStore(courseID: "67890", defaults: defaults)
        first.layout.add(.home)
        #expect(second.layout.pages == CourseSectionLayout.defaultPages)
        let reopened = CourseSectionStore(courseID: "12345", defaults: defaults)
        #expect(reopened.layout == first.layout)
        let key = "com.canvasPlus.courseOverviewSections.v1.12345"
        let before = defaults.data(forKey: key)
        _ = reopened.layout.visiblePages(available: [.calendar], tabsLoaded: true)
        #expect(defaults.data(forKey: key) == before)
        #expect(defaults.data(forKey: "com.canvasPlus.courseOverviewSections.v1.67890") == nil)
    }
}
