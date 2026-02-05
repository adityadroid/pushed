import SwiftUI
import FirebaseCore
import SwiftData

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
        // Configure Firebase on app launch
        FirebaseConfiguration.shared.configure()

        let authManager = AuthManager()
        let pushDelegate = PushNotificationDelegate()

        let container = try! ModelContainer(for: StoredNotification.self)
        let store = NotificationStore(modelContext: container.mainContext)
        let syncService = NotificationSyncService(
            deviceIdProvider: { authManager.isAuthenticated ? UserDefaults.standard.string(forKey: "pushed_device_id") : nil }
        )
        let viewModel = NotificationViewModel(
            syncService: syncService,
            notificationStore: store
        )
        let registrationManager = DeviceRegistrationManager(
            authManager: authManager,
            pushDelegate: pushDelegate
        )

        _authManager = State(initialValue: authManager)
        _pushDelegate = State(initialValue: pushDelegate)
        _viewModel = State(initialValue: viewModel)
        _registrationManager = State(initialValue: registrationManager)
        modelContainer = container
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
                    setupNotificationHandling()
                }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupNotificationHandling() {
        // Wire up notification handling to view model
        pushDelegate.onNotificationReceived = { notification in
            Task { @MainActor in
                viewModel.addNotification(notification)
            }
        }

        pushDelegate.onTokenUpdated = { token in
            Task { @MainActor in
                if registrationManager.isRegistered {
                    try? await registrationManager.updateToken(token)
                } else {
                    try? await registrationManager.registerDevice()
                }
            }
        }
    }
}

/// Root view that handles authentication state.
struct RootView: View {
    
    @Environment(AuthManager.self) private var authManager
    @Environment(DeviceRegistrationManager.self) private var registrationManager
    
    var body: some View {
        Group {
            switch authManager.authState {
            case .loading:
                ProgressView("Loading...")
                
            case .unauthenticated:
                LoginView()
                
            case .authenticated:
                ContentView()
            }
        }
        .animation(.easeInOut, value: authManager.authState)
        .task {
            await registerDeviceIfNeeded()
        }
        .onChange(of: authManager.authState) { _, newState in
            if case .authenticated = newState {
                Task { await registerDeviceIfNeeded() }
            }
        }
    }

    private func registerDeviceIfNeeded() async {
        guard authManager.isAuthenticated else { return }
        do {
            try await registrationManager.registerDevice()
        } catch {
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
