import { useState, useEffect, useCallback } from "react";
import {
  notificationService,
  type Notification,
  type NotificationPreferences,
} from "@/services/notificationService";

// Hook for managing user notifications
export function useNotifications(userId: string) {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!userId) return;

    setLoading(true);
    setError(null);

    const unsubscribe = notificationService.subscribeToNotifications(
      userId,
      (data) => {
        setNotifications(data);
        setLoading(false);
      }
    );

    return () => {
      unsubscribe();
    };
  }, [userId]);

  const markAsRead = useCallback(async (notificationId: string) => {
    try {
      await notificationService.markAsRead(notificationId);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to mark as read");
    }
  }, []);

  const markAllAsRead = useCallback(async () => {
    try {
      await notificationService.markAllAsRead(userId);
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Failed to mark all as read"
      );
    }
  }, [userId]);

  const unreadCount = notifications.filter((n) => !n.read).length;
  const unreadNotifications = notifications.filter((n) => !n.read);
  const readNotifications = notifications.filter((n) => n.read);

  return {
    notifications,
    unreadNotifications,
    readNotifications,
    unreadCount,
    loading,
    error,
    markAsRead,
    markAllAsRead,
  };
}

// Hook for notification preferences
export function useNotificationPreferences(userId: string) {
  const [preferences, setPreferences] =
    useState<NotificationPreferences | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  const fetchPreferences = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const prefs = await notificationService.getNotificationPreferences(
        userId
      );
      setPreferences(prefs);
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Failed to fetch preferences"
      );
    } finally {
      setLoading(false);
    }
  }, [userId]);

  useEffect(() => {
    if (userId) {
      fetchPreferences();
    }
  }, [userId, fetchPreferences]);

  const updatePreferences = useCallback(
    async (newPreferences: Partial<NotificationPreferences>) => {
      if (!preferences) return;

      try {
        setSaving(true);
        setError(null);

        const updatedPreferences = { ...preferences, ...newPreferences };
        await notificationService.updateNotificationPreferences(
          updatedPreferences
        );
        setPreferences(updatedPreferences);
      } catch (err) {
        setError(
          err instanceof Error ? err.message : "Failed to update preferences"
        );
      } finally {
        setSaving(false);
      }
    },
    [preferences]
  );

  return {
    preferences,
    loading,
    error,
    saving,
    updatePreferences,
    refresh: fetchPreferences,
  };
}

// Hook for creating notifications
export function useNotificationCreator() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const createNotification = useCallback(
    async (notification: Omit<Notification, "id" | "createdAt" | "read">) => {
      try {
        setLoading(true);
        setError(null);
        const id = await notificationService.createNotification(notification);
        return id;
      } catch (err) {
        setError(
          err instanceof Error ? err.message : "Failed to create notification"
        );
        throw err;
      } finally {
        setLoading(false);
      }
    },
    []
  );

  const sendEmergencyAlert = useCallback(
    async (
      emergencyId: string,
      type: string,
      location: string,
      priority: "high" | "critical" = "critical"
    ) => {
      try {
        setLoading(true);
        setError(null);
        await notificationService.sendEmergencyAlert(
          emergencyId,
          type,
          location,
          priority
        );
      } catch (err) {
        setError(
          err instanceof Error ? err.message : "Failed to send emergency alert"
        );
        throw err;
      } finally {
        setLoading(false);
      }
    },
    []
  );

  const sendStatusUpdate = useCallback(
    async (
      emergencyId: string,
      oldStatus: string,
      newStatus: string,
      userId?: string
    ) => {
      try {
        setLoading(true);
        setError(null);
        await notificationService.sendStatusUpdateNotification(
          emergencyId,
          oldStatus,
          newStatus,
          userId
        );
      } catch (err) {
        setError(
          err instanceof Error ? err.message : "Failed to send status update"
        );
        throw err;
      } finally {
        setLoading(false);
      }
    },
    []
  );

  const sendResponderAssignment = useCallback(
    async (
      emergencyId: string,
      responderIds: string[],
      emergencyType: string,
      location: string
    ) => {
      try {
        setLoading(true);
        setError(null);
        await notificationService.sendResponderAssignmentNotification(
          emergencyId,
          responderIds,
          emergencyType,
          location
        );
      } catch (err) {
        setError(
          err instanceof Error
            ? err.message
            : "Failed to send assignment notification"
        );
        throw err;
      } finally {
        setLoading(false);
      }
    },
    []
  );

  const sendMaintenanceAlert = useCallback(
    async (title: string, message: string, scheduledTime: Date) => {
      try {
        setLoading(true);
        setError(null);
        await notificationService.sendSystemMaintenanceNotification(
          title,
          message,
          scheduledTime
        );
      } catch (err) {
        setError(
          err instanceof Error
            ? err.message
            : "Failed to send maintenance alert"
        );
        throw err;
      } finally {
        setLoading(false);
      }
    },
    []
  );

  return {
    loading,
    error,
    createNotification,
    sendEmergencyAlert,
    sendStatusUpdate,
    sendResponderAssignment,
    sendMaintenanceAlert,
  };
}

// Hook for notification statistics
export function useNotificationStats(userId: string) {
  const { notifications, loading } = useNotifications(userId);

  const stats = {
    total: notifications.length,
    unread: notifications.filter((n) => !n.read).length,
    byType: notifications.reduce((acc, notification) => {
      acc[notification.type] = (acc[notification.type] || 0) + 1;
      return acc;
    }, {} as Record<string, number>),
    byPriority: notifications.reduce((acc, notification) => {
      acc[notification.priority] = (acc[notification.priority] || 0) + 1;
      return acc;
    }, {} as Record<string, number>),
    recent: notifications.slice(0, 5),
    todayCount: notifications.filter((n) => {
      const today = new Date();
      const notificationDate = new Date(n.createdAt);
      return notificationDate.toDateString() === today.toDateString();
    }).length,
  };

  return { stats, loading };
}

// Hook for real-time notification badge
export function useNotificationBadge(userId: string) {
  const { unreadCount, loading } = useNotifications(userId);

  return {
    count: unreadCount,
    hasUnread: unreadCount > 0,
    loading,
    displayCount: unreadCount > 99 ? "99+" : unreadCount.toString(),
  };
}
