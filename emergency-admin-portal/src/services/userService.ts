import {
  collection,
  doc,
  getDocs,
  getDoc,
  addDoc,
  updateDoc,
  deleteDoc,
  query,
  limit,
  onSnapshot,
  Timestamp,
  setDoc,
} from "firebase/firestore";
import {
  createUserWithEmailAndPassword,
  sendPasswordResetEmail,
  updateProfile,
} from "firebase/auth";
import { db, auth } from "@/lib/firebase";
import {
  type User,
  type UserFilters,
  type UserStats,
  UserRole,
  UserStatus,
  type ResponderProfile,
} from "@/types";

export class UserService {
  private static instance: UserService;
  private readonly collectionName = "users";

  static getInstance(): UserService {
    if (!UserService.instance) {
      UserService.instance = new UserService();
    }
    return UserService.instance;
  }

  // Get all users with optional filters
  async getUsers(filters?: UserFilters): Promise<User[]> {
    try {
      const q = query(collection(db, this.collectionName));
      const querySnapshot = await getDocs(q);

      let users = querySnapshot.docs.map((doc) => {
        const data = doc.data();

        // Map mobile app user structure to admin portal structure
        return {
          id: doc.id,
          name: data.name || "Unknown User",
          email: data.email || "",
          role: data.role || "citizen",
          status: data.status || "active", // Default to active if not set
          phone: data.phone || "",
          avatar: data.photoURL || "",
          department: data.department || "",
          specializations: data.specializations || [],
          location: data.lastLocation
            ? {
                latitude: data.lastLocation.latitude || 0,
                longitude: data.lastLocation.longitude || 0,
                address: data.lastLocation.address || "",
                city: data.lastLocation.city || "",
                state: data.lastLocation.state || "",
              }
            : undefined,
          isOnline: data.isOnline || false,
          lastSeen: data.lastSeen?.toDate() || new Date(),
          lastActive: data.lastSeen?.toDate() || new Date(),
          createdAt: data.createdAt?.toDate() || new Date(),
          updatedAt: data.updatedAt?.toDate() || new Date(),
          metadata: {
            deviceToken: data.deviceToken,
            notificationPreferences: data.notificationPreferences,
          },
        } as User;
      });

      // Apply filters in memory
      if (filters?.role && filters.role.length > 0) {
        users = users.filter((u) => filters.role!.includes(u.role));
      }

      if (filters?.status && filters.status.length > 0) {
        users = users.filter((u) => filters.status!.includes(u.status));
      }

      if (filters?.department && filters.department.length > 0) {
        users = users.filter(
          (u) => u.department && filters.department!.includes(u.department)
        );
      }

      if (filters?.isOnline !== undefined) {
        users = users.filter((u) => u.isOnline === filters.isOnline);
      }

      if (filters?.searchQuery) {
        const query = filters.searchQuery.toLowerCase();
        users = users.filter(
          (u) =>
            u.name.toLowerCase().includes(query) ||
            u.email.toLowerCase().includes(query) ||
            (u.department && u.department.toLowerCase().includes(query))
        );
      }

      return users;
    } catch (error) {
      console.error("Error fetching users:", error);
      throw new Error("Failed to fetch users");
    }
  }

  // Get user by ID
  async getUserById(id: string): Promise<User | null> {
    try {
      const docRef = doc(db, this.collectionName, id);
      const docSnap = await getDoc(docRef);

      if (docSnap.exists()) {
        const data = docSnap.data();

        // Map mobile app user structure to admin portal structure
        return {
          id: docSnap.id,
          name: data.name || "Unknown User",
          email: data.email || "",
          role: data.role || "citizen",
          status: data.status || "active",
          phone: data.phone || "",
          avatar: data.photoURL || "",
          department: data.department || "",
          specializations: data.specializations || [],
          location: data.lastLocation
            ? {
                latitude: data.lastLocation.latitude || 0,
                longitude: data.lastLocation.longitude || 0,
                address: data.lastLocation.address || "",
                city: data.lastLocation.city || "",
                state: data.lastLocation.state || "",
              }
            : undefined,
          isOnline: data.isOnline || false,
          lastSeen: data.lastSeen?.toDate() || new Date(),
          lastActive: data.lastSeen?.toDate() || new Date(),
          createdAt: data.createdAt?.toDate() || new Date(),
          updatedAt: data.updatedAt?.toDate() || new Date(),
          metadata: {
            deviceToken: data.deviceToken,
            notificationPreferences: data.notificationPreferences,
          },
        } as User;
      }

      return null;
    } catch (error) {
      console.error("Error fetching user:", error);
      throw new Error("Failed to fetch user");
    }
  }

