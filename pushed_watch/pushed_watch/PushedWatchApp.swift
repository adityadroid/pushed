import FirebaseCore
import SwiftData
import SwiftUI
import os.log

/// Logger for app-level events
private let appLogger = Logger(subsystem: "com.pushed.watch", category: "App")

/// Main entry point for the Pushed watchOS app.
///
/// **Signing Identity**: adityagurjar.it18@gmail.com
/// **Do NOT use**: a.gurjar@scbank.com.eg
@main
struct PushedWatchApp: App {

  // MARK: - State Objects

  @State private var authManager: AuthManager
  @State private var viewModel: NotificationViewModel
  @State private var pushDelegate: PushNotificationDelegate
  @State private var registrationManager: DeviceRegistrationManager

  private let modelContainer: ModelContainer

  // MARK: - Initialization

  init() {
    appLogger.info("🚀 PushedWatchApp init() starting...")

    // Configure Firebase on app launch
    appLogger.info("🔥 Configuring Firebase...")
    FirebaseConfiguration.shared.configure()
    appLogger.info("✅ Firebase configured")

    appLogger.info("🔧 Creating AuthManager...")
    let authManager = AuthManager()
    appLogger.info("✅ AuthManager created")

    appLogger.info("🔧 Creating PushNotificationDelegate...")
    let pushDelegate = PushNotificationDelegate()
    appLogger.info("✅ PushNotificationDelegate created")

    appLogger.info("🔧 Creating ModelContainer...")
    let container = try! ModelContainer(for: StoredNotification.self)
    appLogger.info("✅ ModelContainer created")

    let store = NotificationStore(modelContext: container.mainContext)
    let syncService = NotificationSyncService(
      deviceIdProvider: {
        authManager.isAuthenticated ? UserDefaults.standard.string(forKey: "pushed_device_id") : nil
      }
    )
    let viewModel = NotificationViewModel(
      syncService: syncService,
      notificationStore: store
    )

    appLogger.info("🔧 Creating DeviceRegistrationManager...")
    let registrationManager = DeviceRegistrationManager(
      authManager: authManager,
      pushDelegate: pushDelegate
    )
    appLogger.info("✅ DeviceRegistrationManager created")

    _authManager = State(initialValue: authManager)
    _pushDelegate = State(initialValue: pushDelegate)
    _viewModel = State(initialValue: viewModel)
    _registrationManager = State(initialValue: registrationManager)
    modelContainer = container

    appLogger.info("✅ PushedWatchApp init() complete")
  }

  // MARK: - Body

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(authManager)
        .environment(viewModel)
        .environment(registrationManager)
        .environmentObject(pushDelegate)
        .modelContainer(modelContainer)
        .onAppear {
          appLogger.info("📱 RootView appeared - setting up notification handling")
          setupNotificationHandling()
        }
    }
  }

  // MARK: - Private Methods

  private func setupNotificationHandling() {
    appLogger.info("🔧 setupNotificationHandling() called")

    // Wire up notification handling to view model
    pushDelegate.onNotificationReceived = { notification in
      appLogger.info("📩 onNotificationReceived callback triggered")
      Task { @MainActor in
        viewModel.addNotification(notification)
      }
    }

    pushDelegate.onNotificationDeleted = { notificationId in
      appLogger.info("🗑️ onNotificationDeleted callback triggered: \(notificationId)")
      Task { @MainActor in
        viewModel.removeNotification(withId: notificationId)
      }
    }

    pushDelegate.onTokenUpdated = { token in
      appLogger.info("🔑 onTokenUpdated callback triggered - token: \(token.prefix(20))...")
      appLogger.info("   Triggering device registration...")
      Task { @MainActor in
        do {
          try await registrationManager.registerDevice()
          appLogger.info("✅ Device registration from onTokenUpdated succeeded")
        } catch {
          appLogger.error(
            "❌ Device registration from onTokenUpdated failed: \(error.localizedDescription)")
        }
      }
    }

    appLogger.info("✅ Notification handling set up")
  }
}

/// Root view that handles authentication state.
struct RootView: View {

  @Environment(\.scenePhase) private var scenePhase
  @Environment(AuthManager.self) private var authManager
  @Environment(DeviceRegistrationManager.self) private var registrationManager

  var body: some View {
    Group {
      switch authManager.authState {
      case .loading:
        ProgressView("Loading...")
          .onAppear {
            appLogger.info("📱 Showing loading state")
          }

      case .unauthenticated:
        LoginView()
          .onAppear {
            appLogger.info("📱 Showing login view - user not authenticated")
          }

      case .authenticated(let userId, let email, _):
        ContentView()
          .onAppear {
            appLogger.info("📱 Showing content view - user authenticated")
            appLogger.info("   userId: \(userId)")
            appLogger.info("   email: \(email ?? "nil")")
          }
      }
    }
    .animation(.easeInOut, value: authManager.authState)
    .task {
      appLogger.info("📱 RootView .task triggered - calling registerDeviceIfNeeded()")
      await registerDeviceIfNeeded()
    }
    .onChange(of: authManager.authState) { oldState, newState in
      appLogger.info(
        "🔔 authState changed: \(String(describing: oldState)) -> \(String(describing: newState))")
      if case .authenticated(let userId, _, _) = newState {
        appLogger.info("   User is now authenticated with userId: \(userId)")
        appLogger.info("   Triggering registerDeviceIfNeeded()...")
        Task { await registerDeviceIfNeeded() }
      }
    }
    .onChange(of: scenePhase) { oldPhase, newPhase in
      appLogger.info(
        "🔔 scenePhase changed: \(String(describing: oldPhase)) -> \(String(describing: newPhase))")
      if newPhase == .active {
        appLogger.info("   App became active - triggering registerDeviceIfNeeded()")
        Task { await registerDeviceIfNeeded() }
      }
    }
  }

