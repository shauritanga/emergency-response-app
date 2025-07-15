import { useState, useEffect, useCallback } from "react";
import { type Emergency, EmergencyStatus } from "@/types/emergency";
import { type User } from "@/types/user";
import {
  realtimeService,
  type SystemMetrics,
  type EmergencyUpdate,
} from "@/services/realtimeService";

// Hook for real-time emergencies
export function useRealtimeEmergencies(filters?: {
  status?: EmergencyStatus[];
  limit?: number;
}) {
  const [emergencies, setEmergencies] = useState<Emergency[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setLoading(true);
    setError(null);

    const unsubscribe = realtimeService.subscribeToEmergencies(
      (data) => {
        setEmergencies(data);
        setLoading(false);
      },
      filters
    );

    return () => {
      unsubscribe();
    };
  }, [filters?.status?.join(","), filters?.limit]);

  return { emergencies, loading, error };
}

// Hook for real-time responders
export function useRealtimeResponders() {
  const [responders, setResponders] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setLoading(true);
    setError(null);

    const unsubscribe = realtimeService.subscribeToResponders((data) => {
      setResponders(data);
      setLoading(false);
    });

    return () => {
      unsubscribe();
    };
  }, []);

  const updateResponderStatus = useCallback(
    async (
      responderId: string,
      isOnline: boolean,
      location?: { latitude: number; longitude: number }
    ) => {
      try {
        await realtimeService.updateResponderStatus(
          responderId,
          isOnline,
          location
        );
      } catch (err) {
        setError(err instanceof Error ? err.message : "Failed to update status");
      }
    },
    []
  );

  return { responders, loading, error, updateResponderStatus };
}

// Hook for system metrics
export function useSystemMetrics() {
  const [metrics, setMetrics] = useState<SystemMetrics | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setLoading(true);
    setError(null);

    const unsubscribe = realtimeService.subscribeToSystemMetrics((data) => {
      setMetrics(data);
      setLoading(false);
    });

    return () => {
      unsubscribe();
    };
  }, []);

  return { metrics, loading, error };
}

// Hook for emergency activity feed
export function useEmergencyUpdates(limit: number = 20) {
  const [updates, setUpdates] = useState<EmergencyUpdate[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setLoading(true);
    setError(null);

    const unsubscribe = realtimeService.subscribeToEmergencyUpdates(
      (data) => {
        setUpdates(data);
        setLoading(false);
      },
      limit
    );

    return () => {
      unsubscribe();
    };
  }, [limit]);

  const logActivity = useCallback(
    async (
      emergencyId: string,
      type: EmergencyUpdate["type"],
      message: string,
      emergency: Emergency
    ) => {
      try {
        await realtimeService.logEmergencyActivity(
          emergencyId,
          type,
          message,
          emergency
        );
      } catch (err) {
        setError(err instanceof Error ? err.message : "Failed to log activity");
      }
    },
    []
  );

  return { updates, loading, error, logActivity };
}

// Hook for active emergencies count
export function useActiveEmergenciesCount() {
  const { emergencies, loading } = useRealtimeEmergencies({
    status: [
      EmergencyStatus.REPORTED,
      EmergencyStatus.DISPATCHED,
      EmergencyStatus.IN_PROGRESS,
    ],
  });

  return {
    count: emergencies.length,
    loading,
    emergencies,
  };
}

// Hook for online responders count
export function useOnlineRespondersCount() {
  const { responders, loading } = useRealtimeResponders();

  const onlineCount = responders.filter((r) => r.isOnline).length;
  const totalCount = responders.length;

  return {
    onlineCount,
    totalCount,
    percentage: totalCount > 0 ? (onlineCount / totalCount) * 100 : 0,
    loading,
    responders,
  };
}

// Hook for emergency statistics
export function useEmergencyStats() {
  const { emergencies, loading } = useRealtimeEmergencies();

  const stats = {
    total: emergencies.length,
    byStatus: emergencies.reduce((acc, emergency) => {
      acc[emergency.status] = (acc[emergency.status] || 0) + 1;
      return acc;
    }, {} as Record<string, number>),
    byType: emergencies.reduce((acc, emergency) => {
      acc[emergency.type] = (acc[emergency.type] || 0) + 1;
      return acc;
    }, {} as Record<string, number>),
    byPriority: emergencies.reduce((acc, emergency) => {
      acc[emergency.priority] = (acc[emergency.priority] || 0) + 1;
      return acc;
    }, {} as Record<string, number>),
  };

  return { stats, loading };
}

// Hook for recent activity
export function useRecentActivity(limit: number = 10) {
  const { updates, loading, error } = useEmergencyUpdates(limit);

  const recentActivity = updates.map((update) => ({
    id: update.id,
    type: update.type,
    message: update.message,
    timestamp: update.timestamp,
    emergency: {
      id: update.emergency.id,
      type: update.emergency.type,
      status: update.emergency.status,
      location: update.emergency.location,
    },
  }));

  return { recentActivity, loading, error };
}
