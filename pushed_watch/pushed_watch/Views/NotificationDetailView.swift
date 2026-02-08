import SwiftUI

/// Beautiful detailed view of a single notification.
///
/// Features:
/// - Full notification content with scrollable body
/// - Prominent "Clear" button to dismiss the notification
/// - Beautiful visual design with gradient accents
/// - Action buttons if available
/// - Metadata section
struct NotificationDetailView: View {

  let notification: PushedNotification

  @Environment(NotificationViewModel.self) private var viewModel
  @Environment(\.dismiss) private var dismiss

  @State private var isDismissing = false
  @State private var showDismissConfirmation = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        // Header with app info
        headerSection

        // Notification content
        contentSection

        // Actions if available
        if !notification.actions.isEmpty {
          actionsSection
        }

        // Dismiss button - prominent and always visible
        dismissButtonSection

        // Metadata
        metadataSection
      }
      .padding()
    }
    .navigationTitle("Details")
    .navigationBarTitleDisplayMode(.inline)
    .disabled(isDismissing)
  }

  // MARK: - Header Section

  private var headerSection: some View {
    HStack(spacing: 14) {
      // App icon with gradient
      ZStack {
        Circle()
          .fill(
            LinearGradient(
              colors: [
                categoryColor.opacity(0.9),
                categoryColor.opacity(0.5),
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .frame(width: 48, height: 48)

        Image(systemName: notification.category.iconName)
          .font(.system(size: 22, weight: .semibold))
          .foregroundStyle(.white)
      }
      .shadow(color: categoryColor.opacity(0.4), radius: 6, x: 0, y: 3)

      VStack(alignment: .leading, spacing: 4) {
        Text(notification.appName ?? notification.packageName)
          .font(.footnote)
          .fontWeight(.semibold)
          .foregroundStyle(categoryColor)

        Text(notification.timestamp.formatted(date: .abbreviated, time: .shortened))
          .font(.caption2)
          .foregroundStyle(.secondary)
      }

      Spacer()

      // Priority badge
      if notification.priority >= .high {
        priorityBadge
      }
    }
    .padding(.bottom, 8)
  }

  private var priorityBadge: some View {
    HStack(spacing: 4) {
      Image(systemName: "exclamationmark.circle.fill")
        .font(.system(size: 10))
      Text("HIGH")
        .font(.system(size: 9, weight: .bold))
    }
    .foregroundStyle(.white)
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(
      Capsule()
        .fill(
          LinearGradient(
            colors: [.red, .orange],
            startPoint: .leading,
            endPoint: .trailing
          )
        )
    )
  }

  // MARK: - Content Section

  private var contentSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      // Title
      Text(notification.title)
        .font(.headline)
        .fontWeight(.bold)
        .foregroundStyle(.primary)

      // Body
      if let body = notification.body, !body.isEmpty {
        Text(body)
          .font(.body)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }

      // Subtext
      if let subText = notification.subText, !subText.isEmpty {
        Text(subText)
          .font(.caption)
          .foregroundStyle(.tertiary)
          .padding(.top, 4)
      }

      // Sender info for messages
      if let senderName = notification.senderName {
        HStack(spacing: 6) {
          Image(systemName: "person.circle.fill")
            .font(.system(size: 14))
          Text("From: \(senderName)")
            .font(.caption)
        }
        .foregroundStyle(.secondary)
        .padding(.top, 4)
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(white: 0.15))
    )
  }

  // MARK: - Actions Section

  private var actionsSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Quick Actions")
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(.secondary)
        .textCase(.uppercase)

      ForEach(notification.actions) { action in
        Button {
          handleAction(action)
        } label: {
          HStack {
            if let iconName = action.icon {
              Image(systemName: iconName)
            }
            Text(action.label)
              .fontWeight(.medium)
            Spacer()
            Image(systemName: "chevron.right")
              .font(.caption)
              .foregroundStyle(.tertiary)
          }
          .padding()
          .background(
            RoundedRectangle(cornerRadius: 10)
              .fill(Color(white: 0.12))
          )
        }
        .buttonStyle(.plain)
        .foregroundStyle(action.isDestructive ? .red : .primary)
      }
    }
  }

  // MARK: - Dismiss Button Section

  private var dismissButtonSection: some View {
    VStack(spacing: 12) {
      Divider()
        .padding(.vertical, 8)

      Button {
        dismissNotification()
      } label: {
        HStack {
          if isDismissing {
            ProgressView()
              .tint(.white)
          } else {
            Image(systemName: "xmark.circle.fill")
              .font(.system(size: 18))
            Text("Clear Notification")
              .fontWeight(.semibold)
          }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
          LinearGradient(
            colors: [.red.opacity(0.8), .red.opacity(0.6)],
            startPoint: .leading,
            endPoint: .trailing
          )
        )
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
      }
      .buttonStyle(.plain)
      .disabled(isDismissing)

      Text("This will permanently remove the notification")
        .font(.caption2)
        .foregroundStyle(.tertiary)
        .multilineTextAlignment(.center)
    }
  }

  // MARK: - Metadata Section

  private var metadataSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Details")
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(.secondary)
        .textCase(.uppercase)

      VStack(spacing: 6) {
        metadataRow(label: "Package", value: notification.packageName)
        metadataRow(label: "Category", value: notification.category.displayName)
        metadataRow(label: "Priority", value: notification.priority.rawValue.capitalized)

        if notification.isOngoing {
          metadataRow(label: "Type", value: "Ongoing")
        }

        if let groupKey = notification.groupKey {
          metadataRow(label: "Group", value: groupKey)
        }

        if let sourceDevice = notification.sourceDeviceId {
          metadataRow(label: "Source", value: String(sourceDevice.prefix(12)) + "...")
        }
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color(white: 0.1))
      )
    }
    .padding(.top, 8)
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
        .lineLimit(1)
    }
  }

  // MARK: - Helpers

  private var categoryColor: Color {
    if let colorTuple = notification.accentColor {
      return Color(
        red: colorTuple.red,
        green: colorTuple.green,
        blue: colorTuple.blue
      )
    }

    switch notification.category {
    case .message: return .blue
    case .email: return .indigo
    case .social: return .pink
    case .news: return .orange
    case .promo: return .green
    case .reminder: return .yellow
    case .call: return .green
    case .transport: return .cyan
    case .alarm: return .red
    case .other: return .gray
    }
  }

  private func handleAction(_ action: NotificationAction) {
    viewModel.executeAction(action, for: notification)
  }

  private func dismissNotification() {
    isDismissing = true

    Task {
      viewModel.dismissNotification(notification)
      // Small delay for visual feedback
      try? await Task.sleep(nanoseconds: 300_000_000)
      dismiss()
    }
  }
}

