import SwiftUI

/// Beautiful list view displaying all received notifications.
///
/// Features:
/// - Grouped by date with elegant section headers
/// - Beautiful notification previews with app icons and colors
/// - Swipe to delete functionality
/// - Pull to refresh
/// - Empty state with animation
struct NotificationListView: View {

  @Environment(NotificationViewModel.self) private var viewModel

  var body: some View {
    List {
      ForEach(sortedDates, id: \.self) { date in
        Section {
          ForEach(viewModel.groupedNotifications[date] ?? []) { notification in
            NavigationLink(value: notification) {
              NotificationRow(notification: notification)
            }
            .listRowBackground(
              RoundedRectangle(cornerRadius: 12)
                .fill(Color(white: 0.12))
                .padding(.vertical, 2)
            )
          }
          .onDelete { indexSet in
            deleteNotifications(at: indexSet, for: date)
          }
        } header: {
          SectionHeader(date: date)
        }
      }
    }
    .listStyle(.plain)
    .refreshable {
      await viewModel.refreshNotifications()
    }
  }

  private var sortedDates: [Date] {
    viewModel.groupedNotifications.keys.sorted().reversed()
  }

  private func deleteNotifications(at offsets: IndexSet, for date: Date) {
    guard let notifications = viewModel.groupedNotifications[date] else { return }

    for index in offsets {
      let notification = notifications[index]
      viewModel.deleteNotification(notification)
    }
  }
}

// MARK: - Section Header

private struct SectionHeader: View {
  let date: Date

  var body: some View {
    HStack {
      Text(formatDate(date))
        .font(.caption2)
        .fontWeight(.semibold)
        .foregroundStyle(.secondary)
        .textCase(.uppercase)
        .tracking(0.5)

      Spacer()
    }
    .padding(.vertical, 4)
  }

  private func formatDate(_ date: Date) -> String {
    if Calendar.current.isDateInToday(date) {
      return "Today"
    } else if Calendar.current.isDateInYesterday(date) {
      return "Yesterday"
    } else {
      return date.formatted(date: .abbreviated, time: .omitted)
    }
  }
}

// MARK: - Notification Row

struct NotificationRow: View {

  let notification: PushedNotification

  @State private var isPressed = false

  var body: some View {
    HStack(spacing: 12) {
      // App icon with gradient background
      appIconView

      // Notification content
      VStack(alignment: .leading, spacing: 4) {
        // Top row: App name + Time
        HStack(alignment: .center) {
          Text(notification.appName ?? formatPackageName(notification.packageName))
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(accentColor)
            .lineLimit(1)

          Spacer()

          // Priority indicator
          if notification.priority >= .high {
            Image(systemName: "exclamationmark.circle.fill")
              .font(.system(size: 10))
              .foregroundStyle(.red)
          }

          Text(notification.formattedTimestamp)
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }

        // Title
        Text(notification.title)
          .font(.footnote)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)
          .lineLimit(1)

        // Body preview
        if let body = notification.body, !body.isEmpty {
          Text(body)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }

        // Subtext or sender info
        if let subText = notification.subText {
          Text(subText)
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .lineLimit(1)
        } else if let senderName = notification.senderName {
          HStack(spacing: 4) {
            Image(systemName: "person.fill")
              .font(.system(size: 8))
            Text(senderName)
          }
          .font(.caption2)
          .foregroundStyle(.tertiary)
        }
      }
    }
    .padding(.vertical, 6)
    .contentShape(Rectangle())
  }

  // MARK: - App Icon View

  @ViewBuilder
  private var appIconView: some View {
    ZStack {
      // Gradient background circle
      Circle()
        .fill(
          LinearGradient(
            colors: [
              accentColor.opacity(0.8),
              accentColor.opacity(0.4),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .frame(width: 40, height: 40)

      // Inner icon
      Image(systemName: notification.category.iconName)
        .font(.system(size: 18, weight: .medium))
        .foregroundStyle(.white)
    }
    .shadow(color: accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
  }

  // MARK: - Helpers

  private var accentColor: Color {
    if let colorTuple = notification.accentColor {
      return Color(
        red: colorTuple.red,
        green: colorTuple.green,
        blue: colorTuple.blue
      )
    }
    return categoryColor
  }

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

  private func formatPackageName(_ packageName: String) -> String {
    // Extract the last component of the package name
    let components = packageName.split(separator: ".")
    if let lastComponent = components.last {
      return String(lastComponent).capitalized
    }
    return packageName
  }
}

// MARK: - Preview

#Preview("Notification List") {
  NavigationStack {
    NotificationListView()
      .environment(NotificationViewModel.previewInstanceWithMultipleNotifications)
  }
}

#Preview("Single Row") {
  List {
    NotificationRow(notification: .preview)
  }
  .listStyle(.plain)
}