  private func registerDeviceIfNeeded() async {
    appLogger.info("🔄 registerDeviceIfNeeded() called")
    appLogger.info("   authManager.isAuthenticated = \(authManager.isAuthenticated)")
    appLogger.info("   authManager.currentUserId = \(authManager.currentUserId ?? "nil")")
    appLogger.info("   authManager.authState = \(String(describing: authManager.authState))")

    guard authManager.isAuthenticated else {
      appLogger.info("⚠️ User not authenticated - skipping registration")
      return
    }

    appLogger.info("✅ User is authenticated - proceeding with registration")

    do {
      try await registrationManager.registerDevice()
      appLogger.info("✅ registerDeviceIfNeeded() completed successfully")
    } catch {
      appLogger.error("❌ registerDeviceIfNeeded() failed: \(error.localizedDescription)")
      registrationManager.lastError = error
    }
  }
}

/// Login view for Firebase authentication.
struct LoginView: View {

  @Environment(AuthManager.self) private var authManager

  @State private var email = ""
  @State private var password = ""
  @State private var isLoading = false
  @State private var errorMessage: String?
  @State private var showingCreateAccount = false

  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        // Header
        VStack(spacing: 8) {
          Image(systemName: "bell.badge.fill")
            .font(.system(size: 40))
            .foregroundStyle(.blue)

          Text("Pushed")
            .font(.headline)

          Text("Sign in to receive notifications")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .padding(.bottom, 8)

        // Email field
        TextField("Email", text: $email)
          .textContentType(.emailAddress)
          .autocorrectionDisabled()
          #if os(iOS)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
          #endif

        // Password field
        SecureField("Password", text: $password)
          .textContentType(.password)

        // Error message
        if let error = errorMessage {
          Text(error)
            .font(.caption2)
            .foregroundStyle(.red)
            .multilineTextAlignment(.center)
        }

        // Sign in button
        Button(action: signIn) {
          if isLoading {
            ProgressView()
          } else {
            Text("Sign In")
              .frame(maxWidth: .infinity)
          }
        }
        .buttonStyle(.borderedProminent)
        .disabled(isLoading || email.isEmpty || password.isEmpty)

        // Create account button
        Button("Create Account") {
          showingCreateAccount = true
        }
        .font(.caption)
        .foregroundStyle(.blue)
      }
      .padding()
    }
    .sheet(isPresented: $showingCreateAccount) {
      CreateAccountView()
    }
  }

  private func signIn() {
    guard !email.isEmpty, !password.isEmpty else { return }

    isLoading = true
    errorMessage = nil

    Task {
      do {
        _ = try await authManager.signIn(email: email, password: password)
      } catch {
        errorMessage = error.localizedDescription
      }
      isLoading = false
    }
  }
}

/// Create account view.
struct CreateAccountView: View {

  @Environment(AuthManager.self) private var authManager
  @Environment(\.dismiss) private var dismiss

  @State private var email = ""
  @State private var password = ""
  @State private var confirmPassword = ""
  @State private var isLoading = false
  @State private var errorMessage: String?

  var passwordsMatch: Bool {
    !password.isEmpty && password == confirmPassword
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        Text("Create Account")
          .font(.headline)

        TextField("Email", text: $email)
          .textContentType(.emailAddress)
          .autocorrectionDisabled()

        SecureField("Password", text: $password)
          .textContentType(.newPassword)

        SecureField("Confirm Password", text: $confirmPassword)
          .textContentType(.newPassword)

        if !passwordsMatch && !confirmPassword.isEmpty {
          Text("Passwords don't match")
            .font(.caption2)
            .foregroundStyle(.orange)
        }

        if let error = errorMessage {
          Text(error)
            .font(.caption2)
            .foregroundStyle(.red)
            .multilineTextAlignment(.center)
        }

        Button(action: createAccount) {
          if isLoading {
            ProgressView()
          } else {
            Text("Create Account")
              .frame(maxWidth: .infinity)
          }
        }
        .buttonStyle(.borderedProminent)
        .disabled(isLoading || email.isEmpty || !passwordsMatch)

        Button("Cancel") {
          dismiss()
        }
        .font(.caption)
      }
      .padding()
    }
  }

  private func createAccount() {
    guard passwordsMatch else { return }

    isLoading = true
    errorMessage = nil

    Task {
      do {
        _ = try await authManager.createAccount(email: email, password: password)
        dismiss()
      } catch {
        errorMessage = error.localizedDescription
      }
      isLoading = false
    }
  }
}

#Preview {
  RootView()
    .environment(AuthManager())
}
