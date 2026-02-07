/**
 * Cloud Functions for Pushed Notification Forwarding System.
 *
 * This is the middleware layer that orchestrates notification forwarding
 * from Android sender devices to watchOS receiver clients.
 *
 * Architecture:
 * 1. Android device writes notification to Firestore
 * 2. onDocumentCreated trigger fires
 * 3. Function fetches registered watchOS devices for the user
 * 4. FCM payload is dispatched to all registered devices
 *
 * @see /contract/notification_schema.json for notification schema
 * @see /plans/2026-02-04-firebase-orchestrator-implementation.md for architecture
 */

import * as admin from "firebase-admin";
import { onDocumentCreated, onDocumentDeleted } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

import {
  sendToWatchOSDevices,
  sendDeletionToWatchOSDevices,
  updateDeviceLastSeen,
} from "./notifications";
import { PushedNotification, RegisteredDevice, DeviceType } from "./types";

// Initialize Firebase Admin
admin.initializeApp();

const db = admin.firestore();

/**
 * Triggered when a new notification is created in Firestore.
 *
 * Path: users/{userId}/notifications/{notificationId}
 *
 * This function:
 * 1. Validates the notification data
 * 2. Fetches all registered watchOS devices for the user
 * 3. Dispatches FCM payload to each device
 */
