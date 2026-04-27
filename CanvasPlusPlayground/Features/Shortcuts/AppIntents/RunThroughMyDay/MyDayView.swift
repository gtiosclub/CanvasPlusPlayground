//
//  MyDayView.swift
//  CanvasPlusPlayground
//
//  Created by Steven Liu on 4/26/26.
//

//  MyDayView.swift
//  CanvasPlusPlayground

import SwiftUI

struct MyDayView: View {
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: Page Header
                VStack(alignment: .leading, spacing: 2) {
                    Text(Date.now, format: .dateTime.weekday(.wide).month(.wide).day())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("My Day")
                        .font(.largeTitle.weight(.semibold))
                }
                .padding(.bottom, 4)

                // MARK: Classes
                SectionHeader(title: "Classes", systemImage: "book.pages", badge: "1")

                VStack(spacing: 10) {
                    ClassRow(
                        course: "PSYC-1101",
                        time: "9:30 – 10:45am",
                        location: "IC 211"
                    )
                }

                // MARK: Todos
                SectionHeader(title: "Todos", systemImage: "checklist", badge: "1 due soon", badgeColor: .red)

                VStack(spacing: 10) {
                    TodoRow(
                        title: "Horror 😱",
                        assignment: "HW 12",
                        due: "11:59pm",
                        isUrgent: true
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let title: String
    let systemImage: String
    var badge: String? = nil
    var badgeColor: Color = .blue

    var body: some View {
        HStack(spacing: 6) {
            Label(title, systemImage: systemImage)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            Spacer()

            if let badge {
                Text(badge)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(badgeColor.opacity(0.15), in: Capsule())
                    .foregroundStyle(badgeColor)
            }
        }
    }
}

// MARK: - Class Row

private struct ClassRow: View {
    let course: String
    let time: String
    let location: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ViewThatFits(in: .horizontal) {
                // Attempt 1: everything on one line
                HStack(spacing: 10) {
                    courseTag
                    timeLabel
                    Spacer(minLength: 4)
                    locationLabel
                }

                // Attempt 2: location wraps to its own line
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 10) {
                        courseTag
                        timeLabel
                        Spacer(minLength: 0)
                    }
                    locationLabel
                        .padding(.leading, 2)
                }
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(.blue)
                .frame(width: 3)
                .padding(.vertical, 8)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.separator, lineWidth: 0.5)
        }
    }

    private var courseTag: some View {
        Text(course)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.blue)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.blue.opacity(0.12), in: Capsule())
    }

    private var timeLabel: some View {
        Text(time)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize()
    }

    private var locationLabel: some View {
        Label(location, systemImage: "mappin.and.ellipse")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

// MARK: - Todo Row

private struct TodoRow: View {
    let title: String
    let assignment: String
    let due: String
    var isUrgent: Bool = false
    @State private var isChecked = false

    var accentColor: Color { isUrgent ? .red : .gray }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(duration: 0.25)) { isChecked.toggle() }
            } label: {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(isChecked ? .green : .secondary)
            }
            .buttonStyle(.plain)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.gray.opacity(0.12), in: Capsule())
                .layoutPriority(2)

            Text(assignment)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .layoutPriority(1)

            Spacer(minLength: 4)

            Label(due, systemImage: "clock.badge.exclamationmark")
                .font(.caption.weight(isUrgent ? .semibold : .regular))
                .foregroundStyle(isUrgent ? accentColor : .secondary)
                .lineLimit(1)
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(accentColor)
                .frame(width: 3)
                .padding(.vertical, 8)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.separator, lineWidth: 0.5)
        }
        .opacity(isChecked ? 0.45 : 1)
    }
}

#Preview {
    MyDayView()
        .preferredColorScheme(.light)
}