// MARK: - Preview

#Preview("Notification Detail") {
  NavigationStack {
    NotificationDetailView(notification: .preview)
      .environment(NotificationViewModel.previewInstance)
  }
}

#Preview("High Priority") {
  NavigationStack {
    NotificationDetailView(
      notification: PushedNotification(
        id: UUID(),
        schemaVersion: "1.0.0",
        timestamp: Date(),
        title: "URGENT: Server Down!",
        body: "The production server is experiencing issues. Please check immediately.",
        packageName: "com.pagerduty.android",
        appName: "PagerDuty",
        category: .alarm,
        priority: .max,
        actions: [
          NotificationAction(
            id: "ack",
            label: "Acknowledge",
            isDestructive: false,
            requiresUnlock: false,
            icon: "checkmark.circle"
          ),
          NotificationAction(
            id: "snooze",
            label: "Snooze",
            isDestructive: false,
            requiresUnlock: false,
            icon: "clock"
          ),
        ],
        groupKey: nil,
        isOngoing: true,
        isSilent: false,
        iconData: nil,
        color: "#E74C3C",
        subText: "Production Environment",
        conversationId: nil,
        senderName: nil,
        sourceDeviceId: "device123",
        createdAt: Date()
      )
    )
    .environment(NotificationViewModel.previewInstance)
  }
}
