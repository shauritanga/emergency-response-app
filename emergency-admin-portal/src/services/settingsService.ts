import {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  collection,
  query,
  getDocs,
  where,
  Timestamp,
} from "firebase/firestore";
import { db } from "@/lib/firebase";

export interface SystemSettings {
  id: string;
  // General Settings
  systemName: string;
  systemDescription: string;
  timezone: string;
  language: string;
  dateFormat: string;
  timeFormat: "12h" | "24h";
  
  // Emergency Settings
  emergencyTypes: string[];
  priorityLevels: string[];
  autoAssignmentEnabled: boolean;
  maxResponseTime: number; // in minutes
  escalationEnabled: boolean;
  escalationTime: number; // in minutes
  
  // Notification Settings
  emailEnabled: boolean;
  smsEnabled: boolean;
  pushNotificationsEnabled: boolean;
  notificationRetryAttempts: number;
  notificationRetryInterval: number; // in minutes
  
  // Security Settings
  sessionTimeout: number; // in minutes
  passwordMinLength: number;
  passwordRequireSpecialChars: boolean;
  passwordRequireNumbers: boolean;
  passwordRequireUppercase: boolean;
  twoFactorAuthRequired: boolean;
  maxLoginAttempts: number;
  lockoutDuration: number; // in minutes
  
  // System Limits
  maxActiveEmergencies: number;
  maxRespondersPerEmergency: number;
  dataRetentionPeriod: number; // in days
  logRetentionPeriod: number; // in days
  
  // Integration Settings
  mapProvider: "google" | "openstreetmap" | "mapbox";
  mapApiKey?: string;
  weatherApiEnabled: boolean;
  weatherApiKey?: string;
  
  // Maintenance
  maintenanceMode: boolean;
  maintenanceMessage: string;
  backupEnabled: boolean;
  backupFrequency: "daily" | "weekly" | "monthly";
  
  // Audit
  auditLoggingEnabled: boolean;
  auditRetentionPeriod: number; // in days
  
  updatedAt: Date;
  updatedBy: string;
}

export interface UserPreferences {
  userId: string;
  theme: "light" | "dark" | "system";
  language: string;
  timezone: string;
  dateFormat: string;
  timeFormat: "12h" | "24h";
  dashboardLayout: "compact" | "comfortable" | "spacious";
  defaultView: "dashboard" | "emergencies" | "monitoring";
  autoRefresh: boolean;
  refreshInterval: number; // in seconds
  soundNotifications: boolean;
  desktopNotifications: boolean;
  emailDigest: "none" | "daily" | "weekly";
  updatedAt: Date;
}

export class SettingsService {
  private static instance: SettingsService;

  static getInstance(): SettingsService {
    if (!SettingsService.instance) {
      SettingsService.instance = new SettingsService();
    }
    return SettingsService.instance;
  }

  // System Settings
  async getSystemSettings(): Promise<SystemSettings> {
    try {
      const docRef = doc(db, "system_settings", "main");
      const docSnap = await getDoc(docRef);

      if (docSnap.exists()) {
        const data = docSnap.data();
        return {
          id: docSnap.id,
          ...data,
          updatedAt: data.updatedAt?.toDate() || new Date(),
        } as SystemSettings;
      }

      // Return default settings if none exist
      return this.getDefaultSystemSettings();
    } catch (error) {
      console.error("Error getting system settings:", error);
      throw error;
    }
  }

  async updateSystemSettings(
    settings: Partial<SystemSettings>,
    updatedBy: string
  ): Promise<void> {
    try {
      const docRef = doc(db, "system_settings", "main");
      await updateDoc(docRef, {
        ...settings,
        updatedAt: Timestamp.now(),
        updatedBy,
      });
    } catch (error) {
      console.error("Error updating system settings:", error);
      throw error;
    }
  }

  async initializeSystemSettings(updatedBy: string): Promise<void> {
    try {
      const docRef = doc(db, "system_settings", "main");
      const docSnap = await getDoc(docRef);

      if (!docSnap.exists()) {
        const defaultSettings = this.getDefaultSystemSettings();
        await setDoc(docRef, {
          ...defaultSettings,
          updatedAt: Timestamp.now(),
          updatedBy,
        });
      }
    } catch (error) {
      console.error("Error initializing system settings:", error);
      throw error;
    }
  }

  // User Preferences
  async getUserPreferences(userId: string): Promise<UserPreferences> {
    try {
      const docRef = doc(db, "user_preferences", userId);
      const docSnap = await getDoc(docRef);

      if (docSnap.exists()) {
        const data = docSnap.data();
        return {
          ...data,
          updatedAt: data.updatedAt?.toDate() || new Date(),
        } as UserPreferences;
      }

      // Return default preferences if none exist
      return this.getDefaultUserPreferences(userId);
    } catch (error) {
      console.error("Error getting user preferences:", error);
      throw error;
    }
  }

  async updateUserPreferences(preferences: Partial<UserPreferences>): Promise<void> {
    try {
      if (!preferences.userId) {
        throw new Error("User ID is required");
      }

      const docRef = doc(db, "user_preferences", preferences.userId);
      await updateDoc(docRef, {
        ...preferences,
        updatedAt: Timestamp.now(),
      });
    } catch (error) {
      console.error("Error updating user preferences:", error);
      throw error;
    }
  }

