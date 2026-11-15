import SwiftUI

struct CourseSectionLayout: Equatable {
    typealias Page = NavigationModel.CoursePage

    static let defaultPages: [Page] = [.assignments, .announcements, .calendar]
    private(set) var pages: [Page]

    /// - Parameter data: Stored JSON raw values, or nil for a new course.
    init(data: Data? = nil) {
        guard let data, let values = try? JSONDecoder().decode([String].self, from: data) else {
            pages = Self.defaultPages
            return
        }
        var seen = Set<Page>()
        pages = values.compactMap(Page.init(rawValue:)).filter { seen.insert($0).inserted }
    }

    /// - Returns: JSON raw values in the user's chosen order.
    func encoded() -> Data? {
        try? JSONEncoder().encode(pages.map(\.rawValue))
    }

    /// - Parameter page: The page to append if it is not already present.
    mutating func add(_ page: Page) {
        if !pages.contains(page) { pages.append(page) }
    }

    /// - Parameter offsets: Positions in the stored list to remove; invalid positions are ignored.
    mutating func remove(at offsets: IndexSet) {
        pages.remove(atOffsets: offsets.intersection(IndexSet(integersIn: pages.indices)))
    }

    /// - Parameters:
    ///   - offsets: Positions in the stored list to move.
    ///   - destination: Insertion offset before removal, as supplied by List.onMove.
    mutating func move(from offsets: IndexSet, to destination: Int) {
        guard (0...pages.count).contains(destination), offsets.allSatisfy({ pages.indices.contains($0) }) else { return }
        pages.move(fromOffsets: offsets, toOffset: destination)
    }

    mutating func reset() {
        pages = Self.defaultPages
    }

    /// - Parameters:
    ///   - available: Pages returned by CoursePage.available(for:).
    ///   - tabsLoaded: Whether the course has any loaded tabs.
    /// - Returns: Visible pages in stored order, without changing the stored list.
    func visiblePages(available: [Page], tabsLoaded: Bool) -> [Page] {
        tabsLoaded ? pages.filter(Set(available).contains) : pages
    }
}
