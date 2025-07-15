import { useState, useEffect, useCallback } from "react";
import {
  analyticsService,
  type EmergencyAnalytics,
  type ResponderAnalytics,
  type SystemAnalytics,
  type DateRange,
  generateEmergencyReport,
  generateResponderReport,
  generateSystemReport,
} from "@/services/analyticsService";

// Hook for emergency analytics
export function useEmergencyAnalytics(dateRange: DateRange) {
  const [analytics, setAnalytics] = useState<EmergencyAnalytics | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchAnalytics = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await analyticsService.getEmergencyAnalytics(dateRange);
      setAnalytics(data);
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Failed to fetch analytics"
      );
    } finally {
      setLoading(false);
    }
  }, [dateRange.start.getTime(), dateRange.end.getTime()]);

  useEffect(() => {
    fetchAnalytics();
  }, [fetchAnalytics]);

  const refresh = useCallback(() => {
    fetchAnalytics();
  }, [fetchAnalytics]);

  return { analytics, loading, error, refresh };
}

// Hook for responder analytics
export function useResponderAnalytics(dateRange: DateRange) {
  const [analytics, setAnalytics] = useState<ResponderAnalytics | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchAnalytics = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await analyticsService.getResponderAnalytics(dateRange);
      setAnalytics(data);
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Failed to fetch analytics"
      );
    } finally {
      setLoading(false);
    }
  }, [dateRange.start.getTime(), dateRange.end.getTime()]);

  useEffect(() => {
    fetchAnalytics();
  }, [fetchAnalytics]);

  const refresh = useCallback(() => {
    fetchAnalytics();
  }, [fetchAnalytics]);

  return { analytics, loading, error, refresh };
}

// Hook for system analytics
export function useSystemAnalytics(dateRange: DateRange) {
  const [analytics, setAnalytics] = useState<SystemAnalytics | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchAnalytics = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await analyticsService.getSystemAnalytics(dateRange);
      setAnalytics(data);
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Failed to fetch analytics"
      );
    } finally {
      setLoading(false);
    }
  }, [dateRange.start.getTime(), dateRange.end.getTime()]);

  useEffect(() => {
    fetchAnalytics();
  }, [fetchAnalytics]);

  const refresh = useCallback(() => {
    fetchAnalytics();
  }, [fetchAnalytics]);

  return { analytics, loading, error, refresh };
}

// Hook for report generation
export function useReportGeneration() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const generateReport = useCallback(
    async (
      type: "emergency" | "responder" | "system",
      dateRange: DateRange
    ) => {
      try {
        setLoading(true);
        setError(null);

        let report;
        switch (type) {
          case "emergency":
            report = await generateEmergencyReport(dateRange);
            break;
          case "responder":
            report = await generateResponderReport(dateRange);
            break;
          case "system":
            report = await generateSystemReport(dateRange);
            break;
          default:
            throw new Error("Invalid report type");
        }

        // In a real implementation, this would trigger a download or save the report
        console.log("Generated report:", report);
        return report;
      } catch (err) {
        setError(
          err instanceof Error ? err.message : "Failed to generate report"
        );
        throw err;
      } finally {
        setLoading(false);
      }
    },
    []
  );

  return { generateReport, loading, error };
}

// Hook for date range management
export function useDateRange(initialRange?: DateRange) {
  const [dateRange, setDateRange] = useState<DateRange>(
    initialRange || {
      start: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), // 30 days ago
      end: new Date(),
    }
  );

  const setPresetRange = useCallback((preset: string) => {
    const end = new Date();
    let start: Date;

    switch (preset) {
      case "today":
        start = new Date();
        start.setHours(0, 0, 0, 0);
        break;
      case "yesterday":
        start = new Date();
        start.setDate(start.getDate() - 1);
        start.setHours(0, 0, 0, 0);
        end.setDate(end.getDate() - 1);
        end.setHours(23, 59, 59, 999);
        break;
      case "week":
        start = new Date();
        start.setDate(start.getDate() - 7);
        break;
      case "month":
        start = new Date();
        start.setMonth(start.getMonth() - 1);
        break;
      case "quarter":
        start = new Date();
        start.setMonth(start.getMonth() - 3);
        break;
      case "year":
        start = new Date();
        start.setFullYear(start.getFullYear() - 1);
        break;
      default:
        start = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    }

    setDateRange({ start, end });
  }, []);

  const setCustomRange = useCallback((start: Date, end: Date) => {
    setDateRange({ start, end });
  }, []);

  return {
    dateRange,
    setPresetRange,
    setCustomRange,
    setDateRange,
  };
}

// Hook for analytics comparison
export function useAnalyticsComparison(
  currentRange: DateRange,
  comparisonRange: DateRange
) {
  const [comparison, setComparison] = useState<{
    current: EmergencyAnalytics | null;
    previous: EmergencyAnalytics | null;
    changes: Record<string, { value: number; percentage: number }>;
  }>({
    current: null,
    previous: null,
    changes: {},
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchComparison = async () => {
      try {
        setLoading(true);
        setError(null);

        const [current, previous] = await Promise.all([
          analyticsService.getEmergencyAnalytics(currentRange),
          analyticsService.getEmergencyAnalytics(comparisonRange),
        ]);

        // Calculate changes
        const changes = {
          totalEmergencies: {
            value: current.totalEmergencies - previous.totalEmergencies,
            percentage:
              previous.totalEmergencies > 0
                ? ((current.totalEmergencies - previous.totalEmergencies) /
                    previous.totalEmergencies) *
                  100
                : 0,
          },
          resolutionRate: {
            value: current.resolutionRate - previous.resolutionRate,
            percentage:
              previous.resolutionRate > 0
                ? ((current.resolutionRate - previous.resolutionRate) /
                    previous.resolutionRate) *
                  100
                : 0,
          },
          averageResponseTime: {
            value: current.averageResponseTime - previous.averageResponseTime,
            percentage:
              previous.averageResponseTime > 0
                ? ((current.averageResponseTime -
                    previous.averageResponseTime) /
                    previous.averageResponseTime) *
                  100
                : 0,
          },
        };

        setComparison({ current, previous, changes });
      } catch (err) {
        setError(
          err instanceof Error ? err.message : "Failed to fetch comparison"
        );
      } finally {
        setLoading(false);
      }
    };

    fetchComparison();
  }, [
    currentRange.start.getTime(),
    currentRange.end.getTime(),
    comparisonRange.start.getTime(),
    comparisonRange.end.getTime(),
  ]);

  return { comparison, loading, error };
}
