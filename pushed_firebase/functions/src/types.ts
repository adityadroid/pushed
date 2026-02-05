/**
 * Type definitions for Pushed notification system.
 * These types mirror the shared contract defined in /contract/notification_schema.json
 */

/**
 * Notification category for filtering and grouping.
 */
export type NotificationCategory =
    | "message"
    | "email"
    | "social"
    | "news"
    | "promo"
    | "reminder"
    | "call"
    | "transport"
    | "alarm"
    | "other";

/**
 * Notification priority level.
 */
export type NotificationPriority = "min" | "low" | "default" | "high" | "max";

/**
 * Device type for registration.
 */
export type DeviceType = "android" | "watchos";

/**
 * Notification action button.
 */
export interface NotificationAction {
    id: string;
    label: string;
    isDestructive?: boolean;
    requiresUnlock?: boolean;
    icon?: string | null;
}

/**
 * Pushed notification payload matching the shared contract.
 */
export interface PushedNotification {
    id: string;
    schemaVersion: string;
    timestamp: FirebaseFirestore.Timestamp;
    title: string;
    body?: string | null;
    packageName: string;
    appName?: string | null;
    category: NotificationCategory;
    priority: NotificationPriority;
    actions?: NotificationAction[];
    groupKey?: string | null;
    isOngoing?: boolean;
    isSilent?: boolean;
    iconData?: string | null;
    color?: string | null;
    subText?: string | null;
    conversationId?: string | null;
    senderName?: string | null;

    // Additional fields for the cloud function
    sourceDeviceId: string;
    createdAt: FirebaseFirestore.Timestamp;
}

/**
 * Registered device for receiving notifications.
 */
export interface RegisteredDevice {
    type: DeviceType;
    fcmToken: string;
    deviceName: string;
    lastSeen: FirebaseFirestore.Timestamp;
    createdAt: FirebaseFirestore.Timestamp;
}

/**
 * User profile data.
 */
export interface UserProfile {
    email?: string | null;
    displayName?: string | null;
    createdAt: FirebaseFirestore.Timestamp;
    updatedAt: FirebaseFirestore.Timestamp;
}

/**
 * FCM notification payload for watchOS.
 */
export interface FCMPayload {
    notification: {
        title: string;
        body: string;
    };
    data: {
        notificationId: string;
        schemaVersion: string;
        packageName: string;
        appName: string;
        category: string;
        priority: string;
        sourceDeviceId: string;
        timestamp: string;
        body?: string;
        actions?: string;
        iconData?: string;
        subText?: string;
        isOngoing?: string;
        isSilent?: string;
        createdAt?: string;
        groupKey?: string;
        color?: string;
        senderName?: string;
        conversationId?: string;
    };
    apns: {
        payload: {
            aps: {
                alert: {
                    title: string;
                    body: string;
                    subtitle?: string;
                };
                sound: string;
                badge?: number;
                "mutable-content": number;
                "content-available": number;
            };
        };
        headers: {
            "apns-priority": string;
            "apns-push-type": string;
        };
    };
}

/**
 * Result of sending FCM to multiple devices.
 */
export interface FCMBatchResult {
    successCount: number;
    failureCount: number;
    failedTokens: string[];
}