export const onNotificationCreated = onDocumentCreated(
  {
    document: "users/{userId}/notifications/{notificationId}",
    region: "us-central1",
    memory: "256MiB",
    timeoutSeconds: 60,
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.warn("No data in notification document");
      return;
    }

    const userId = event.params.userId;
    const notificationId = event.params.notificationId;
    const notification = snapshot.data() as PushedNotification;

    logger.info("Processing new notification", {
      userId,
      notificationId,
      title: notification.title,
      packageName: notification.packageName,
      sourceDeviceId: notification.sourceDeviceId,
    });

    // Validate required fields
    if (!notification.id || !notification.title || !notification.packageName) {
      logger.error("Invalid notification data", { notificationId, notification });
      return;
    }

    // Validate schema version
    if (!notification.schemaVersion || !notification.schemaVersion.startsWith("1.")) {
      logger.warn("Unsupported schema version", {
        version: notification.schemaVersion,
        notificationId,
      });
      // Continue anyway for forward compatibility, but log warning
    }

    try {
      // Send notification to all watchOS devices
      const result = await sendToWatchOSDevices(userId, notification);

      // Update the notification document with dispatch status
      await snapshot.ref.update({
        dispatchedAt: admin.firestore.FieldValue.serverTimestamp(),
        dispatchSuccessCount: result.successCount,
        dispatchFailureCount: result.failureCount,
      });

      logger.info("Notification dispatch complete", {
        notificationId,
        successCount: result.successCount,
        failureCount: result.failureCount,
      });
    } catch (error) {
      logger.error("Error dispatching notification", { error, notificationId, userId });

      // Mark notification with error status
      await snapshot.ref.update({
        dispatchError: error instanceof Error ? error.message : "Unknown error",
        dispatchedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }
);

/**
 * Triggered when a notification is deleted.
 *
 * Optionally notify watchOS devices to remove the notification from their local store.
 */
export const onNotificationDeleted = onDocumentDeleted(
  {
    document: "users/{userId}/notifications/{notificationId}",
    region: "us-central1",
  },
  async (event) => {
    const userId = event.params.userId;
    const notificationId = event.params.notificationId;

    logger.info("Notification deleted", { userId, notificationId });

    try {
      // Send a data-only message to trigger local deletion on watch
      await sendDeletionToWatchOSDevices(userId, notificationId);
    } catch (error) {
      logger.error("Error sending deletion command", { error, userId, notificationId });
    }
  }
);

/**
 * Callable function to register a device.
 *
 * Called from both Android and watchOS clients after authentication.
 */
export const registerDevice = onCall(
  {
    region: "us-central1",
    memory: "128MiB",
  },
  async (request) => {
    // Verify authentication
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const userId = request.auth.uid;
    const { deviceId, type, fcmToken, deviceName, osVersion, appVersion } = request.data as {
      deviceId: string;
      type: DeviceType;
      fcmToken: string;
      deviceName: string;
      osVersion?: string;
      appVersion?: string;
    };

    // Validate required fields
    if (!deviceId || !type || !fcmToken || !deviceName) {
      throw new HttpsError("invalid-argument", "Missing required fields");
    }

    if (type !== "android" && type !== "watchos") {
      throw new HttpsError("invalid-argument", "Invalid device type");
    }

    logger.info("Registering device", { userId, deviceId, type, deviceName });

    const deviceRef = db.doc(`users/${userId}/devices/${deviceId}`);
    const existingDevice = await deviceRef.get();

    const deviceData: RegisteredDevice = {
      type,
      fcmToken,
      deviceName,
      lastSeen: admin.firestore.Timestamp.now(),
      createdAt: existingDevice.exists
        ? (existingDevice.data() as RegisteredDevice).createdAt
        : admin.firestore.Timestamp.now(),
      ...(osVersion && { osVersion }),
      ...(appVersion && { appVersion }),
    };

    await deviceRef.set(deviceData);

    logger.info("Device registered successfully", { userId, deviceId, type });

    return { success: true, deviceId };
  }
);

/**
 * Callable function to unregister a device.
 *
 * Called when user logs out or disables notifications.
 */
export const unregisterDevice = onCall(
  {
    region: "us-central1",
    memory: "128MiB",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const userId = request.auth.uid;
    const { deviceId } = request.data as { deviceId: string };

    if (!deviceId) {
      throw new HttpsError("invalid-argument", "Device ID required");
    }

    logger.info("Unregistering device", { userId, deviceId });

    const deviceRef = db.doc(`users/${userId}/devices/${deviceId}`);
    await deviceRef.delete();

    logger.info("Device unregistered successfully", { userId, deviceId });

    return { success: true };
  }
);

/**
 * Callable function to update device FCM token.
 *
 * Called when FCM token is refreshed.
 */
export const updateDeviceToken = onCall(
  {
    region: "us-central1",
    memory: "128MiB",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const userId = request.auth.uid;
    const { deviceId, fcmToken } = request.data as {
      deviceId: string;
      fcmToken: string;
    };

    if (!deviceId || !fcmToken) {
      throw new HttpsError("invalid-argument", "Device ID and FCM token required");
    }

    logger.info("Updating device token", { userId, deviceId });

    const deviceRef = db.doc(`users/${userId}/devices/${deviceId}`);
    await deviceRef.update({
      fcmToken,
      lastSeen: admin.firestore.FieldValue.serverTimestamp(),
    });

    logger.info("Device token updated successfully", { userId, deviceId });

    return { success: true };
  }
);

/**
 * Callable function to heartbeat/ping device.
 *
 * Updates lastSeen timestamp for device health monitoring.
 */
export const deviceHeartbeat = onCall(
  {
    region: "us-central1",
    memory: "128MiB",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const userId = request.auth.uid;
    const { deviceId } = request.data as { deviceId: string };

    if (!deviceId) {
      throw new HttpsError("invalid-argument", "Device ID required");
    }

    await updateDeviceLastSeen(userId, deviceId);

    return { success: true, timestamp: Date.now() };
  }
);

/**
 * Callable function to get all registered devices for the current user.
 */
export const getRegisteredDevices = onCall(
  {
    region: "us-central1",
    memory: "128MiB",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const userId = request.auth.uid;

    const devicesRef = db.collection(`users/${userId}/devices`);
    const snapshot = await devicesRef.get();

    const devices: Array<{
      id: string;
      type: DeviceType;
      deviceName: string;
      lastSeen: number;
    }> = [];

    snapshot.forEach((doc) => {
      const data = doc.data() as RegisteredDevice;
      devices.push({
        id: doc.id,
        type: data.type,
        deviceName: data.deviceName,
        lastSeen: data.lastSeen.toMillis(),
      });
    });

    logger.info("Fetched registered devices", { userId, count: devices.length });

    return { devices };
  }
);

/**
 * Callable function to dismiss a notification.
 *
 * Called by watchOS clients when a notification is dismissed locally.
 */
export const dismissNotification = onCall(
  {
    region: "us-central1",
    memory: "128MiB",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const userId = request.auth.uid;
    const { notificationId } = request.data as { notificationId: string };

    if (!notificationId) {
      throw new HttpsError("invalid-argument", "Notification ID required");
    }

    logger.info("Dismissing notification", { userId, notificationId });

    const notificationRef = db.doc(`users/${userId}/notifications/${notificationId}`);
    await notificationRef.delete();

    return { success: true };
  }
);

/**
 * Callable function to handle notification action requests.
 *
 * Called by watchOS clients to forward action intent to the backend.
 */
export const handleNotificationAction = onCall(
  {
    region: "us-central1",
    memory: "128MiB",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const userId = request.auth.uid;
    const { notificationId, actionId, actionLabel, timestamp } = request.data as {
      notificationId: string;
      actionId: string;
      actionLabel?: string;
      timestamp?: string;
    };

    if (!notificationId || !actionId) {
      throw new HttpsError("invalid-argument", "Notification ID and action ID required");
    }

    const actionRef = db.collection(`users/${userId}/notificationActions`).doc();

    await actionRef.set({
      notificationId,
      actionId,
      actionLabel: actionLabel ?? null,
      clientTimestamp: timestamp ?? null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    logger.info("Recorded notification action", { userId, notificationId, actionId });

    return { success: true, actionEventId: actionRef.id };
  }
);
