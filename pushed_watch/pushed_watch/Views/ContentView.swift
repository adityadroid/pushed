import SwiftUI

/// Main content view that displays the notification list.
struct ContentView: View {
    
    @Environment(NotificationViewModel.self) private var viewModel
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    LoadingView()
                } else if viewModel.notifications.isEmpty {
                    EmptyStateView()
                } else {
                    NotificationListView()
                }
            }
            .navigationTitle("Pushed")
            .navigationDestination(for: PushedNotification.self) { notification in
                NotificationDetailView(notification: notification)
            }
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
    }
}

// MARK: - Loading View

private struct LoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(.blue)
            Text("Loading...")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Empty State View

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            
            Text("No Notifications")
                .font(.headline)
            
            Text("Notifications from your Android device will appear here.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environment(NotificationViewModel.previewInstance)
}
