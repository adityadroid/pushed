import SwiftUI

/// List view displaying all received notifications.
struct NotificationListView: View {
    
    @Environment(NotificationViewModel.self) private var viewModel
    
    var body: some View {
        List {
            ForEach(viewModel.groupedNotifications.keys.sorted().reversed(), id: \.self) { date in
                Section {
                    ForEach(viewModel.groupedNotifications[date] ?? []) { notification in
                        NavigationLink(value: notification) {
                            NotificationRow(notification: notification)
                        }
                    }
                    .onDelete { indexSet in
                        deleteNotifications(at: indexSet, for: date)
                    }
                } header: {
                    Text(formatSectionDate(date))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.refreshNotifications()
        }
    }
    
    private func formatSectionDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
    }
    
    private func deleteNotifications(at offsets: IndexSet, for date: Date) {
        guard let notifications = viewModel.groupedNotifications[date] else { return }
        
        for index in offsets {
            let notification = notifications[index]
            viewModel.deleteNotification(notification)
        }
    }
}

// MARK: - Notification Row

struct NotificationRow: View {
    
    let notification: PushedNotification
    
    var body: some View {
        HStack(spacing: 12) {
            // App icon or category icon
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: notification.category.iconName)
                    .font(.system(size: 16))
                    .foregroundStyle(accentColor)
            }
            
            // Notification content
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(notification.appName ?? notification.packageName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(notification.formattedTimestamp)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                
                Text(notification.title)
                    .font(.footnote)
                    .bold()
                    .lineLimit(1)
                
                if let body = notification.body {
                    Text(body)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
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
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NotificationListView()
            .environment(NotificationViewModel.preview)
    }
}
