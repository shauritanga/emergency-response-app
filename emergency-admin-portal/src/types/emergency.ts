export const EmergencyType = {
  FIRE: "fire",
  MEDICAL: "medical",
  POLICE: "police",
  NATURAL_DISASTER: "natural_disaster",
  ACCIDENT: "accident",
  SECURITY: "security",
  OTHER: "other",
} as const;

export type EmergencyType = (typeof EmergencyType)[keyof typeof EmergencyType];

export const EmergencyStatus = {
  REPORTED: "reported",
  DISPATCHED: "dispatched",
  IN_PROGRESS: "in_progress",
  RESOLVED: "resolved",
  CANCELLED: "cancelled",
} as const;

export type EmergencyStatus =
  (typeof EmergencyStatus)[keyof typeof EmergencyStatus];

export const EmergencyPriority = {
  LOW: "low",
  MEDIUM: "medium",
  HIGH: "high",
  CRITICAL: "critical",
} as const;

export type EmergencyPriority =
  (typeof EmergencyPriority)[keyof typeof EmergencyPriority];

export const TimelineEventType = {
  REPORTED: "reported",
  DISPATCHED: "dispatched",
  RESPONDER_ASSIGNED: "responder_assigned",
  RESPONDER_ARRIVED: "responder_arrived",
  STATUS_UPDATE: "status_update",
  RESOLVED: "resolved",
  CANCELLED: "cancelled",
  NOTE_ADDED: "note_added",
} as const;

export type TimelineEventType =
  (typeof TimelineEventType)[keyof typeof TimelineEventType];

export interface Emergency {
  id: string;
  type: EmergencyType;
  status: EmergencyStatus;
  priority: EmergencyPriority;
  title: string;
  description: string;
  location: {
    latitude: number;
    longitude: number;
    address?: string;
    city?: string;
    state?: string;
  };
  reportedBy: {
    userId: string;
    name: string;
    phone?: string;
    email?: string;
  };
  assignedResponders: string[]; // User IDs
  timeline: EmergencyTimelineEvent[];
  imageUrls: string[]; // URLs of uploaded images
  createdAt: Date;
  updatedAt: Date;
  resolvedAt?: Date;
  estimatedResponseTime?: number; // in minutes
  actualResponseTime?: number; // in minutes
}

export interface EmergencyTimelineEvent {
  id: string;
  emergencyId: string;
  type: TimelineEventType;
  title: string;
  description: string;
  userId: string;
  userName: string;
  userRole: string;
  timestamp: Date;
  metadata?: Record<string, any>;
}

export interface EmergencyFilters {
  status?: EmergencyStatus[];
  type?: EmergencyType[];
  priority?: EmergencyPriority[];
  dateRange?: {
    start: Date;
    end: Date;
  };
  assignedResponder?: string;
  searchQuery?: string;
}

export interface EmergencyStats {
  total: number;
  active: number;
  resolved: number;
  averageResponseTime: number;
  byType: Record<EmergencyType, number>;
  byStatus: Record<EmergencyStatus, number>;
  byPriority: Record<EmergencyPriority, number>;
}
