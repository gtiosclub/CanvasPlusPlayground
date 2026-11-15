import Foundation

@Observable
@MainActor
final class CourseSectionStore {
    private let defaults: UserDefaults
    private let key: String

    var layout: CourseSectionLayout {
        didSet {
            if let data = layout.encoded() { defaults.set(data, forKey: key) }
        }
    }

    /// - Parameters:
    ///   - courseID: The raw Canvas course identifier.
    ///   - defaults: Preference storage; inject an isolated suite in tests.
    init(courseID: String, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        key = "com.canvasPlus.courseOverviewSections.v1.\(courseID)"
        layout = CourseSectionLayout(data: defaults.data(forKey: key))
    }
}
