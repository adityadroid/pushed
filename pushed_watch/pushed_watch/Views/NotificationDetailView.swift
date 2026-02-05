import SwiftUI

/// Detailed view of a single notification.
struct NotificationDetailView: View {

  let notification: PushedNotification

  @Environment(NotificationViewModel.self) private var viewModel
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        // Header with app info
        headerSection

        Divider()

        // Notification content
        contentSection

        // Actions if available
        if !notification.actions.isEmpty {
          Divider()
          actionsSection
        }

        // Metadata
        Divider()
        metadataSection
      }
      .padding()
    }
    .navigationTitle("Details")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button("Dismiss", systemImage: "bell.slash") {
          viewModel.dismissNotification(notification)
          dismiss()
        }
        .labelStyle(.iconOnly)
      }
    }
  }

  // MARK: - Header Section

  private var headerSection: some View {
    HStack(spacing: 12) {
      // App icon
      ZStack {
        Circle()
          .fill(categoryColor.opacity(0.2))
          .frame(width: 44, height: 44)

        Image(systemName: notification.category.iconName)
          .font(.system(size: 20))
          .foregroundStyle(categoryColor)
      }

      VStack(alignment: .leading, spacing: 2) {
        Text(notification.appName ?? notification.packageName)
          .font(.footnote)
          .bold()

        Text(notification.timestamp.formatted(date: .abbreviated, time: .shortened))
          .font(.caption2)
          .foregroundStyle(.secondary)
      }

      Spacer()

      // Priority indicator
      if notification.priority >= .high {
        Image(systemName: "exclamationmark.circle.fill")
          .foregroundStyle(.red)
      }
    }
  }

  // MARK: - Content Section

  private var contentSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(notification.title)
        .font(.headline)

      if let body = notification.body {
        Text(body)
          .font(.body)
          .foregroundStyle(.secondary)
      }

      if let subText = notification.subText {
        Text(subText)
          .font(.caption)
          .foregroundStyle(.tertiary)
      }
    }
  }

  // MARK: - Actions Section

  private var actionsSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Actions")
        .font(.caption)
        .foregroundStyle(.secondary)

      ForEach(notification.actions) { action in
        Button {
          handleAction(action)
        } label: {
          HStack {
            if let iconName = action.icon {
              Image(systemName: iconName)
            }
            Text(action.label)
            Spacer()
            Image(systemName: "chevron.right")
              .font(.caption)
              .foregroundStyle(.tertiary)
          }
        }
        .buttonStyle(.plain)
        .foregroundStyle(action.isDestructive ? .red : .primary)
      }
    }
  }

  // MARK: - Metadata Section

  private var metadataSection: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Details")
        .font(.caption)
        .foregroundStyle(.secondary)

      metadataRow(label: "Package", value: notification.packageName)
      metadataRow(label: "Category", value: notification.category.displayName)
      metadataRow(label: "Priority", value: notification.priority.rawValue.capitalized)

      if notification.isOngoing {
        metadataRow(label: "Type", value: "Ongoing")
      }

      if let groupKey = notification.groupKey {
        metadataRow(label: "Group", value: groupKey)
      }
    }
  }

  private func metadataRow(label: String, value: String) -> some View {
    HStack {
      Text(label)
        .font(.caption2)
        .foregroundStyle(.tertiary)
      Spacer()
      Text(value)
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
  }

  // MARK: - Helpers

  private var categoryColor: Color {
    switch notification.category {
    case .message: .blue
    case .email: .indigo
    case .social: .pink
    case .news: .orange
    case .promo: .green
    case .reminder: .yellow
    case .call: .green
    case .transport: .cyan
    case .alarm: .red
    case .other: .gray
    }
  }

  private func handleAction(_ action: NotificationAction) {
    // In a real implementation, this would send the action back to Android
    viewModel.executeAction(action, for: notification)
  }
}

// MARK: - Preview

#Preview {
  NavigationStack {
    NotificationDetailView(notification: .preview)
      .environment(NotificationViewModel.previewInstance)
  }
}
