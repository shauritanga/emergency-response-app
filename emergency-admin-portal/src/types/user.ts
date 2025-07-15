export interface User {
  id: string;
  email: string;
  name: string;
  role: UserRole;
  status: UserStatus;
  phone?: string;
  avatar?: string;
  department?: string;
  specializations?: string[];
  location?: {
    latitude: number;
    longitude: number;
    address?: string;
    city?: string;
    state?: string;
  };
  isOnline: boolean;
  lastSeen: Date;
  lastActive: Date;
  createdAt: Date;
  updatedAt: Date;
  metadata?: Record<string, any>;
}

export const UserRole = {
  ADMIN: "admin",
  RESPONDER: "responder",
  CITIZEN: "citizen",
} as const;

export type UserRole = (typeof UserRole)[keyof typeof UserRole];

export const UserStatus = {
  ACTIVE: "active",
  INACTIVE: "inactive",
  SUSPENDED: "suspended",
  PENDING: "pending",
} as const;

export type UserStatus = (typeof UserStatus)[keyof typeof UserStatus];

export interface ResponderProfile extends User {
  role: typeof UserRole.RESPONDER;
  badgeNumber?: string;
  certifications: string[];
  availability: ResponderAvailability;
  currentAssignments: string[]; // Emergency IDs
  responseHistory: ResponseHistoryEntry[];
}

export const ResponderAvailability = {
  AVAILABLE: "available",
  BUSY: "busy",
  OFF_DUTY: "off_duty",
  EMERGENCY: "emergency",
} as const;

export type ResponderAvailability =
  (typeof ResponderAvailability)[keyof typeof ResponderAvailability];

export interface ResponseHistoryEntry {
  emergencyId: string;
  emergencyType: string;
  responseTime: number; // in minutes
  resolvedAt: Date;
  rating?: number; // 1-5 stars
  feedback?: string;
}

export interface UserFilters {
  role?: UserRole[];
  status?: UserStatus[];
  department?: string[];
  availability?: ResponderAvailability[];
  isOnline?: boolean;
  searchQuery?: string;
}

export interface UserStats {
  total: number;
  active: number;
  online: number;
  byRole: Record<UserRole, number>;
  byStatus: Record<UserStatus, number>;
  responders: {
    available: number;
    busy: number;
    offDuty: number;
  };
}
