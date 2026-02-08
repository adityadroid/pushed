import SwiftUI

/// Main content view that displays the notification list.
///
/// Features:
/// - Beautiful loading state with animation
/// - Engaging empty state with helpful message
/// - Notification list with navigation
/// - Error handling with alerts
struct ContentView: View {

  @Environment(NotificationViewModel.self) private var viewModel
  @State private var showClearConfirmation = false

  var body: some View {
    NavigationStack {
      Group {
        if viewModel.isLoading {
          LoadingView()
        } else if viewModel.notifications.isEmpty {
          EmptyStateView(onRefresh: refreshNotifications)
        } else {
          NotificationListView()
        }
      }
      .navigationTitle("Pushed")
      .navigationDestination(for: PushedNotification.self) { notification in
        NotificationDetailView(notification: notification)
      }
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            refreshNotifications()
          } label: {
            Label("Refresh", systemImage: "arrow.clockwise")
          }
        }

        if !viewModel.notifications.isEmpty {
          ToolbarItem(placement: .topBarTrailing) {
            Button(role: .destructive) {
              showClearConfirmation = true
            } label: {
              Label("Clear All", systemImage: "trash")
            }
          }
        }
      }

    }
    .confirmationDialog(
      "Clear All Notifications?",
      isPresented: $showClearConfirmation,
      titleVisibility: .visible
    ) {
      Button("Clear All", role: .destructive) {
        viewModel.clearAll()
      }
      Button("Cancel", role: .cancel) {}
    }
    .alert(
      "Error",
      isPresented: Binding(
        get: { viewModel.errorMessage != nil },
        set: { isPresented in
          if !isPresented {
            viewModel.errorMessage = nil
          }
        }
      )
    ) {
      Button("OK") {
        viewModel.errorMessage = nil
      }
    } message: {
      Text(viewModel.errorMessage ?? "")
    }
    .onAppear {
      // Refresh notifications when view appears
      Task {
        await viewModel.refreshNotifications()
      }
    }
  }

  private func refreshNotifications() {
    Task {
      await viewModel.refreshNotifications()
    }
  }
}

// MARK: - Loading View

private struct LoadingView: View {

  @State private var isAnimating = false

  var body: some View {
    VStack(spacing: 20) {
      // Animated bell icon
      ZStack {
        Circle()
          .fill(
            LinearGradient(
              colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .frame(width: 80, height: 80)

        Image(systemName: "bell.badge.fill")
          .font(.system(size: 36))
          .foregroundStyle(.blue)
          .rotationEffect(.degrees(isAnimating ? 10 : -10))
          .animation(
            .easeInOut(duration: 0.5)
              .repeatForever(autoreverses: true),
            value: isAnimating
          )
      }

      VStack(spacing: 8) {
        Text("Loading Notifications")
          .font(.headline)
          .foregroundStyle(.primary)

        ProgressView()
          .tint(.blue)
      }
    }
    .onAppear {
      isAnimating = true
    }
  }
}

// MARK: - Empty State View

private struct EmptyStateView: View {

  let onRefresh: () -> Void

  @State private var isAnimating = false

  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        Spacer()
          .frame(height: 20)

        // Beautiful illustration
        ZStack {
          // Background circles
          Circle()
            .fill(
              LinearGradient(
                colors: [.blue.opacity(0.15), .purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .frame(width: 100, height: 100)
            .scaleEffect(isAnimating ? 1.1 : 1.0)
            .animation(
              .easeInOut(duration: 2)
                .repeatForever(autoreverses: true),
              value: isAnimating
            )

          Circle()
            .fill(
              LinearGradient(
                colors: [.blue.opacity(0.2), .cyan.opacity(0.15)],
                startPoint: .top,
                endPoint: .bottom
              )
            )
            .frame(width: 70, height: 70)

          // Bell icon
          Image(systemName: "bell.slash.fill")
            .font(.system(size: 32))
            .foregroundStyle(
              LinearGradient(
                colors: [.blue, .purple],
                startPoint: .top,
                endPoint: .bottom
              )
            )
        }

        VStack(spacing: 10) {
          Text("No Notifications")
            .font(.headline)
            .fontWeight(.bold)

          Text("Your Android notifications will appear here when they arrive.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
        }

        // Refresh button
        Button {
          onRefresh()
        } label: {
          HStack(spacing: 8) {
            Image(systemName: "arrow.clockwise")
            Text("Check for Notifications")
          }
          .font(.footnote)
          .fontWeight(.medium)
          .padding(.horizontal, 16)
          .padding(.vertical, 10)
          .background(
            Capsule()
              .fill(
                LinearGradient(
                  colors: [.blue.opacity(0.8), .blue.opacity(0.6)],
                  startPoint: .leading,
                  endPoint: .trailing
                )
              )
          )
          .foregroundStyle(.white)
        }
        .buttonStyle(.plain)

        // Help text
        VStack(spacing: 6) {
          Text("Make sure:")
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)

          VStack(alignment: .leading, spacing: 4) {
            helpItem("Android app is running")
            helpItem("Same account on both devices")
            helpItem("Internet connection is active")
          }
        }
        .padding()
        .background(
          RoundedRectangle(cornerRadius: 12)
            .fill(Color(white: 0.1))
        )

        Spacer()
      }
      .padding()
    }
    .onAppear {
      isAnimating = true
    }
  }

  private func helpItem(_ text: String) -> some View {
    HStack(spacing: 6) {
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 10))
        .foregroundStyle(.green)
      Text(text)
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
  }
}

// MARK: - Preview

#Preview("Content View - Empty") {
  ContentView()
    .environment(NotificationViewModel.previewInstance)
}

#Preview("Content View - With Notifications") {
  ContentView()
    .environment(NotificationViewModel.previewInstanceWithMultipleNotifications)
}
