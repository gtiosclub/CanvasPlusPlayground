//
//  ProposedActionsView.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/18/26.
//

import SwiftUI

/// The shared approval UI for agent write actions. Each card says exactly what will happen,
/// and nothing runs until the student taps Approve.
struct ProposedActionsView: View {
    let model: ActionApprovalModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Suggested actions", systemImage: "sparkles")
                .font(.headline)
                .fontDesign(.rounded)

            Text("Nothing happens until you approve it.")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(model.items) { item in
                ProposedActionCard(item: item) {
                    Task { await model.approve(item.id) }
                } onDismiss: {
                    model.dismiss(item.id)
                }
            }
        }
    }
}

private struct ProposedActionCard: View {
    let item: ActionApprovalModel.Item
    let onApprove: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.action.systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.action.title)
                    .bold()

                Text(item.action.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                footer
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.thinMaterial)
                .strokeBorder(.ultraThickMaterial)
        }
        .opacity(item.status == .dismissed ? 0.5 : 1)
        .animation(.default, value: item.status)
    }

    @ViewBuilder
    private var footer: some View {
        switch item.status {
        case .pending:
            buttons
        case .running:
            ProgressView()
                .controlSize(.small)
        case .done:
            Label("Done", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .bold()
                .foregroundStyle(.green)
        case .dismissed:
            Text("Dismissed")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .failed(let message):
            VStack(alignment: .leading, spacing: 6) {
                Label(message, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.red)
                buttons
            }
        }
    }

    private var buttons: some View {
        HStack {
            Button("Approve", action: onApprove)
                .buttonStyle(.borderedProminent)

            Button("Not now", action: onDismiss)
                .buttonStyle(.bordered)
        }
        .controlSize(.small)
        .padding(.top, 2)
    }
}
