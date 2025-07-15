import {
  collection,
  addDoc,
  query,
  where,
  orderBy,
  limit,
  onSnapshot,
  updateDoc,
  doc,
  Timestamp,
  getDocs,
} from "firebase/firestore";
import { db } from "@/lib/firebase";

export interface Notification {
  id: string;
  title: string;
  message: string;
  type: "info" | "success" | "warning" | "error" | "emergency";
  priority: "low" | "medium" | "high" | "critical";
  userId?: string; // If null, it's a system-wide notification
  read: boolean;
  actionUrl?: string;
  actionLabel?: string;
  metadata?: Record<string, any>;
  createdAt: Date;
  expiresAt?: Date;
}

export interface NotificationPreferences {
  userId: string;
  emailNotifications: boolean;
  pushNotifications: boolean;
  smsNotifications: boolean;
  emergencyAlerts: boolean;
  systemUpdates: boolean;
  reportReminders: boolean;
  maintenanceAlerts: boolean;
  quietHours: {
    enabled: boolean;
    start: string; // HH:MM format
    end: string; // HH:MM format
  };
}

export class NotificationService {
  private static instance: NotificationService;

  static getInstance(): NotificationService {
    if (!NotificationService.instance) {
      NotificationService.instance = new NotificationService();
    }
    return NotificationService.instance;
  }

  // Create a new notification
  async createNotification(
    notification: Omit<Notification, "id" | "createdAt" | "read">
  ): Promise<string> {
    try {
      const docRef = await addDoc(collection(db, "notifications"), {
        ...notification,
        read: false,
        createdAt: Timestamp.now(),
        ...(notification.expiresAt && {
          expiresAt: Timestamp.fromDate(notification.expiresAt),
        }),
      });

      // Send push notification if enabled
      if (notification.userId) {
        await this.sendPushNotification(notification.userId, notification);
      } else {
        // System-wide notification
        await this.sendSystemWideNotification(notification);
      }

      return docRef.id;
    } catch (error) {
      console.error("Error creating notification:", error);
      throw error;
    }
  }

  // Subscribe to user notifications
  subscribeToNotifications(
    userId: string,
    callback: (notifications: Notification[]) => void
  ): () => void {
    const q = query(
      collection(db, "notifications"),
      where("userId", "in", [userId, null]), // User-specific and system-wide
      orderBy("createdAt", "desc"),
      limit(50)
    );

    return onSnapshot(q, (snapshot) => {
      const notifications: Notification[] = [];
      snapshot.forEach((doc) => {
        const data = doc.data();
        notifications.push({
          id: doc.id,
          ...data,
          createdAt: data.createdAt?.toDate() || new Date(),
          expiresAt: data.expiresAt?.toDate(),
        } as Notification);
      });
      callback(notifications);
    });
  }

  // Mark notification as read
  async markAsRead(notificationId: string): Promise<void> {
    try {
      const notificationRef = doc(db, "notifications", notificationId);
      await updateDoc(notificationRef, {
        read: true,
      });
    } catch (error) {
      console.error("Error marking notification as read:", error);
      throw error;
    }
  }

  // Mark all notifications as read for a user
  async markAllAsRead(userId: string): Promise<void> {
    try {
      const q = query(
        collection(db, "notifications"),
        where("userId", "==", userId),
        where("read", "==", false)
      );

      const snapshot = await getDocs(q);
      const updatePromises = snapshot.docs.map((doc) =>
        updateDoc(doc.ref, { read: true })
      );

      await Promise.all(updatePromises);
    } catch (error) {
      console.error("Error marking all notifications as read:", error);
      throw error;
    }
  }

  // Get notification preferences
  async getNotificationPreferences(userId: string): Promise<NotificationPreferences> {
    try {
      const q = query(
        collection(db, "notification_preferences"),
        where("userId", "==", userId)
      );

      const snapshot = await getDocs(q);
      if (!snapshot.empty) {
        const doc = snapshot.docs[0];
        return { id: doc.id, ...doc.data() } as NotificationPreferences;
      }

      // Return default preferences
      return {
        userId,
        emailNotifications: true,
        pushNotifications: true,
        smsNotifications: false,
        emergencyAlerts: true,
        systemUpdates: true,
        reportReminders: true,
        maintenanceAlerts: true,
        quietHours: {
          enabled: false,
          start: "22:00",
          end: "08:00",
        },
      };
    } catch (error) {
      console.error("Error getting notification preferences:", error);
      throw error;
    }
  }