  async initializeUserPreferences(userId: string): Promise<void> {
    try {
      const docRef = doc(db, "user_preferences", userId);
      const docSnap = await getDoc(docRef);

      if (!docSnap.exists()) {
        const defaultPreferences = this.getDefaultUserPreferences(userId);
        await setDoc(docRef, {
          ...defaultPreferences,
          updatedAt: Timestamp.now(),
        });
      }
    } catch (error) {
      console.error("Error initializing user preferences:", error);
      throw error;
    }
  }

  // Configuration validation
  async validateSettings(settings: Partial<SystemSettings>): Promise<{
    valid: boolean;
    errors: string[];
  }> {
    const errors: string[] = [];

    if (settings.maxResponseTime && settings.maxResponseTime < 1) {
      errors.push("Max response time must be at least 1 minute");
    }

    if (settings.escalationTime && settings.escalationTime < 5) {
      errors.push("Escalation time must be at least 5 minutes");
    }

    if (settings.sessionTimeout && settings.sessionTimeout < 15) {
      errors.push("Session timeout must be at least 15 minutes");
    }

    if (settings.passwordMinLength && settings.passwordMinLength < 8) {
      errors.push("Password minimum length must be at least 8 characters");
    }

    if (settings.maxLoginAttempts && settings.maxLoginAttempts < 3) {
      errors.push("Max login attempts must be at least 3");
    }

    if (settings.dataRetentionPeriod && settings.dataRetentionPeriod < 30) {
      errors.push("Data retention period must be at least 30 days");
    }

    return {
      valid: errors.length === 0,
      errors,
    };
  }

  // Default configurations
  private getDefaultSystemSettings(): SystemSettings {
    return {
      id: "main",
      systemName: "Emergency Response System",
      systemDescription: "Comprehensive emergency management platform",
      timezone: "UTC",
      language: "en",
      dateFormat: "MM/DD/YYYY",
      timeFormat: "12h",
      
      emergencyTypes: ["Fire", "Medical", "Police", "Accident", "Natural Disaster"],
      priorityLevels: ["Low", "Medium", "High", "Critical"],
      autoAssignmentEnabled: true,
      maxResponseTime: 15,
      escalationEnabled: true,
      escalationTime: 30,
      
      emailEnabled: true,
      smsEnabled: false,
      pushNotificationsEnabled: true,
      notificationRetryAttempts: 3,
      notificationRetryInterval: 5,
      
      sessionTimeout: 60,
      passwordMinLength: 8,
      passwordRequireSpecialChars: true,
      passwordRequireNumbers: true,
      passwordRequireUppercase: true,
      twoFactorAuthRequired: false,
      maxLoginAttempts: 5,
      lockoutDuration: 15,
      
      maxActiveEmergencies: 100,
      maxRespondersPerEmergency: 10,
      dataRetentionPeriod: 365,
      logRetentionPeriod: 90,
      
      mapProvider: "openstreetmap",
      weatherApiEnabled: false,
      
      maintenanceMode: false,
      maintenanceMessage: "System is currently under maintenance. Please try again later.",
      backupEnabled: true,
      backupFrequency: "daily",
      
      auditLoggingEnabled: true,
      auditRetentionPeriod: 180,
      
      updatedAt: new Date(),
      updatedBy: "system",
    };
  }

  private getDefaultUserPreferences(userId: string): UserPreferences {
    return {
      userId,
      theme: "system",
      language: "en",
      timezone: "UTC",
      dateFormat: "MM/DD/YYYY",
      timeFormat: "12h",
      dashboardLayout: "comfortable",
      defaultView: "dashboard",
      autoRefresh: true,
      refreshInterval: 30,
      soundNotifications: true,
      desktopNotifications: true,
      emailDigest: "daily",
      updatedAt: new Date(),
    };
  }

  // System health check
  async performHealthCheck(): Promise<{
    status: "healthy" | "warning" | "critical";
    checks: Array<{
      name: string;
      status: "pass" | "fail" | "warning";
      message: string;
    }>;
  }> {
    const checks = [];

    try {
      // Database connectivity
      const testDoc = await getDoc(doc(db, "system_settings", "main"));
      checks.push({
        name: "Database Connectivity",
        status: "pass" as const,
        message: "Database connection successful",
      });
    } catch (error) {
      checks.push({
        name: "Database Connectivity",
        status: "fail" as const,
        message: "Database connection failed",
      });
    }

    // Check system settings
    try {
      const settings = await this.getSystemSettings();
      checks.push({
        name: "System Configuration",
        status: "pass" as const,
        message: "System settings loaded successfully",
      });
    } catch (error) {
      checks.push({
        name: "System Configuration",
        status: "fail" as const,
        message: "Failed to load system settings",
      });
    }

    const failedChecks = checks.filter((check) => check.status === "fail");
    const warningChecks = checks.filter((check) => check.status === "warning");

    let status: "healthy" | "warning" | "critical";
    if (failedChecks.length > 0) {
      status = "critical";
    } else if (warningChecks.length > 0) {
      status = "warning";
    } else {
      status = "healthy";
    }

    return { status, checks };
  }
}

export const settingsService = SettingsService.getInstance();
