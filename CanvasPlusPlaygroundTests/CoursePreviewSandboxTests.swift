@testable import CanvasPlusPlayground
import Testing

struct CoursePreviewSandboxTests {
    @Test(arguments: ["12345", "67890"])
    func everyPreviewHasSandboxContent(_ courseID: String) throws {
        let course = try #require(SandboxData.dummyCourses.first { $0.id == courseID })
        #expect(!CoursePreviewSelection.syllabusExcerpt(course.syllabusBody).isEmpty)
        #expect(!CoursePreviewSelection.pages(SandboxData.dummyPages(forCourseID: courseID)).isEmpty)
        let grades = try #require(SandboxData.dummyEnrollment(forCourseID: courseID).grades)
        #expect(grades.current_score != nil)
        #expect(grades.current_grade != nil)
        #expect(CoursePreviewSelection.gradeSummary(
            score: grades.current_score?.description ?? "--",
            grade: grades.current_grade ?? "--"
        ) != "No grade available")
        let root = SandboxData.dummyRootFolder(forCourseID: courseID)
        let files = SandboxData.dummyFiles(forCourseID: courseID).filter { $0.folderId == Int(root.id) }
        #expect(!CoursePreviewSelection.files(files).isEmpty)
        #expect(!CoursePreviewSelection.quizzes(SandboxData.dummyQuizzes(forCourseID: courseID)).isEmpty)
        #expect(!CoursePreviewSelection.people(SandboxData.dummyUsers(forCourseID: courseID)).isEmpty)
        #expect(!CoursePreviewSelection.groups(SandboxData.dummyGroups(forCourseID: courseID)).isEmpty)
        let items = SandboxData.dummyModuleItems(forCourseID: courseID)
        let blocks = SandboxData.dummyModules(forCourseID: courseID).map { module in
            ModulesViewModel.ModuleBlock(module: module, items: items.filter { String($0.moduleID) == module.id })
        }
        let selected = try #require(CoursePreviewSelection.currentModule(blocks))
        #expect(!selected.module.name.isEmpty)
        #expect(!CoursePreviewSelection.moduleItems(selected).isEmpty)
        if courseID == "67890" {
            #expect(selected.module.state == .started)
            #expect(selected.module.name == "SwiftUI Fundamentals")
        }
        #expect(Set(NavigationModel.CoursePage.available(for: course)) == Set(NavigationModel.CoursePage.allCases))
    }
}
