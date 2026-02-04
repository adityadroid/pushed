import SwiftUI

/// Main entry point for the Pushed watchOS app.
@main
struct PushedWatchApp: App {
    
    @State private var viewModel = NotificationViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
        }
    }
}