  // Get responders only
  async getResponders(): Promise<ResponderProfile[]> {
    try {
      const users = await this.getUsers({ role: [UserRole.RESPONDER] });
      return users as ResponderProfile[];
    } catch (error) {
      console.error("Error fetching responders:", error);
      throw new Error("Failed to fetch responders");
    }
  }

  // Update user status
  async updateUserStatus(id: string, status: UserStatus): Promise<void> {
    try {
      const docRef = doc(db, this.collectionName, id);
      await updateDoc(docRef, {
        status,
        updatedAt: Timestamp.now(),
      });
    } catch (error) {
      console.error("Error updating user status:", error);
      throw new Error("Failed to update user status");
    }
  }

  // Update user role
  async updateUserRole(id: string, role: UserRole): Promise<void> {
    try {
      const docRef = doc(db, this.collectionName, id);
      await updateDoc(docRef, {
        role,
        updatedAt: Timestamp.now(),
      });
    } catch (error) {
      console.error("Error updating user role:", error);
      throw new Error("Failed to update user role");
    }
  }

  // Create new user with Firebase Auth and Firestore
  async createUser(
    userData: Omit<User, "id" | "createdAt" | "updatedAt"> & {
      password?: string;
      sendPasswordReset?: boolean;
    }
  ): Promise<string> {
    try {
      console.log("Creating user with data:", userData);

      // Generate a temporary password if none provided
      const tempPassword = userData.password || this.generateTempPassword();

      // Step 1: Create Firebase Auth user
      console.log("Creating Firebase Auth user...");
      const userCredential = await createUserWithEmailAndPassword(
        auth,
        userData.email,
        tempPassword
      );

      const firebaseUser = userCredential.user;
      console.log("Firebase Auth user created:", firebaseUser.uid);

      // Step 2: Update Firebase Auth profile
      await updateProfile(firebaseUser, {
        displayName: userData.name,
      });

      // Step 3: Create comprehensive user document in Firestore
      const now = Timestamp.now();
      const userDoc = {
        email: userData.email,
        name: userData.name,
        role: userData.role,
        status: userData.status || UserStatus.ACTIVE,
        phone: userData.phone || "",
        avatar: userData.avatar || "",
        department: userData.department || "",
        specializations: userData.specializations || [],
        location: userData.location || null,
        isOnline: userData.isOnline || false,
        lastSeen: now,
        lastActive: now,
        createdAt: now,
        updatedAt: now,
        metadata: {
          ...userData.metadata,
          createdBy: "admin",
          createdVia: "admin-portal",
          tempPassword: !userData.password, // Flag if temp password was used
        },
      };

      console.log("Creating Firestore document...");
      await setDoc(doc(db, this.collectionName, firebaseUser.uid), userDoc);

      // Step 4: Send password reset email if using temp password or requested
      if (!userData.password || userData.sendPasswordReset) {
        try {
          console.log("Sending password reset email...");
          await sendPasswordResetEmail(auth, userData.email);
          console.log("Password reset email sent successfully");
        } catch (emailError) {
          console.warn("Failed to send password reset email:", emailError);
          // Don't fail the entire operation if email fails
        }
      }

      console.log("User created successfully:", firebaseUser.uid);
      return firebaseUser.uid;
    } catch (error) {
      console.error("Error creating user:", error);

      // Provide more specific error messages
      if (error instanceof Error) {
        if (error.message.includes("email-already-in-use")) {
          throw new Error("A user with this email address already exists");
        } else if (error.message.includes("invalid-email")) {
          throw new Error("Please provide a valid email address");
        } else if (error.message.includes("weak-password")) {
          throw new Error("Password should be at least 6 characters long");
        } else if (error.message.includes("network-request-failed")) {
          throw new Error(
            "Network error. Please check your connection and try again"
          );
        } else if (error.message.includes("permission-denied")) {
          throw new Error(
            "Permission denied. Please check Firebase security rules"
          );
        }
      }

      throw new Error(
        `Failed to create user: ${
          error instanceof Error ? error.message : "Unknown error"
        }`
      );
    }
  }

