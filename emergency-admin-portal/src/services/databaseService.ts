import {
  collection,
  doc,
  addDoc,
  updateDoc,
  deleteDoc,
  getDoc,
  getDocs,
  query,
  where,
  orderBy,
  limit,
  onSnapshot,
  Timestamp,
  writeBatch,
  increment,
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import { Emergency, EmergencyStatus } from "@/types/emergency";
import { User, UserRole, UserStatus } from "@/types/user";

export class DatabaseService {
  private static instance: DatabaseService;

  static getInstance(): DatabaseService {
    if (!DatabaseService.instance) {
      DatabaseService.instance = new DatabaseService();
    }
    return DatabaseService.instance;
  }

  // Emergency Management
  async createEmergency(emergency: Omit<Emergency, "id" | "createdAt" | "updatedAt">): Promise<string> {
    try {
      const docRef = await addDoc(collection(db, "emergencies"), {
        ...emergency,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      });

      // Log activity
      await this.logEmergencyActivity(docRef.id, "new_emergency", "Emergency reported", emergency as Emergency);

      return docRef.id;
    } catch (error) {
      console.error("Error creating emergency:", error);
      throw error;
    }
  }

  async updateEmergency(id: string, updates: Partial<Emergency>): Promise<void> {
    try {
      const emergencyRef = doc(db, "emergencies", id);
      await updateDoc(emergencyRef, {
        ...updates,
        updatedAt: Timestamp.now(),
      });

      // Log status changes
      if (updates.status) {
        const emergencyDoc = await getDoc(emergencyRef);
        if (emergencyDoc.exists()) {
          const emergency = { id: emergencyDoc.id, ...emergencyDoc.data() } as Emergency;
          await this.logEmergencyActivity(
            id,
            "status_change",
            `Status changed to ${updates.status}`,
            emergency
          );
        }
      }
    } catch (error) {
      console.error("Error updating emergency:", error);
      throw error;
    }
  }

  async deleteEmergency(id: string): Promise<void> {
    try {
      await deleteDoc(doc(db, "emergencies", id));
    } catch (error) {
      console.error("Error deleting emergency:", error);
      throw error;
    }
  }

  async getEmergency(id: string): Promise<Emergency | null> {
    try {
      const docSnap = await getDoc(doc(db, "emergencies", id));
      if (docSnap.exists()) {
        const data = docSnap.data();
        return {
          id: docSnap.id,
          ...data,
          createdAt: data.createdAt?.toDate() || new Date(),
          updatedAt: data.updatedAt?.toDate() || new Date(),
        } as Emergency;
      }
      return null;
    } catch (error) {
      console.error("Error getting emergency:", error);
      throw error;
    }
  }

  async getEmergencies(filters?: {
    status?: EmergencyStatus[];
    type?: string[];
    limit?: number;
  }): Promise<Emergency[]> {
    try {
      let q = query(collection(db, "emergencies"), orderBy("createdAt", "desc"));

      if (filters?.status) {
        q = query(q, where("status", "in", filters.status));
      }

      if (filters?.type) {
        q = query(q, where("type", "in", filters.type));
      }

      if (filters?.limit) {
        q = query(q, limit(filters.limit));
      }

      const snapshot = await getDocs(q);
      const emergencies: Emergency[] = [];

      snapshot.forEach((doc) => {
        const data = doc.data();
        emergencies.push({
          id: doc.id,
          ...data,
          createdAt: data.createdAt?.toDate() || new Date(),
          updatedAt: data.updatedAt?.toDate() || new Date(),
        } as Emergency);
      });

      return emergencies;
    } catch (error) {
      console.error("Error getting emergencies:", error);
      throw error;
    }
  }

  // User Management
  async createUser(user: Omit<User, "id" | "createdAt" | "updatedAt">): Promise<string> {
    try {
      const docRef = await addDoc(collection(db, "users"), {
        ...user,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
        lastSeen: Timestamp.now(),
        lastActive: Timestamp.now(),
      });

      return docRef.id;
    } catch (error) {
      console.error("Error creating user:", error);
      throw error;
    }
  }

  async updateUser(id: string, updates: Partial<User>): Promise<void> {
    try {
      const userRef = doc(db, "users", id);
      await updateDoc(userRef, {
        ...updates,
        updatedAt: Timestamp.now(),
        ...(updates.isOnline !== undefined && { lastSeen: Timestamp.now() }),
      });
    } catch (error) {
      console.error("Error updating user:", error);
      throw error;
    }
  }

  async deleteUser(id: string): Promise<void> {
    try {
      await deleteDoc(doc(db, "users", id));
    } catch (error) {
      console.error("Error deleting user:", error);
      throw error;
    }
  }

  async getUser(id: string): Promise<User | null> {
    try {
      const docSnap = await getDoc(doc(db, "users", id));
      if (docSnap.exists()) {
        const data = docSnap.data();
        return {
          id: docSnap.id,
          ...data,
          createdAt: data.createdAt?.toDate() || new Date(),
          updatedAt: data.updatedAt?.toDate() || new Date(),
          lastSeen: data.lastSeen?.toDate() || new Date(),
          lastActive: data.lastActive?.toDate() || new Date(),
        } as User;
      }
      return null;
    } catch (error) {
      console.error("Error getting user:", error);
      throw error;
    }
  }

  async getUsers(filters?: {
    role?: UserRole[];
    status?: UserStatus[];
    limit?: number;
  }): Promise<User[]> {
    try {
      let q = query(collection(db, "users"), orderBy("createdAt", "desc"));

      if (filters?.role) {
        q = query(q, where("role", "in", filters.role));
      }

      if (filters?.status) {
        q = query(q, where("status", "in", filters.status));
      }

      if (filters?.limit) {
        q = query(q, limit(filters.limit));
      }

      const snapshot = await getDocs(q);
      const users: User[] = [];

      snapshot.forEach((doc) => {
        const data = doc.data();
        users.push({
          id: doc.id,
          ...data,
          createdAt: data.createdAt?.toDate() || new Date(),
          updatedAt: data.updatedAt?.toDate() || new Date(),
          lastSeen: data.lastSeen?.toDate() || new Date(),
          lastActive: data.lastActive?.toDate() || new Date(),
        } as User);
      });

      return users;
    } catch (error) {
      console.error("Error getting users:", error);
      throw error;
    }
  }

  // Responder Assignment
  async assignResponders(emergencyId: string, responderIds: string[]): Promise<void> {
    try {
      const batch = writeBatch(db);

      // Update emergency with assigned responders
      const emergencyRef = doc(db, "emergencies", emergencyId);
      batch.update(emergencyRef, {
        assignedResponders: responderIds,
        status: EmergencyStatus.DISPATCHED,
        updatedAt: Timestamp.now(),
      });

      // Update responder status
      responderIds.forEach((responderId) => {
        const responderRef = doc(db, "users", responderId);
        batch.update(responderRef, {
          currentAssignment: emergencyId,
          status: UserStatus.ACTIVE,
          updatedAt: Timestamp.now(),
        });
      });

      await batch.commit();

      // Log activity
      const emergency = await this.getEmergency(emergencyId);
      if (emergency) {
        await this.logEmergencyActivity(
          emergencyId,
          "assignment",
          `${responderIds.length} responder(s) assigned`,
          emergency
        );
      }
    } catch (error) {
      console.error("Error assigning responders:", error);
      throw error;
    }
  }

  // Activity Logging
  async logEmergencyActivity(
    emergencyId: string,
    type: "new_emergency" | "status_change" | "assignment" | "resolved",
    message: string,
    emergency: Emergency
  ): Promise<void> {
    try {
      await addDoc(collection(db, "emergency_timeline"), {
        emergencyId,
        type,
        message,
        emergency: {
          id: emergency.id,
          type: emergency.type,
          status: emergency.status,
          location: emergency.location,
        },
        timestamp: Timestamp.now(),
      });
    } catch (error) {
      console.error("Error logging emergency activity:", error);
      throw error;
    }
  }

  // Statistics and Analytics
  async getEmergencyStats(dateRange?: { start: Date; end: Date }) {
    try {
      let q = query(collection(db, "emergencies"));

      if (dateRange) {
        q = query(
          q,
          where("createdAt", ">=", Timestamp.fromDate(dateRange.start)),
          where("createdAt", "<=", Timestamp.fromDate(dateRange.end))
        );
      }

      const snapshot = await getDocs(q);
      const emergencies: Emergency[] = [];

      snapshot.forEach((doc) => {
        const data = doc.data();
        emergencies.push({
          id: doc.id,
          ...data,
          createdAt: data.createdAt?.toDate() || new Date(),
          updatedAt: data.updatedAt?.toDate() || new Date(),
        } as Emergency);
      });

      return {
        total: emergencies.length,
        byStatus: emergencies.reduce((acc, e) => {
          acc[e.status] = (acc[e.status] || 0) + 1;
          return acc;
        }, {} as Record<string, number>),
        byType: emergencies.reduce((acc, e) => {
          acc[e.type] = (acc[e.type] || 0) + 1;
          return acc;
        }, {} as Record<string, number>),
        byPriority: emergencies.reduce((acc, e) => {
          acc[e.priority] = (acc[e.priority] || 0) + 1;
          return acc;
        }, {} as Record<string, number>),
        averageResponseTime: emergencies
          .filter((e) => e.responseTime)
          .reduce((sum, e) => sum + (e.responseTime || 0), 0) / emergencies.length || 0,
      };
    } catch (error) {
      console.error("Error getting emergency stats:", error);
      throw error;
    }
  }

  // Real-time subscriptions
  subscribeToEmergencies(
    callback: (emergencies: Emergency[]) => void,
    filters?: { status?: EmergencyStatus[]; limit?: number }
  ): () => void {
    let q = query(collection(db, "emergencies"), orderBy("createdAt", "desc"));

    if (filters?.status) {
      q = query(q, where("status", "in", filters.status));
    }

    if (filters?.limit) {
      q = query(q, limit(filters.limit));
    }

    return onSnapshot(q, (snapshot) => {
      const emergencies: Emergency[] = [];
      snapshot.forEach((doc) => {
        const data = doc.data();
        emergencies.push({
          id: doc.id,
          ...data,
          createdAt: data.createdAt?.toDate() || new Date(),
          updatedAt: data.updatedAt?.toDate() || new Date(),
        } as Emergency);
      });
      callback(emergencies);
    });
  }

  subscribeToUsers(
    callback: (users: User[]) => void,
    filters?: { role?: UserRole[]; limit?: number }
  ): () => void {
    let q = query(collection(db, "users"), orderBy("lastSeen", "desc"));

    if (filters?.role) {
      q = query(q, where("role", "in", filters.role));
    }

    if (filters?.limit) {
      q = query(q, limit(filters.limit));
    }

    return onSnapshot(q, (snapshot) => {
      const users: User[] = [];
      snapshot.forEach((doc) => {
        const data = doc.data();
        users.push({
          id: doc.id,
          ...data,
          createdAt: data.createdAt?.toDate() || new Date(),
          updatedAt: data.updatedAt?.toDate() || new Date(),
          lastSeen: data.lastSeen?.toDate() || new Date(),
          lastActive: data.lastActive?.toDate() || new Date(),
        } as User);
      });
      callback(users);
    });
  }

  // Batch operations
  async batchUpdateEmergencies(updates: Array<{ id: string; data: Partial<Emergency> }>): Promise<void> {
    try {
      const batch = writeBatch(db);

      updates.forEach(({ id, data }) => {
        const docRef = doc(db, "emergencies", id);
        batch.update(docRef, {
          ...data,
          updatedAt: Timestamp.now(),
        });
      });

      await batch.commit();
    } catch (error) {
      console.error("Error batch updating emergencies:", error);
      throw error;
    }
  }

  async batchUpdateUsers(updates: Array<{ id: string; data: Partial<User> }>): Promise<void> {
    try {
      const batch = writeBatch(db);

      updates.forEach(({ id, data }) => {
        const docRef = doc(db, "users", id);
        batch.update(docRef, {
          ...data,
          updatedAt: Timestamp.now(),
        });
      });

      await batch.commit();
    } catch (error) {
      console.error("Error batch updating users:", error);
      throw error;
    }
  }
}

export const databaseService = DatabaseService.getInstance();
