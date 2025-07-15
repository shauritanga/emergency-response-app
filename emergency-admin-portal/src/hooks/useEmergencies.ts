import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useState, useEffect } from "react";
import { EmergencyService } from "@/services/emergencyService";
import {
  type Emergency,
  type EmergencyFilters,
  type EmergencyStats,
  EmergencyStatus,
} from "@/types";

const emergencyService = EmergencyService.getInstance();

// Query keys
export const emergencyKeys = {
  all: ["emergencies"] as const,
  lists: () => [...emergencyKeys.all, "list"] as const,
  list: (filters?: EmergencyFilters) =>
    [...emergencyKeys.lists(), filters] as const,
  details: () => [...emergencyKeys.all, "detail"] as const,
  detail: (id: string) => [...emergencyKeys.details(), id] as const,
  stats: () => [...emergencyKeys.all, "stats"] as const,
  timeline: (id: string) => [...emergencyKeys.all, "timeline", id] as const,
};

// Get emergencies with filters
export const useEmergencies = (filters?: EmergencyFilters) => {
  return useQuery({
    queryKey: emergencyKeys.list(filters),
    queryFn: () => emergencyService.getEmergencies(filters),
    staleTime: 30000, // 30 seconds
    refetchInterval: 60000, // Refetch every minute
  });
};

// Get single emergency
export const useEmergency = (id: string) => {
  return useQuery({
    queryKey: emergencyKeys.detail(id),
    queryFn: () => emergencyService.getEmergencyById(id),
    enabled: !!id,
    staleTime: 30000,
  });
};

// Get emergency statistics
export const useEmergencyStats = () => {
  return useQuery({
    queryKey: emergencyKeys.stats(),
    queryFn: () => emergencyService.getEmergencyStats(),
    staleTime: 60000, // 1 minute
    refetchInterval: 120000, // Refetch every 2 minutes
  });
};

// Get emergency timeline
export const useEmergencyTimeline = (emergencyId: string) => {
  return useQuery({
    queryKey: emergencyKeys.timeline(emergencyId),
    queryFn: () => emergencyService.getEmergencyTimeline(emergencyId),
    enabled: !!emergencyId,
    staleTime: 30000,
  });
};

// Real-time emergencies subscription
export const useEmergenciesRealtime = (filters?: EmergencyFilters) => {
  const [emergencies, setEmergencies] = useState<Emergency[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    setLoading(true);
    setError(null);

    const unsubscribe = emergencyService.subscribeToEmergencies(
      (newEmergencies) => {
        setEmergencies(newEmergencies);
        setLoading(false);
      },
      filters
    );

    return () => {
      unsubscribe();
    };
  }, [JSON.stringify(filters)]); // Use JSON.stringify to properly compare filters object

  return { emergencies, loading, error };
};

// Mutations
export const useUpdateEmergencyStatus = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      id,
      status,
      userId,
      userName,
    }: {
      id: string;
      status: EmergencyStatus;
      userId: string;
      userName: string;
    }) => emergencyService.updateEmergencyStatus(id, status, userId, userName),
    onSuccess: (_, variables) => {
      // Invalidate and refetch emergency queries
      queryClient.invalidateQueries({ queryKey: emergencyKeys.all });
      queryClient.invalidateQueries({
        queryKey: emergencyKeys.detail(variables.id),
      });
      queryClient.invalidateQueries({
        queryKey: emergencyKeys.timeline(variables.id),
      });
    },
  });
};

export const useAssignResponder = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      emergencyId,
      responderId,
      responderName,
      adminId,
      adminName,
    }: {
      emergencyId: string;
      responderId: string;
      responderName: string;
      adminId: string;
      adminName: string;
    }) =>
      emergencyService.assignResponder(
        emergencyId,
        responderId,
        responderName,
        adminId,
        adminName
      ),
    onSuccess: (_, variables) => {
      // Invalidate and refetch emergency queries
      queryClient.invalidateQueries({ queryKey: emergencyKeys.all });
      queryClient.invalidateQueries({
        queryKey: emergencyKeys.detail(variables.emergencyId),
      });
      queryClient.invalidateQueries({
        queryKey: emergencyKeys.timeline(variables.emergencyId),
      });
    },
  });
};

export const useAddTimelineEvent = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (
      event: Parameters<typeof emergencyService.addTimelineEvent>[0]
    ) => emergencyService.addTimelineEvent(event),
    onSuccess: (_, variables) => {
      // Invalidate timeline for this emergency
      queryClient.invalidateQueries({
        queryKey: emergencyKeys.timeline(variables.emergencyId),
      });
    },
  });
};
