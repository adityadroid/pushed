import WidgetKit
import SwiftUI

/// Complication provider for showing notification count on watch face.
struct NotificationComplicationProvider: TimelineProvider {
    
    typealias Entry = NotificationEntry
    
    // MARK: - TimelineProvider
    
    func placeholder(in context: Context) -> NotificationEntry {
        NotificationEntry(date: Date(), count: 0, latestTitle: nil)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (NotificationEntry) -> Void) {
        // Provide sample data for preview
        let entry = NotificationEntry(
            date: Date(),
            count: 3,
            latestTitle: "New message from John"
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<NotificationEntry>) -> Void) {
        // In a real implementation, fetch from NotificationStore
        let currentDate = Date()
        
        // TODO: Fetch actual notification count and latest notification
        let entry = NotificationEntry(
            date: currentDate,
            count: 0,
            latestTitle: nil
        )
        
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate) ?? currentDate
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
}

/// Timeline entry for notification complication.
struct NotificationEntry: TimelineEntry {
    let date: Date
    let count: Int
    let latestTitle: String?
}

/// Complication views for different families.
struct NotificationComplicationView: View {
    
    @Environment(\.widgetFamily) private var family
    
    let entry: NotificationEntry
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryCorner:
            cornerView
        case .accessoryInline:
            inlineView
        case .accessoryRectangular:
            rectangularView
        @unknown default:
            circularView
        }
    }
    
    // MARK: - Circular
    
    private var circularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            
            VStack(spacing: 0) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 12))
                
                Text("\(entry.count)")
                    .font(.system(size: 16, weight: .bold))
            }
        }
    }
    
    // MARK: - Corner
    
    private var cornerView: some View {
        ZStack {
            Image(systemName: "bell.fill")
                .font(.title3)
            
            if entry.count > 0 {
                Text("\(entry.count)")
                    .font(.caption2)
                    .padding(2)
                    .background(.red)
                    .clipShape(.circle)
                    .offset(x: 8, y: -8)
            }
        }
    }
    
    // MARK: - Inline
    
    private var inlineView: some View {
        HStack {
            Image(systemName: "bell.fill")
            
            if entry.count > 0 {
                Text("\(entry.count) notifications")
            } else {
                Text("No notifications")
            }
        }
    }
    
    // MARK: - Rectangular
    
    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: "bell.fill")
                Text("Pushed")
                    .bold()
                Spacer()
                Text("\(entry.count)")
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
            
            if let title = entry.latestTitle {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            } else {
                Text("No new notifications")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

/// Widget configuration for the complication.
struct NotificationWidget: Widget {
    
    let kind = "NotificationWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NotificationComplicationProvider()) { entry in
            NotificationComplicationView(entry: entry)
        }
        .configurationDisplayName("Notifications")
        .description("Shows your notification count from Android.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryInline,
            .accessoryRectangular
        ])
    }
}

// MARK: - Preview

#Preview(as: .accessoryCircular) {
    NotificationWidget()
} timeline: {
    NotificationEntry(date: Date(), count: 5, latestTitle: "New message")
    NotificationEntry(date: Date(), count: 0, latestTitle: nil)
}
