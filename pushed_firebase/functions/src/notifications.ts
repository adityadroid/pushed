/**
 * Notification forwarding logic for Pushed.
 *
 * This module handles:
 * - Fetching registered watchOS devices for a user
 * - Building FCM payloads for Apple devices
 * - Dispatching notifications via Firebase Cloud Messaging
 * - Cleaning up stale device tokens
 */

import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import {
  PushedNotification,
  RegisteredDevice,
  FCMPayload,
  FCMBatchResult,
} from "./types";

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Fetch all registered watchOS devices for a user.
 */
export async function getWatchOSDevices(
  userId: string
): Promise<{ id: string; device: RegisteredDevice }[]> {
  const devicesRef = db.collection(`users/${userId}/devices`);
  const snapshot = await devicesRef.where("type", "==", "watchos").get();

  const devices: { id: string; device: RegisteredDevice }[] = [];

  snapshot.forEach((doc) => {
    const data = doc.data() as RegisteredDevice;
    devices.push({ id: doc.id, device: data });
  });

  logger.info(`Found ${devices.length} watchOS devices for user ${userId}`);
  return devices;
}

/**
 * Build FCM payload for watchOS devices.
 */
export function buildFCMPayload(notification: PushedNotification): FCMPayload {
  const body = notification.body || "New notification";
  const subtitle = notification.appName || notification.packageName;

  // Map priority to APNs priority
  const apnsPriority = notification.priority === "high" || notification.priority === "max"
    ? "10"
    : "5";

  return {
    notification: {
      title: notification.title,
      body: body,
    },
    data: {
      notificationId: notification.id,
      schemaVersion: notification.schemaVersion,
      packageName: notification.packageName,
      appName: notification.appName || notification.packageName,
      category: notification.category,
      priority: notification.priority,
      sourceDeviceId: notification.sourceDeviceId,
      timestamp: notification.timestamp.toDate().toISOString(),
      ...(notification.body && { body: notification.body }),
      actions: JSON.stringify(notification.actions ?? []),
      ...(notification.iconData && { iconData: notification.iconData }),
      ...(notification.subText && { subText: notification.subText }),
      isOngoing: notification.isOngoing ? "true" : "false",
      isSilent: notification.isSilent ? "true" : "false",
      ...(notification.createdAt && {
        createdAt: notification.createdAt.toDate().toISOString(),
      }),
      ...(notification.groupKey && { groupKey: notification.groupKey }),
      ...(notification.color && { color: notification.color }),
      ...(notification.senderName && { senderName: notification.senderName }),
      ...(notification.conversationId && { conversationId: notification.conversationId }),
    },
    apns: {
      payload: {
        aps: {
          alert: {
            title: notification.title,
            body: body,
            subtitle: subtitle,
          },
          sound: notification.isSilent ? "" : "default",
          "mutable-content": 1,
          "content-available": 1,
        },
      },
      headers: {
        "apns-priority": apnsPriority,
        "apns-push-type": "alert",
      },
    },
  };
}

/**
 * Send notification to all registered watchOS devices for a user.
 */
export async function sendToWatchOSDevices(
  userId: string,
  notification: PushedNotification
): Promise<FCMBatchResult> {
  const devices = await getWatchOSDevices(userId);

  if (devices.length === 0) {
    logger.info(`No watchOS devices registered for user ${userId}, skipping FCM dispatch`);
    return { successCount: 0, failureCount: 0, failedTokens: [] };
  }

  const payload = buildFCMPayload(notification);
  const tokens = devices.map((d) => d.device.fcmToken);

  logger.info(`Sending notification to ${tokens.length} watchOS devices`, {
    notificationId: notification.id,
    userId: userId,
    sourceDevice: notification.sourceDeviceId,
  });

  // Send to all devices using multicast
  try {
    const response = await messaging.sendEachForMulticast({
      tokens: tokens,
      notification: payload.notification,
      data: payload.data,
      apns: payload.apns,
    });

    const failedTokens: string[] = [];

    // Process responses to identify failed tokens
    response.responses.forEach((resp, idx) => {
      if (!resp.success) {
        failedTokens.push(tokens[idx]);
        logger.warn(`Failed to send to token ${tokens[idx].substring(0, 20)}...`, {
          error: resp.error?.message,
          code: resp.error?.code,
        });
      }
    });

    // Clean up invalid tokens
    if (failedTokens.length > 0) {
      await cleanupInvalidTokens(userId, devices, failedTokens);
    }

    logger.info("FCM dispatch complete", {
      successCount: response.successCount,
      failureCount: response.failureCount,
      notificationId: notification.id,
    });

    return {
      successCount: response.successCount,
      failureCount: response.failureCount,
      failedTokens: failedTokens,
    };
  } catch (error) {
    logger.error("Error sending FCM messages", { error, userId, notificationId: notification.id });
    throw error;
  }
}

/**
 * Remove invalid/stale FCM tokens from user's device registry.
 */
async function cleanupInvalidTokens(
  userId: string,
  devices: { id: string; device: RegisteredDevice }[],
  failedTokens: string[]
): Promise<void> {
  const batch = db.batch();
  let deleteCount = 0;

  for (const { id, device } of devices) {
    if (failedTokens.includes(device.fcmToken)) {
      // Check if the token failure is due to an unregistered token
      // We should delete these tokens to keep the registry clean
      const deviceRef = db.doc(`users/${userId}/devices/${id}`);
      batch.delete(deviceRef);
      deleteCount++;
      logger.info(`Removing invalid device ${id} with failed token`);
    }
  }

  if (deleteCount > 0) {
    await batch.commit();
    logger.info(`Cleaned up ${deleteCount} invalid device tokens for user ${userId}`);
  }
}

/**
 * Update device's lastSeen timestamp.
 */
export async function updateDeviceLastSeen(
  userId: string,
  deviceId: string
): Promise<void> {
  const deviceRef = db.doc(`users/${userId}/devices/${deviceId}`);
  await deviceRef.update({
    lastSeen: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/**
 * Get count of active notifications for badging.
 */
export async function getActiveNotificationCount(userId: string): Promise<number> {
  // Get count of notifications from the last 24 hours
  const oneDayAgo = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() - 24 * 60 * 60 * 1000)
  );

  const snapshot = await db
    .collection(`users/${userId}/notifications`)
    .where("timestamp", ">=", oneDayAgo)
    .count()
    .get();

  return snapshot.data().count;
}
