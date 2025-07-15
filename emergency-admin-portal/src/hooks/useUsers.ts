import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useState, useEffect } from "react";
import { UserService } from "@/services/userService";
import { type User, type UserFilters, UserRole, UserStatus } from "@/types";

const userService = UserService.getInstance();

// Query keys
export const userKeys = {
  all: ["users"] as const,
  lists: () => [...userKeys.all, "list"] as const,
  list: (filters?: UserFilters) => [...userKeys.lists(), filters] as const,
  details: () => [...userKeys.all, "detail"] as const,
  detail: (id: string) => [...userKeys.details(), id] as const,
  stats: () => [...userKeys.all, "stats"] as const,
  responders: () => [...userKeys.all, "responders"] as const,
};

// Get users with filters
export const useUsers = (filters?: UserFilters) => {
  return useQuery({
    queryKey: userKeys.list(filters),
    queryFn: () => userService.getUsers(filters),
    staleTime: 30000, // 30 seconds
    refetchInterval: 60000, // Refetch every minute
  });
};

// Get single user
export const useUser = (id: string) => {
  return useQuery({
    queryKey: userKeys.detail(id),
    queryFn: () => userService.getUserById(id),
    enabled: !!id,
    staleTime: 30000,
  });
};

// Get responders only
export const useResponders = () => {
  return useQuery({
    queryKey: userKeys.responders(),
    queryFn: () => userService.getResponders(),
    staleTime: 30000,
    refetchInterval: 60000,
  });
};

// Get user statistics
export const useUserStats = () => {
  return useQuery({
    queryKey: userKeys.stats(),
    queryFn: () => userService.getUserStats(),
    staleTime: 60000, // 1 minute
    refetchInterval: 120000, // Refetch every 2 minutes
  });
};

// Real-time users subscription
export const useUsersRealtime = (filters?: UserFilters) => {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    setLoading(true);
    setError(null);

    const unsubscribe = userService.subscribeToUsers((newUsers) => {
      setUsers(newUsers);
      setLoading(false);
    }, filters);

    return () => {
      unsubscribe();
    };
  }, [JSON.stringify(filters)]); // Use JSON.stringify to properly compare filters object

  return { users, loading, error };
};

// Mutations
export const useUpdateUserStatus = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, status }: { id: string; status: UserStatus }) =>
      userService.updateUserStatus(id, status),
    onSuccess: (_, variables) => {
      // Invalidate and refetch user queries
      queryClient.invalidateQueries({ queryKey: userKeys.all });
      queryClient.invalidateQueries({
        queryKey: userKeys.detail(variables.id),
      });
    },
  });
};

export const useUpdateUserRole = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, role }: { id: string; role: UserRole }) =>
      userService.updateUserRole(id, role),
    onSuccess: (_, variables) => {
      // Invalidate and refetch user queries
      queryClient.invalidateQueries({ queryKey: userKeys.all });
      queryClient.invalidateQueries({
        queryKey: userKeys.detail(variables.id),
      });
    },
  });
};

export const useCreateUser = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (
      userData: Omit<User, "id" | "createdAt" | "updatedAt"> & {
        password?: string;
        sendPasswordReset?: boolean;
      }
    ) => userService.createUser(userData),
    onSuccess: () => {
      // Invalidate and refetch user queries
      queryClient.invalidateQueries({ queryKey: userKeys.all });
    },
  });
};

export const useDeleteUser = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => userService.deleteUser(id),
    onSuccess: () => {
      // Invalidate and refetch user queries
      queryClient.invalidateQueries({ queryKey: userKeys.all });
    },
  });
};

export const useUpdateResponderAvailability = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, availability }: { id: string; availability: string }) =>
      userService.updateResponderAvailability(id, availability),
    onSuccess: (_, variables) => {
      // Invalidate and refetch user queries
      queryClient.invalidateQueries({ queryKey: userKeys.all });
      queryClient.invalidateQueries({
        queryKey: userKeys.detail(variables.id),
      });
      queryClient.invalidateQueries({ queryKey: userKeys.responders() });
    },
  });
};