  // Generate a secure temporary password
  private generateTempPassword(): string {
    const chars =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*";
    let password = "";
    for (let i = 0; i < 12; i++) {
      password += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return password;
  }

  // Delete user
  async deleteUser(id: string): Promise<void> {
    try {
      const docRef = doc(db, this.collectionName, id);
      await deleteDoc(docRef);
    } catch (error) {
      console.error("Error deleting user:", error);
      throw new Error("Failed to delete user");
    }
  }

  // Real-time subscription to users
  subscribeToUsers(
    callback: (users: User[]) => void,
    filters?: UserFilters
  ): () => void {
    const q = query(collection(db, this.collectionName), limit(100));

    return onSnapshot(q, (querySnapshot) => {
      let users = querySnapshot.docs.map((doc) => {
        const data = doc.data();

        // Map mobile app user structure to admin portal structure
        return {
          id: doc.id,
          name: data.name || "Unknown User",
          email: data.email || "",
          role: data.role || "citizen",
          status: data.status || "active",
          phone: data.phone || "",
          avatar: data.photoURL || "",
          department: data.department || "",
          specializations: data.specializations || [],
          location: data.lastLocation
            ? {
                latitude: data.lastLocation.latitude || 0,
                longitude: data.lastLocation.longitude || 0,
                address: data.lastLocation.address || "",
                city: data.lastLocation.city || "",
                state: data.lastLocation.state || "",
              }
            : undefined,
          isOnline: data.isOnline || false,
          lastSeen: data.lastSeen?.toDate() || new Date(),
          lastActive: data.lastSeen?.toDate() || new Date(),
          createdAt: data.createdAt?.toDate() || new Date(),
          updatedAt: data.updatedAt?.toDate() || new Date(),
          metadata: {
            deviceToken: data.deviceToken,
            notificationPreferences: data.notificationPreferences,
          },
        } as User;
      });

      // Apply filters in memory
      if (filters?.role && filters.role.length > 0) {
        users = users.filter((u) => filters.role!.includes(u.role));
      }

      if (filters?.status && filters.status.length > 0) {
        users = users.filter((u) => filters.status!.includes(u.status));
      }

      if (filters?.isOnline !== undefined) {
        users = users.filter((u) => u.isOnline === filters.isOnline);
      }

      // Limit after filtering
      users = users.slice(0, 50);

      callback(users);
    });
  }

  // Get user statistics
  async getUserStats(): Promise<UserStats> {
    try {
      const users = await this.getUsers();

      const stats: UserStats = {
        total: users.length,
        active: users.filter((u) => u.status === UserStatus.ACTIVE).length,
        online: users.filter((u) => u.isOnline).length,
        byRole: {} as any,
        byStatus: {} as any,
        responders: {
          available: 0,
          busy: 0,
          offDuty: 0,
        },
      };

      // Group by role and status
      users.forEach((user) => {
        stats.byRole[user.role] = (stats.byRole[user.role] || 0) + 1;
        stats.byStatus[user.status] = (stats.byStatus[user.status] || 0) + 1;
      });

      // Calculate responder availability
      const responders = users.filter(
        (u) => u.role === UserRole.RESPONDER
      ) as ResponderProfile[];
      responders.forEach((responder) => {
        if (responder.availability) {
          switch (responder.availability) {
            case "available":
              stats.responders.available++;
              break;
            case "busy":
              stats.responders.busy++;
              break;
            case "off_duty":
              stats.responders.offDuty++;
              break;
          }
        }
      });

      return stats;
    } catch (error) {
      console.error("Error calculating user stats:", error);
      throw new Error("Failed to calculate user stats");
    }
  }

  // Update responder availability
  async updateResponderAvailability(
    id: string,
    availability: string
  ): Promise<void> {
    try {
      const docRef = doc(db, this.collectionName, id);
      await updateDoc(docRef, {
        availability,
        updatedAt: Timestamp.now(),
      });
    } catch (error) {
      console.error("Error updating responder availability:", error);
      throw new Error("Failed to update responder availability");
    }
  }
}
