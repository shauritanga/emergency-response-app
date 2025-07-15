import {
  collection,
  doc,
  getDocs,
  getDoc,
  addDoc,
  updateDoc,
  deleteDoc,
  query,
  where,
  orderBy,
  limit,
  onSnapshot,
  Timestamp,
  QueryConstraint,
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import {
  type Emergency,
  type EmergencyFilters,
  type EmergencyStats,
  EmergencyStatus,
  type EmergencyTimelineEvent,
} from "@/types";

export class EmergencyService {
  private static instance: EmergencyService;
  private readonly collectionName = "emergencies";
  private readonly timelineCollectionName = "emergency_timeline";

  static getInstance(): EmergencyService {
    if (!EmergencyService.instance) {
      EmergencyService.instance = new EmergencyService();
    }
    return EmergencyService.instance;
  }

  // Get all emergencies with optional filters
  async getEmergencies(filters?: EmergencyFilters): Promise<Emergency[]> {
    try {
      const constraints: QueryConstraint[] = [];

      // Order by timestamp (mobile app's date field)
      constraints.push(orderBy("timestamp", "desc"));

      const q = query(collection(db, this.collectionName), ...constraints);
      const querySnapshot = await getDocs(q);

      let emergencies = querySnapshot.docs.map((doc) => {
        const data = doc.data();

        // Map your mobile app's data structure to admin portal structure
        return {
          id: doc.id,
          title: data.description || "Emergency Report",
          description: data.description || "",
          type: data.type?.toLowerCase() || "other",
          status: data.status?.toLowerCase().replace(" ", "_") || "reported",
          priority: "medium" as any,
          location: {
            latitude: data.latitude || 0,
            longitude: data.longitude || 0,
            address: `${data.latitude || 0}, ${data.longitude || 0}`,
          },
          reportedBy: {
            userId: data.userId || "",
            name: "User " + (data.userId?.slice(-4) || "Unknown"),
          },
          assignedResponders: data.responderIds || [],
          timeline: [],
          createdAt: data.timestamp?.toDate() || new Date(),
          updatedAt: data.timestamp?.toDate() || new Date(),
          imageUrls: data.imageUrls || [],
          responderIds: data.responderIds || [],
        };
      });

      // Apply filters in memory
      if (filters?.status && filters.status.length > 0) {
        emergencies = emergencies.filter((e) =>
          filters.status!.includes(e.status)
        );
      }

      if (filters?.type && filters.type.length > 0) {
        emergencies = emergencies.filter((e) => filters.type!.includes(e.type));
      }

      if (filters?.priority && filters.priority.length > 0) {
        emergencies = emergencies.filter((e) =>
          filters.priority!.includes(e.priority)
        );
      }

      if (filters?.dateRange) {
        emergencies = emergencies.filter(
          (e) =>
            e.createdAt >= filters.dateRange!.start &&
            e.createdAt <= filters.dateRange!.end
        );
      }

      return emergencies;
    } catch (error) {
      console.error("Error fetching emergencies:", error);
      throw new Error("Failed to fetch emergencies");
    }
  }

  // Get emergency by ID
  async getEmergencyById(id: string): Promise<Emergency | null> {
    try {
      const docRef = doc(db, this.collectionName, id);
      const docSnap = await getDoc(docRef);

      if (docSnap.exists()) {
        const data = docSnap.data();
        return {
          id: docSnap.id,
          ...data,
          createdAt: data.createdAt?.toDate(),
          updatedAt: data.updatedAt?.toDate(),
          resolvedAt: data.resolvedAt?.toDate(),
        } as Emergency;
      }

      return null;
    } catch (error) {
      console.error("Error fetching emergency:", error);
      throw new Error("Failed to fetch emergency");
    }
  }

  // Update emergency status
  async updateEmergencyStatus(
    id: string,
    status: EmergencyStatus,
    userId: string,
    userName: string
  ): Promise<void> {
    try {
      const docRef = doc(db, this.collectionName, id);
      const updateData: any = {
        status,
        updatedAt: Timestamp.now(),
      };

      if (status === EmergencyStatus.RESOLVED) {
        updateData.resolvedAt = Timestamp.now();
      }

      await updateDoc(docRef, updateData);

      // Add timeline event
      await this.addTimelineEvent({
        emergencyId: id,
        type: "status_update" as any,
        title: `Status updated to ${status}`,
        description: `Emergency status changed to ${status}`,
        userId,
        userName,
        userRole: "admin",
        timestamp: new Date(),
      });
    } catch (error) {
      console.error("Error updating emergency status:", error);

      // Provide more specific error messages
      if (error instanceof Error) {
        if (error.message.includes("not found")) {
          throw new Error("Emergency not found. It may have been deleted.");
        } else if (error.message.includes("permission-denied")) {
          throw new Error(
            "Permission denied. You don't have access to update this emergency."
          );
        } else if (error.message.includes("network-request-failed")) {
          throw new Error(
            "Network error. Please check your connection and try again."
          );
        }
      }

      throw new Error(
        `Failed to update emergency status: ${
          error instanceof Error ? error.message : "Unknown error"
        }`
      );
    }
  }

  // Assign responder to emergency
  async assignResponder(
    emergencyId: string,
    responderId: string,
    responderName: string,
    adminId: string,
    adminName: string
  ): Promise<void> {
    try {
      const docRef = doc(db, this.collectionName, emergencyId);
      const emergency = await this.getEmergencyById(emergencyId);

      if (!emergency) {
        throw new Error("Emergency not found");
      }

      const updatedResponders = [...emergency.assignedResponders];
      if (!updatedResponders.includes(responderId)) {
        updatedResponders.push(responderId);
      }

      await updateDoc(docRef, {
        assignedResponders: updatedResponders,
        updatedAt: Timestamp.now(),
      });

      // Add timeline event
      await this.addTimelineEvent({
        emergencyId,
        type: "responder_assigned" as any,
        title: `Responder assigned`,
        description: `${responderName} has been assigned to this emergency`,
        userId: adminId,
        userName: adminName,
        userRole: "admin",
        timestamp: new Date(),
      });
    } catch (error) {
      console.error("Error assigning responder:", error);
      throw new Error("Failed to assign responder");
    }
  }

  // Add timeline event
  async addTimelineEvent(
    event: Omit<EmergencyTimelineEvent, "id">
  ): Promise<void> {
    try {
      await addDoc(collection(db, this.timelineCollectionName), {
        ...event,
        timestamp: Timestamp.fromDate(event.timestamp),
      });
    } catch (error) {
      console.error("Error adding timeline event:", error);
      throw new Error("Failed to add timeline event");
    }
  }

  // Get emergency timeline
  async getEmergencyTimeline(
    emergencyId: string
  ): Promise<EmergencyTimelineEvent[]> {
    try {
      const q = query(
        collection(db, this.timelineCollectionName),
        where("emergencyId", "==", emergencyId),
        orderBy("timestamp", "desc")
      );

      const querySnapshot = await getDocs(q);
      return querySnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
        timestamp: doc.data().timestamp?.toDate(),
      })) as EmergencyTimelineEvent[];
    } catch (error) {
      console.error("Error fetching timeline:", error);
      throw new Error("Failed to fetch timeline");
    }
  }

  // Real-time subscription to emergencies
  subscribeToEmergencies(
    callback: (emergencies: Emergency[]) => void,
    filters?: EmergencyFilters
  ): () => void {
    const constraints: QueryConstraint[] = [];

    // Order by timestamp (your mobile app's date field)
    constraints.push(orderBy("timestamp", "desc"));
    constraints.push(limit(100)); // Get more to allow for filtering

    const q = query(collection(db, this.collectionName), ...constraints);

    return onSnapshot(
      q,
      (querySnapshot) => {
        let emergencies = querySnapshot.docs.map((doc) => {
          const data = doc.data();

          // Map your mobile app's data structure to admin portal structure
          return {
            id: doc.id,
            title: data.description || "Emergency Report", // Use description as title
            description: data.description || "",
            type: data.type?.toLowerCase() || "other", // Convert to lowercase
            status: data.status?.toLowerCase().replace(" ", "_") || "reported", // Convert "In Progress" to "in_progress"
            priority: "medium" as any, // Default priority since mobile app doesn't have this
            location: {
              latitude: data.latitude || 0,
              longitude: data.longitude || 0,
              address: `${data.latitude || 0}, ${data.longitude || 0}`, // Use coordinates as address
            },
            reportedBy: {
              userId: data.userId || "",
              name: "User " + (data.userId?.slice(-4) || "Unknown"), // Generate name from userId
            },
            assignedResponders: data.responderIds || [],
            timeline: [],
            createdAt: data.timestamp?.toDate() || new Date(),
            updatedAt: data.timestamp?.toDate() || new Date(),
            imageUrls: data.imageUrls || [],
            responderIds: data.responderIds || [],
          };
        });

        // Apply filters in memory
        if (filters?.status && filters.status.length > 0) {
          emergencies = emergencies.filter((e) =>
            filters.status!.includes(e.status)
          );
        }

        // Limit after filtering
        emergencies = emergencies.slice(0, 50);

        callback(emergencies);
      },
      (error) => {
        console.error("EmergencyService: Subscription error:", error);
      }
    );
  }

  // Get emergency statistics
  async getEmergencyStats(): Promise<EmergencyStats> {
    try {
      const emergencies = await this.getEmergencies();

      const stats: EmergencyStats = {
        total: emergencies.length,
        active: emergencies.filter(
          (e) =>
            e.status !== EmergencyStatus.RESOLVED &&
            e.status !== EmergencyStatus.CANCELLED
        ).length,
        resolved: emergencies.filter(
          (e) => e.status === EmergencyStatus.RESOLVED
        ).length,
        averageResponseTime: 0,
        byType: {} as any,
        byStatus: {} as any,
        byPriority: {} as any,
      };

      // Calculate average response time
      const resolvedEmergencies = emergencies.filter(
        (e) => e.actualResponseTime
      );
      if (resolvedEmergencies.length > 0) {
        stats.averageResponseTime =
          resolvedEmergencies.reduce(
            (sum, e) => sum + (e.actualResponseTime || 0),
            0
          ) / resolvedEmergencies.length;
      }

      // Group by type, status, priority
      emergencies.forEach((emergency) => {
        stats.byType[emergency.type] = (stats.byType[emergency.type] || 0) + 1;
        stats.byStatus[emergency.status] =
          (stats.byStatus[emergency.status] || 0) + 1;
        stats.byPriority[emergency.priority] =
          (stats.byPriority[emergency.priority] || 0) + 1;
      });

      return stats;
    } catch (error) {
      console.error("Error calculating emergency stats:", error);
      throw new Error("Failed to calculate emergency stats");
    }
  }
}
