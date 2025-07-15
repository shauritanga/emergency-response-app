import {
  collection,
  query,
  where,
  orderBy,
  getDocs,
  Timestamp,
  limit,
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import {
  type Emergency,
  EmergencyStatus,
  EmergencyType,
} from "@/types/emergency";
import { type User } from "@/types/user";

export interface DateRange {
  start: Date;
  end: Date;
}

export interface EmergencyAnalytics {
  totalEmergencies: number;
  resolvedEmergencies: number;
  averageResponseTime: number;
  resolutionRate: number;
  emergenciesByType: Record<string, number>;
  emergenciesByStatus: Record<string, number>;
  emergenciesByPriority: Record<string, number>;
  dailyTrends: Array<{
    date: string;
    count: number;
    resolved: number;
    avgResponseTime: number;
  }>;
  hourlyDistribution: Array<{
    hour: number;
    count: number;
  }>;
  topLocations: Array<{
    location: string;
    count: number;
    avgResponseTime: number;
  }>;
}

export interface ResponderAnalytics {
  totalResponders: number;
  activeResponders: number;
  averageResponseTime: number;
  topPerformers: Array<{
    id: string;
    name: string;
    completedEmergencies: number;
    averageResponseTime: number;
    rating: number;
  }>;
  departmentStats: Record<
    string,
    {
      count: number;
      activeCount: number;
      avgResponseTime: number;
    }
  >;
  responseTimeDistribution: Array<{
    range: string;
    count: number;
  }>;
}

export interface SystemAnalytics {
  systemUptime: number;
  averageSystemLoad: number;
  peakHours: Array<{
    hour: number;
    emergencyCount: number;
  }>;
  geographicDistribution: Array<{
    area: string;
    count: number;
    responseTime: number;
  }>;
  monthlyComparison: Array<{
    month: string;
    emergencies: number;
    resolved: number;
    avgResponseTime: number;
  }>;
}

export class AnalyticsService {
  private static instance: AnalyticsService;

  static getInstance(): AnalyticsService {
    if (!AnalyticsService.instance) {
      AnalyticsService.instance = new AnalyticsService();
    }
    return AnalyticsService.instance;
  }

  async getEmergencyAnalytics(
    dateRange: DateRange
  ): Promise<EmergencyAnalytics> {
    try {
      // Query using 'timestamp' field which is what the mobile app uses
      const emergenciesQuery = query(
        collection(db, "emergencies"),
        where("timestamp", ">=", Timestamp.fromDate(dateRange.start)),
        where("timestamp", "<=", Timestamp.fromDate(dateRange.end)),
        orderBy("timestamp", "desc")
      );

      const snapshot = await getDocs(emergenciesQuery);
      const emergencies: Emergency[] = [];

      console.log(
        `Analytics: Found ${snapshot.size} emergencies in date range`
      );

      snapshot.forEach((doc) => {
        const data = doc.data();
        console.log("Emergency data:", data);
        emergencies.push({
          id: doc.id,
          type: data.type || "unknown",
          status: data.status || "pending",
          priority: data.priority || "medium",
          title: data.description || "Emergency",
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
          timeline: [],
          imageUrls: data.imageUrls || [],
          createdAt: data.timestamp?.toDate() || new Date(),
          updatedAt:
            data.updatedAt?.toDate() || data.timestamp?.toDate() || new Date(),
          resolvedAt: data.resolvedAt?.toDate(),
          estimatedResponseTime: data.estimatedResponseTime || 0,
          actualResponseTime: data.actualResponseTime || 0,
        } as Emergency);
      });

      return this.processEmergencyAnalytics(emergencies, dateRange);
    } catch (error) {
      console.error("Error fetching emergency analytics:", error);
      throw error;
    }
  }

  async getResponderAnalytics(
    dateRange: DateRange
  ): Promise<ResponderAnalytics> {
    try {
      // Get all responders
      const respondersQuery = query(
        collection(db, "users"),
        where("role", "==", "responder")
      );

      const respondersSnapshot = await getDocs(respondersQuery);
      const responders: User[] = [];

      respondersSnapshot.forEach((doc) => {
        const data = doc.data();
        responders.push({
          id: doc.id,
          name: data.name || "Unknown",
          email: data.email || "",
          role: data.role || "responder",
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
          lastActive: data.lastActive?.toDate() || new Date(),
          createdAt: data.createdAt?.toDate() || new Date(),
          updatedAt: data.updatedAt?.toDate() || new Date(),
          metadata: data.metadata || {},
        } as User);
      });

      // Get emergencies in date range to calculate real performance metrics
      const emergenciesQuery = query(
        collection(db, "emergencies"),
        where("timestamp", ">=", Timestamp.fromDate(dateRange.start)),
        where("timestamp", "<=", Timestamp.fromDate(dateRange.end)),
        orderBy("timestamp", "desc")
      );

      const emergenciesSnapshot = await getDocs(emergenciesQuery);
      const emergencies: Emergency[] = [];

      emergenciesSnapshot.forEach((doc) => {
        const data = doc.data();
        emergencies.push({
          id: doc.id,
          type: data.type || "unknown",
          status: data.status || "pending",
          assignedResponders: data.responderIds || [],
          createdAt: data.timestamp?.toDate() || new Date(),
          actualResponseTime: data.actualResponseTime || 0,
        } as Emergency);
      });

      return this.processResponderAnalytics(responders, emergencies, dateRange);
    } catch (error) {
      console.error("Error fetching responder analytics:", error);
      throw error;
    }
  }

  async getSystemAnalytics(dateRange: DateRange): Promise<SystemAnalytics> {
    try {
      // Get system metrics and performance data using correct timestamp field
      const emergenciesQuery = query(
        collection(db, "emergencies"),
        where("timestamp", ">=", Timestamp.fromDate(dateRange.start)),
        where("timestamp", "<=", Timestamp.fromDate(dateRange.end)),
        orderBy("timestamp", "desc")
      );

      const snapshot = await getDocs(emergenciesQuery);
      const emergencies: Emergency[] = [];

      snapshot.forEach((doc) => {
        const data = doc.data();
        emergencies.push({
          id: doc.id,
          type: data.type || "unknown",
          status: data.status || "pending",
          priority: data.priority || "medium",
          title: data.description || "Emergency",
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
          timeline: [],
          imageUrls: data.imageUrls || [],
          createdAt: data.timestamp?.toDate() || new Date(),
          updatedAt:
            data.updatedAt?.toDate() || data.timestamp?.toDate() || new Date(),
          resolvedAt: data.resolvedAt?.toDate(),
          estimatedResponseTime: data.estimatedResponseTime || 0,
          actualResponseTime: data.actualResponseTime || 0,
        } as Emergency);
      });

      return this.processSystemAnalytics(emergencies, dateRange);
    } catch (error) {
      console.error("Error fetching system analytics:", error);
      throw error;
    }
  }

  private processEmergencyAnalytics(
    emergencies: Emergency[],
    dateRange: DateRange
  ): EmergencyAnalytics {
    const totalEmergencies = emergencies.length;
    const resolvedEmergencies = emergencies.filter(
      (e) => e.status === EmergencyStatus.RESOLVED
    ).length;

    // Calculate average response time
    const emergenciesWithResponseTime = emergencies.filter(
      (e) => e.actualResponseTime && e.actualResponseTime > 0
    );
    const averageResponseTime =
      emergenciesWithResponseTime.length > 0
        ? emergenciesWithResponseTime.reduce(
            (sum, e) => sum + (e.actualResponseTime || 0),
            0
          ) / emergenciesWithResponseTime.length
        : 0;

    const resolutionRate =
      totalEmergencies > 0 ? (resolvedEmergencies / totalEmergencies) * 100 : 0;

    // Group by type, status, priority
    const emergenciesByType = this.groupBy(emergencies, "type");
    const emergenciesByStatus = this.groupBy(emergencies, "status");
    const emergenciesByPriority = this.groupBy(emergencies, "priority");

    console.log("Analytics grouping results:", {
      emergenciesByType,
      emergenciesByStatus,
      emergenciesByPriority,
      sampleEmergency: emergencies[0],
    });

    // Daily trends
    const dailyTrends = this.calculateDailyTrends(emergencies, dateRange);

    // Hourly distribution
    const hourlyDistribution = this.calculateHourlyDistribution(emergencies);

    // Top locations
    const topLocations = this.calculateTopLocations(emergencies);

    return {
      totalEmergencies,
      resolvedEmergencies,
      averageResponseTime,
      resolutionRate,
      emergenciesByType,
      emergenciesByStatus,
      emergenciesByPriority,
      dailyTrends,
      hourlyDistribution,
      topLocations,
    };
  }

  private processResponderAnalytics(
    responders: User[],
    emergencies: Emergency[],
    dateRange: DateRange
  ): ResponderAnalytics {
    const totalResponders = responders.length;
    const activeResponders = responders.filter((r) => r.isOnline).length;

    // Calculate real average response time from emergencies
    const emergenciesWithResponseTime = emergencies.filter(
      (e) => e.actualResponseTime && e.actualResponseTime > 0
    );
    const averageResponseTime =
      emergenciesWithResponseTime.length > 0
        ? emergenciesWithResponseTime.reduce(
            (sum, e) => sum + (e.actualResponseTime || 0),
            0
          ) / emergenciesWithResponseTime.length
        : 0;

    // Calculate real top performers based on actual emergency data
    const responderPerformance = responders.map((responder) => {
      const responderEmergencies = emergencies.filter((e) =>
        e.assignedResponders.includes(responder.id)
      );

      const completedEmergencies = responderEmergencies.filter(
        (e) => e.status === "resolved"
      ).length;

      const responderResponseTimes = responderEmergencies
        .filter((e) => e.actualResponseTime && e.actualResponseTime > 0)
        .map((e) => e.actualResponseTime || 0);

      const avgResponseTime =
        responderResponseTimes.length > 0
          ? responderResponseTimes.reduce((sum, time) => sum + time, 0) /
            responderResponseTimes.length
          : 0;

      return {
        id: responder.id,
        name: responder.name,
        completedEmergencies,
        averageResponseTime: avgResponseTime,
        rating:
          completedEmergencies > 0
            ? Math.min(5, 3 + completedEmergencies / 10)
            : 3,
      };
    });

    const topPerformers = responderPerformance
      .sort((a, b) => b.completedEmergencies - a.completedEmergencies)
      .slice(0, 10);

    // Department stats with real response time calculation
    const departmentStats = responders.reduce((acc, responder) => {
      const dept = responder.department || "Unknown";
      if (!acc[dept]) {
        acc[dept] = {
          count: 0,
          activeCount: 0,
          avgResponseTime: 0,
          totalResponseTime: 0,
          responseCount: 0,
        };
      }
      acc[dept].count++;
      if (responder.isOnline) acc[dept].activeCount++;

      // Calculate real average response time for this department
      const responderEmergencies = emergencies.filter((e) =>
        e.assignedResponders.includes(responder.id)
      );
      const responderResponseTimes = responderEmergencies
        .filter((e) => e.actualResponseTime && e.actualResponseTime > 0)
        .map((e) => e.actualResponseTime || 0);

      if (responderResponseTimes.length > 0) {
        const totalTime = responderResponseTimes.reduce(
          (sum, time) => sum + time,
          0
        );
        acc[dept].totalResponseTime += totalTime;
        acc[dept].responseCount += responderResponseTimes.length;
      }

      return acc;
    }, {} as Record<string, { count: number; activeCount: number; avgResponseTime: number; totalResponseTime: number; responseCount: number }>);

    // Calculate final average response times for departments
    Object.keys(departmentStats).forEach((dept) => {
      if (departmentStats[dept].responseCount > 0) {
        departmentStats[dept].avgResponseTime =
          departmentStats[dept].totalResponseTime /
          departmentStats[dept].responseCount;
      }
    });

    console.log("Responder analytics:", {
      totalResponders,
      activeResponders,
      departmentStats,
      sampleResponder: responders[0],
    });

    // Response time distribution based on real data
    const allResponseTimes = emergencies
      .filter((e) => e.actualResponseTime && e.actualResponseTime > 0)
      .map((e) => e.actualResponseTime || 0);

    const responseTimeDistribution = [
      {
        range: "0-2 min",
        count: allResponseTimes.filter((time) => time <= 2).length,
      },
      {
        range: "2-5 min",
        count: allResponseTimes.filter((time) => time > 2 && time <= 5).length,
      },
      {
        range: "5-10 min",
        count: allResponseTimes.filter((time) => time > 5 && time <= 10).length,
      },
      {
        range: "10+ min",
        count: allResponseTimes.filter((time) => time > 10).length,
      },
    ];

    return {
      totalResponders,
      activeResponders,
      averageResponseTime,
      topPerformers,
      departmentStats,
      responseTimeDistribution,
    };
  }

  private processSystemAnalytics(
    emergencies: Emergency[],
    dateRange: DateRange
  ): SystemAnalytics {
    // System uptime (mock - would come from actual system monitoring)
    const systemUptime = 99.8;

    // Average system load (mock)
    const averageSystemLoad = 65.4;

    // Peak hours
    const hourlyData = this.calculateHourlyDistribution(emergencies);
    const peakHours = hourlyData
      .sort((a, b) => b.count - a.count)
      .slice(0, 5)
      .map((item) => ({
        hour: item.hour,
        emergencyCount: item.count,
      }));

    // Geographic distribution
    const geographicDistribution =
      this.calculateGeographicDistribution(emergencies);

    // Monthly comparison
    const monthlyComparison = this.calculateMonthlyComparison(
      emergencies,
      dateRange
    );

    return {
      systemUptime,
      averageSystemLoad,
      peakHours,
      geographicDistribution,
      monthlyComparison,
    };
  }

  private groupBy(items: any[], key: string): Record<string, number> {
    return items.reduce((acc, item) => {
      const value = item[key] || "Unknown";
      acc[value] = (acc[value] || 0) + 1;
      return acc;
    }, {});
  }

  private calculateDailyTrends(emergencies: Emergency[], dateRange: DateRange) {
    const days = Math.ceil(
      (dateRange.end.getTime() - dateRange.start.getTime()) /
        (1000 * 60 * 60 * 24)
    );

    const trends = [];
    for (let i = 0; i < days; i++) {
      const date = new Date(dateRange.start);
      date.setDate(date.getDate() + i);

      const dayEmergencies = emergencies.filter((e) => {
        const emergencyDate = new Date(e.createdAt);
        return emergencyDate.toDateString() === date.toDateString();
      });

      const resolved = dayEmergencies.filter(
        (e) => e.status === EmergencyStatus.RESOLVED
      ).length;

      const avgResponseTime =
        dayEmergencies.length > 0
          ? dayEmergencies.reduce(
              (sum, e) => sum + (e.actualResponseTime || 0),
              0
            ) / dayEmergencies.length
          : 0;

      trends.push({
        date: date.toISOString().split("T")[0],
        count: dayEmergencies.length,
        resolved,
        avgResponseTime,
      });
    }

    return trends;
  }

  private calculateHourlyDistribution(emergencies: Emergency[]) {
    const hourlyData = Array.from({ length: 24 }, (_, hour) => ({
      hour,
      count: 0,
    }));

    emergencies.forEach((emergency) => {
      const hour = new Date(emergency.createdAt).getHours();
      hourlyData[hour].count++;
    });

    return hourlyData;
  }

  private calculateTopLocations(emergencies: Emergency[]) {
    const locationCounts = emergencies.reduce((acc, emergency) => {
      const location = emergency.location?.address || "Unknown Location";
      if (!acc[location]) {
        acc[location] = { count: 0, totalResponseTime: 0 };
      }
      acc[location].count++;
      acc[location].totalResponseTime += emergency.actualResponseTime || 0;
      return acc;
    }, {} as Record<string, { count: number; totalResponseTime: number }>);

    return Object.entries(locationCounts)
      .map(([location, data]) => ({
        location,
        count: data.count,
        avgResponseTime:
          data.count > 0 ? data.totalResponseTime / data.count : 0,
      }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 10);
  }

  private calculateGeographicDistribution(emergencies: Emergency[]) {
    // Calculate real geographic distribution based on city/area data
    const areaCounts = emergencies.reduce((acc, emergency) => {
      const area =
        emergency.location?.city ||
        emergency.location?.address ||
        "Unknown Area";
      if (!acc[area]) {
        acc[area] = { count: 0, totalResponseTime: 0 };
      }
      acc[area].count++;
      acc[area].totalResponseTime += emergency.actualResponseTime || 0;
      return acc;
    }, {} as Record<string, { count: number; totalResponseTime: number }>);

    return Object.entries(areaCounts)
      .map(([area, data]) => ({
        area,
        count: data.count,
        responseTime: data.count > 0 ? data.totalResponseTime / data.count : 0,
      }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 10);
  }

  private calculateMonthlyComparison(
    emergencies: Emergency[],
    dateRange: DateRange
  ) {
    // Calculate monthly data for comparison
    const monthlyData = [];
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];

    for (let i = 0; i < 6; i++) {
      const date = new Date();
      date.setMonth(date.getMonth() - i);

      const monthEmergencies = emergencies.filter((e) => {
        const emergencyDate = new Date(e.createdAt);
        return (
          emergencyDate.getMonth() === date.getMonth() &&
          emergencyDate.getFullYear() === date.getFullYear()
        );
      });

      const resolved = monthEmergencies.filter(
        (e) => e.status === EmergencyStatus.RESOLVED
      ).length;

      const avgResponseTime =
        monthEmergencies.length > 0
          ? monthEmergencies.reduce(
              (sum, e) => sum + (e.actualResponseTime || 0),
              0
            ) / monthEmergencies.length
          : 0;

      monthlyData.unshift({
        month: months[date.getMonth()],
        emergencies: monthEmergencies.length,
        resolved,
        avgResponseTime,
      });
    }

    return monthlyData;
  }
}

export const analyticsService = AnalyticsService.getInstance();

// Export report generation functions
export async function generateEmergencyReport(dateRange: DateRange) {
  const analytics = await analyticsService.getEmergencyAnalytics(dateRange);
  return {
    title: "Emergency Response Report",
    dateRange,
    analytics,
    generatedAt: new Date(),
  };
}

export async function generateResponderReport(dateRange: DateRange) {
  const analytics = await analyticsService.getResponderAnalytics(dateRange);
  return {
    title: "Responder Performance Report",
    dateRange,
    analytics,
    generatedAt: new Date(),
  };
}

export async function generateSystemReport(dateRange: DateRange) {
  const analytics = await analyticsService.getSystemAnalytics(dateRange);
  return {
    title: "System Performance Report",
    dateRange,
    analytics,
    generatedAt: new Date(),
  };
}
