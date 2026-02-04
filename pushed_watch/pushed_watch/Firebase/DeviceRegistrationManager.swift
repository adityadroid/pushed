import Foundation
import FirebaseFirestore

/// Manager for device registration with Firebase on watchOS.
///
/// Handles:
/// - Registering watchOS devices for push notifications
/// - Storing FCM tokens in Firestore
/// - Device heartbeats and status updates
@MainActor
@Observable
final class DeviceRegistrationManager {
    
    // MARK: - State
    
    /// Whether the device is currently registered
    var isRegistered = false
    
    /// Last registration error if any
    var lastError: Error?
    
    // MARK: - Dependencies
    
    private let authManager: AuthManager
    private let pushDelegate: PushNotificationDelegate
    private let firestore = Firestore.firestore()
    
    // MARK: - Device Info
    
    /// Unique identifier for this device
    var deviceId: String {
        // Use a stable identifier for watchOS
        if let existingId = UserDefaults.standard.string(forKey: "pushed_device_id") {
            return existingId
        }
        
        let newId = "watchos_\(UUID().uuidString)"
        UserDefaults.standard.set(newId, forKey: "pushed_device_id")
        return newId
    }
    
    /// Human-readable device name
    var deviceName: String {
        #if os(watchOS)
        return "Apple Watch"
        #else
        return "Unknown Device"
        #endif
    }
    
    // MARK: - Initialization
    
    init(authManager: AuthManager, pushDelegate: PushNotificationDelegate) {
        self.authManager = authManager
        self.pushDelegate = pushDelegate
    }
    
    // MARK: - Public Methods
    
    /// Register this device for push notifications.
    ///
    /// Must be called after successful authentication.
    func registerDevice() async throws {
        guard let userId = authManager.currentUserId else {
            throw DeviceError.notAuthenticated
        }
        
        let fcmToken = try await pushDelegate.getToken()
        
        let deviceData: [String: Any] = [
            "type": "watchos",
            "fcmToken": fcmToken,
            "deviceName": deviceName,
            "lastSeen": FieldValue.serverTimestamp(),
            "createdAt": FieldValue.serverTimestamp(),
            "osVersion": getOSVersion()
        ]
        
        do {
            try await firestore
                .collection("users")
                .document(userId)
                .collection("devices")
                .document(deviceId)
                .setData(deviceData, merge: true)
            
            isRegistered = true
            lastError = nil
            print("Device registered successfully: \(deviceId)")
        } catch {
            lastError = error
            throw DeviceError.registrationFailed(error.localizedDescription)
        }
    }
    
    /// Unregister this device.
    ///
    /// Called when user signs out.
    func unregisterDevice() async throws {
        guard let userId = authManager.currentUserId else {
            throw DeviceError.notAuthenticated
        }
        
        do {
            try await firestore
                .collection("users")
                .document(userId)
                .collection("devices")
                .document(deviceId)
                .delete()
            
            isRegistered = false
            print("Device unregistered: \(deviceId)")
        } catch {
            throw DeviceError.unregistrationFailed(error.localizedDescription)
        }
    }
    
    /// Update the FCM token for this device.
    ///
    /// Called when FCM token is refreshed.
    func updateToken(_ newToken: String) async throws {
        guard let userId = authManager.currentUserId else {
            return // Silently fail if not authenticated
        }
        
        do {
            try await firestore
                .collection("users")
                .document(userId)
                .collection("devices")
                .document(deviceId)
                .updateData([
                    "fcmToken": newToken,
                    "lastSeen": FieldValue.serverTimestamp()
                ])
            
            print("FCM token updated for device \(deviceId)")
        } catch {
            print("Failed to update FCM token: \(error)")
        }
    }
    
    /// Send a heartbeat to update lastSeen timestamp.
    func sendHeartbeat() async {
        guard let userId = authManager.currentUserId, isRegistered else {
            return
        }
        
        do {
            try await firestore
                .collection("users")
                .document(userId)
                .collection("devices")
                .document(deviceId)
                .updateData([
                    "lastSeen": FieldValue.serverTimestamp()
                ])
        } catch {
            print("Failed to send heartbeat: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func getOSVersion() -> String {
        #if os(watchOS)
        return "watchOS \(ProcessInfo.processInfo.operatingSystemVersion.majorVersion).\(ProcessInfo.processInfo.operatingSystemVersion.minorVersion)"
        #else
        return "Unknown"
        #endif
    }
}

// MARK: - Errors

enum DeviceError: LocalizedError {
    case notAuthenticated
    case registrationFailed(String)
    case unregistrationFailed(String)
    case tokenNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            "User must be authenticated"
        case .registrationFailed(let reason):
            "Device registration failed: \(reason)"
        case .unregistrationFailed(let reason):
            "Device unregistration failed: \(reason)"
        case .tokenNotAvailable:
            "FCM token not available"
        }
    }
}
