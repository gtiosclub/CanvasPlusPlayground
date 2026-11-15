import SwiftUI

struct CourseSectionRow: View {
    @Environment(NavigationModel.self) private var navigationModel

    let page: NavigationModel.CoursePage
    let course: Course
    @Binding var expandedSections: Set<NavigationModel.CoursePage>

    private var isExpanded: Bool { expandedSections.contains(page) }

    var body: some View {
        switch page {
        case .assignments:
            expandable { AssignmentOverviewView(course: course) }
        case .announcements:
            expandable { AnnouncementOverviewView(course: course) }
        case .calendar:
            expandable { CalendarOverviewView(course: course) }
        case .home, .syllabus, .files, .grades, .people, .groups, .quizzes, .modules, .pages:
            plainRow
        }
    }

    private var plainRow: some View {
        Button {
            navigationModel.push(.coursePage(page, course))
        } label: {
            header(expandable: false)
        }
        .buttonStyle(.plain)
    }

    private func expandable<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(duration: 0.3, bounce: 0.15)) {
                    if isExpanded {
                        expandedSections.remove(page)
                    } else {
                        expandedSections.insert(page)
                    }
                }
            } label: {
                header(expandable: true)
            }
            .buttonStyle(.plain)
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")

            if isExpanded {
                content()
                    .transition(.opacity)
            }
        }
        .clipped()
    }

    private func header(expandable: Bool) -> some View {
        HStack {
            Text(page.title)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 0)
            Image(systemName: expandable ? "chevron.down" : "chevron.right")
                .font(.body.weight(.medium))
                .foregroundStyle(.secondary)
                .rotationEffect(.degrees(expandable && !isExpanded ? -90 : 0))
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 12)
    }
}
