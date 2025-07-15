import {
  collection,
  query,
  onSnapshot,
  orderBy,
  limit,
  where,
  Timestamp,
  doc,
  updateDoc,
  addDoc,
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import { type Emergency, EmergencyStatus } from "@/types/emergency";
import { type User } from "@/types/user";

export interface SystemMetrics {
  activeEmergencies: number;
  totalResponders: number;
  onlineResponders: number;
  averageResponseTime: number;
  systemStatus: "online" | "degraded" | "offline";
  lastUpdated: Date;
}

export interface EmergencyUpdate {
  id: string;
  type: "status_change" | "assignment" | "new_emergency" | "resolved";
  emergency: Emergency;
  timestamp: Date;
  message: string;
}

export class RealtimeService {
  private static instance: RealtimeService;
  private listeners: Map<string, () => void> = new Map();

  static getInstance(): RealtimeService {
    if (!RealtimeService.instance) {
      RealtimeService.instance = new RealtimeService();
    }
    return RealtimeService.instance;
  }

  // Real-time emergency monitoring
  subscribeToEmergencies(
    callback: (emergencies: Emergency[]) => void,
    filters?: {
      status?: EmergencyStatus[];
      limit?: number;
    }
  ): () => void {
    // Use 'timestamp' field to match mobile app data structure
    let q = query(collection(db, "emergencies"), orderBy("timestamp", "desc"));

    if (filters?.status) {
      // Map admin portal status enum to mobile app status values
      const mobileStatuses = filters.status.map((status) => {
        switch (status) {
          case EmergencyStatus.REPORTED:
            return "pending";
          case EmergencyStatus.DISPATCHED:
            return "dispatched";
          case EmergencyStatus.IN_PROGRESS:
            return "in_progress";
          case EmergencyStatus.RESOLVED:
            return "resolved";
          default:
            return status.toLowerCase();
        }
      });
      q = query(q, where("status", "in", mobileStatuses));
    }

    if (filters?.limit) {
      q = query(q, limit(filters.limit));
    }

    const unsubscribe = onSnapshot(
      q,
      (snapshot) => {
        const emergencies: Emergency[] = [];
        snapshot.forEach((doc) => {
          const data = doc.data();

          // Map mobile app data structure to admin portal structure
          const emergency: Emergency = {
            id: doc.id,
            type: data.type || "unknown",
            status: this.mapMobileStatusToAdminStatus(data.status || "pending"),
            priority: data.priority || "medium",
            title: data.title || `${data.type || "Emergency"} Report`,
            description: data.description || "",
            location: {
              latitude: data.latitude || 0,
              longitude: data.longitude || 0,
              address: data.address || "",
              city: data.city || "",
              state: data.state || "",
            },
            reportedBy: {
              userId: data.userId || "",
              name: data.userName || "Unknown",
              phone: data.userPhone || "",
              email: data.userEmail || "",
            },
            assignedResponders: data.responderIds || [],
            timeline: [], // Timeline will be populated separately if needed
            imageUrls: data.images || [],
            createdAt: data.timestamp?.toDate() || new Date(),
            updatedAt:
              data.updatedAt?.toDate() ||
              data.timestamp?.toDate() ||
              new Date(),
            resolvedAt: data.resolvedAt?.toDate(),
            estimatedResponseTime: data.estimatedResponseTime || 0,
            actualResponseTime: data.actualResponseTime || 0,
          };

          emergencies.push(emergency);
        });

        callback(emergencies);
      },
      (error) => {
        console.error("Error in emergency subscription:", error);
      }
    );

    const listenerId = `emergencies_${Date.now()}`;
    this.listeners.set(listenerId, unsubscribe);
    return unsubscribe;
  }

  // Helper method to map mobile app status to admin portal status
  private mapMobileStatusToAdminStatus(mobileStatus: string): EmergencyStatus {
    switch (mobileStatus.toLowerCase()) {
      case "pending":
        return EmergencyStatus.REPORTED;
      case "dispatched":
        return EmergencyStatus.DISPATCHED;
      case "in_progress":
        return EmergencyStatus.IN_PROGRESS;
      case "resolved":
        return EmergencyStatus.RESOLVED;
      default:
        return EmergencyStatus.REPORTED;
    }
  }

  // Real-time responder monitoring
  subscribeToResponders(callback: (responders: User[]) => void): () => void {
    const q = query(
      collection(db, "users"),
      where("role", "==", "responder"),
      orderBy("lastSeen", "desc")
    );

    const unsubscribe = onSnapshot(
      q,
      (snapshot) => {
        const responders: User[] = [];
        snapshot.forEach((doc) => {
          responders.push({
            id: doc.id,
            ...doc.data(),
            createdAt: doc.data().createdAt?.toDate() || new Date(),
            updatedAt: doc.data().updatedAt?.toDate() || new Date(),
            lastSeen: doc.data().lastSeen?.toDate() || new Date(),
            lastActive: doc.data().lastActive?.toDate() || new Date(),
          } as User);
        });
        callback(responders);
      },
      (error) => {
        console.error("Error in responder subscription:", error);
      }
    );

    const listenerId = `responders_${Date.now()}`;
    this.listeners.set(listenerId, unsubscribe);
    return unsubscribe;
  }

  // Real-time system metrics
  subscribeToSystemMetrics(
    callback: (metrics: SystemMetrics) => void
  ): () => void {
    // Store the latest data from both subscriptions
    let latestEmergencyData: {
      activeEmergencies: number;
      allEmergencies: Emergency[];
    } | null = null;
    let latestResponderData: {
      totalResponders: number;
      onlineResponders: number;
    } | null = null;

    // Subscribe to emergencies
    const emergencyUnsubscribe = this.subscribeToEmergencies((emergencies) => {
      const activeEmergencies = emergencies.filter(
        (e) => e.status !== EmergencyStatus.RESOLVED
      ).length;

      latestEmergencyData = { activeEmergencies, allEmergencies: emergencies };

      // Calculate metrics if we have both data sets
      if (latestResponderData) {
        this.calculateSystemMetrics(
          latestEmergencyData,
          latestResponderData,
          callback
        );
      }
    });

    // Subscribe to responders
    const responderUnsubscribe = this.subscribeToResponders((responders) => {
      const totalResponders = responders.length;
      const onlineResponders = responders.filter((r) => r.isOnline).length;

      latestResponderData = { totalResponders, onlineResponders };

      // Calculate metrics if we have both data sets
      if (latestEmergencyData) {
        this.calculateSystemMetrics(
          latestEmergencyData,
          latestResponderData,
          callback
        );
      }
    });

    const listenerId = `system_metrics_${Date.now()}`;
    this.listeners.set(listenerId, () => {
      emergencyUnsubscribe();
      responderUnsubscribe();
    });

    return () => {
      emergencyUnsubscribe();
      responderUnsubscribe();
    };
  }

  private calculateSystemMetrics(
    emergencyData: { activeEmergencies: number; allEmergencies: Emergency[] },
    responderData: { totalResponders: number; onlineResponders: number },
    callback: (metrics: SystemMetrics) => void
  ) {
    try {
      // Calculate average response time from resolved emergencies with actual response times
      const resolvedEmergencies = emergencyData.allEmergencies.filter(
        (e) =>
          e.status === EmergencyStatus.RESOLVED &&
          e.actualResponseTime &&
          e.actualResponseTime > 0
      );

      let totalResponseTime = 0;
      let count = 0;

      resolvedEmergencies.forEach((emergency) => {
        if (emergency.actualResponseTime) {
          totalResponseTime += emergency.actualResponseTime;
          count++;
        }
      });

      const averageResponseTime = count > 0 ? totalResponseTime / count : 0;

      const metrics: SystemMetrics = {
        activeEmergencies: emergencyData.activeEmergencies,
        totalResponders: responderData.totalResponders,
        onlineResponders: responderData.onlineResponders,
        averageResponseTime,
        systemStatus: this.determineSystemStatus(
          responderData.onlineResponders,
          responderData.totalResponders
        ),
        lastUpdated: new Date(),
      };

      callback(metrics);
    } catch (error) {
      console.error("Error calculating system metrics:", error);
    }
  }

  private determineSystemStatus(
    onlineResponders: number,
    totalResponders: number
  ): "online" | "degraded" | "offline" {
    if (totalResponders === 0) return "offline";
    const onlinePercentage = (onlineResponders / totalResponders) * 100;

    if (onlinePercentage >= 70) return "online";
    if (onlinePercentage >= 30) return "degraded";
    return "offline";
  }

  // Emergency activity feed
  subscribeToEmergencyUpdates(
    callback: (updates: EmergencyUpdate[]) => void,
    limitCount: number = 20
  ): () => void {
    const q = query(
      collection(db, "emergency_timeline"),
      orderBy("timestamp", "desc"),
      limit(limitCount)
    );

    const unsubscribe = onSnapshot(
      q,
      (snapshot) => {
        const updates: EmergencyUpdate[] = [];
        snapshot.forEach((doc) => {
          const data = doc.data();
          updates.push({
            id: doc.id,
            type: data.type,
            emergency: data.emergency,
            timestamp: data.timestamp?.toDate() || new Date(),
            message: data.message,
          });
        });
        callback(updates);
      },
      (error) => {
        console.error("Error in emergency updates subscription:", error);
      }
    );

    const listenerId = `updates_${Date.now()}`;
    this.listeners.set(listenerId, unsubscribe);
    return unsubscribe;
  }

  // Update responder status
  async updateResponderStatus(
    responderId: string,
    isOnline: boolean,
    location?: { latitude: number; longitude: number }
  ): Promise<void> {
    try {
      const responderRef = doc(db, "users", responderId);
      await updateDoc(responderRef, {
        isOnline,
        lastSeen: Timestamp.now(),
        lastActive: Timestamp.now(),
        ...(location && { location }),
      });
    } catch (error) {
      console.error("Error updating responder status:", error);
      throw error;
    }
  }

  // Log emergency activity
  async logEmergencyActivity(
    emergencyId: string,
    type: EmergencyUpdate["type"],
    message: string,
    emergency: Emergency
  ): Promise<void> {
    try {
      await addDoc(collection(db, "emergency_timeline"), {
        emergencyId,
        type,
        message,
        emergency,
        timestamp: Timestamp.now(),
      });
    } catch (error) {
      console.error("Error logging emergency activity:", error);
      throw error;
    }
  }

  // Cleanup all listeners
  cleanup(): void {
    this.listeners.forEach((unsubscribe) => {
      unsubscribe();
    });
    this.listeners.clear();
  }
}

export const realtimeService = RealtimeService.getInstance();