  // Update notification preferences
  async updateNotificationPreferences(
    preferences: NotificationPreferences
  ): Promise<void> {
    try {
      const q = query(
        collection(db, "notification_preferences"),
        where("userId", "==", preferences.userId)
      );

      const snapshot = await getDocs(q);
      if (!snapshot.empty) {
        const docRef = snapshot.docs[0].ref;
        await updateDoc(docRef, preferences);
      } else {
        await addDoc(collection(db, "notification_preferences"), preferences);
      }
    } catch (error) {
      console.error("Error updating notification preferences:", error);
      throw error;
    }
  }

  // Emergency notification helpers
  async sendEmergencyAlert(
    emergencyId: string,
    type: string,
    location: string,
    priority: "high" | "critical" = "critical"
  ): Promise<void> {
    const notification = {
      title: `${type} Emergency Alert`,
      message: `New ${type.toLowerCase()} emergency reported at ${location}`,
      type: "emergency" as const,
      priority,
      actionUrl: `/emergencies/${emergencyId}`,
      actionLabel: "View Emergency",
      metadata: { emergencyId, type, location },
    };

    await this.createNotification(notification);
  }

  async sendStatusUpdateNotification(
    emergencyId: string,
    oldStatus: string,
    newStatus: string,
    userId?: string
  ): Promise<void> {
    const notification = {
      title: "Emergency Status Updated",
      message: `Emergency status changed from ${oldStatus} to ${newStatus}`,
      type: "info" as const,
      priority: "medium" as const,
      userId,
      actionUrl: `/emergencies/${emergencyId}`,
      actionLabel: "View Emergency",
      metadata: { emergencyId, oldStatus, newStatus },
    };

    await this.createNotification(notification);
  }

  async sendResponderAssignmentNotification(
    emergencyId: string,
    responderIds: string[],
    emergencyType: string,
    location: string
  ): Promise<void> {
    const promises = responderIds.map((responderId) =>
      this.createNotification({
        title: "New Emergency Assignment",
        message: `You have been assigned to a ${emergencyType} emergency at ${location}`,
        type: "warning",
        priority: "high",
        userId: responderId,
        actionUrl: `/emergencies/${emergencyId}`,
        actionLabel: "View Assignment",
        metadata: { emergencyId, emergencyType, location },
      })
    );

    await Promise.all(promises);
  }

  async sendSystemMaintenanceNotification(
    title: string,
    message: string,
    scheduledTime: Date
  ): Promise<void> {
    const notification = {
      title,
      message,
      type: "warning" as const,
      priority: "medium" as const,
      metadata: { scheduledTime: scheduledTime.toISOString() },
    };

    await this.createNotification(notification);
  }

  // Private helper methods
  private async sendPushNotification(
    userId: string,
    notification: Omit<Notification, "id" | "createdAt" | "read">
  ): Promise<void> {
    // Check user preferences
    const preferences = await this.getNotificationPreferences(userId);
    
    if (!preferences.pushNotifications) {
      return;
    }

    // Check quiet hours
    if (preferences.quietHours.enabled && this.isQuietHours(preferences.quietHours)) {
      // Only send critical notifications during quiet hours
      if (notification.priority !== "critical") {
        return;
      }
    }

    // In a real implementation, this would integrate with a push notification service
    // like Firebase Cloud Messaging, OneSignal, etc.
    console.log(`Push notification sent to user ${userId}:`, notification);
  }

  private async sendSystemWideNotification(
    notification: Omit<Notification, "id" | "createdAt" | "read">
  ): Promise<void> {
    // In a real implementation, this would send to all users based on their preferences
    console.log("System-wide notification:", notification);
  }

  private isQuietHours(quietHours: { start: string; end: string }): boolean {
    const now = new Date();
    const currentTime = now.getHours() * 60 + now.getMinutes();
    
    const [startHour, startMin] = quietHours.start.split(":").map(Number);
    const [endHour, endMin] = quietHours.end.split(":").map(Number);
    
    const startTime = startHour * 60 + startMin;
    const endTime = endHour * 60 + endMin;

    if (startTime <= endTime) {
      return currentTime >= startTime && currentTime <= endTime;
    } else {
      // Quiet hours span midnight
      return currentTime >= startTime || currentTime <= endTime;
    }
  }

  // Cleanup expired notifications
  async cleanupExpiredNotifications(): Promise<void> {
    try {
      const now = Timestamp.now();
      const q = query(
        collection(db, "notifications"),
        where("expiresAt", "<=", now)
      );

      const snapshot = await getDocs(q);
      const deletePromises = snapshot.docs.map((doc) => doc.ref.delete());
      
      await Promise.all(deletePromises);
      console.log(`Cleaned up ${snapshot.docs.length} expired notifications`);
    } catch (error) {
      console.error("Error cleaning up expired notifications:", error);
    }
  }
}

export const notificationService = NotificationService.getInstance();
