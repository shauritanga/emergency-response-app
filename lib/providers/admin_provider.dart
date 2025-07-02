import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/emergency.dart';
import '../services/admin_service.dart';

// Admin state class
class AdminState {
  final List<UserModel> users;
  final List<Emergency> emergencies;
  final Map<String, dynamic> dashboardStats;
  final List<Map<String, dynamic>> emergencyTrends;
  final Map<String, dynamic> systemSettings;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String selectedFilter;

  AdminState({
    this.users = const [],
    this.emergencies = const [],
    this.dashboardStats = const {},
    this.emergencyTrends = const [],
    this.systemSettings = const {},
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.selectedFilter = 'all',
  });

  AdminState copyWith({
    List<UserModel>? users,
    List<Emergency>? emergencies,
    Map<String, dynamic>? dashboardStats,
    List<Map<String, dynamic>>? emergencyTrends,
    Map<String, dynamic>? systemSettings,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? selectedFilter,
  }) {
    return AdminState(
      users: users ?? this.users,
      emergencies: emergencies ?? this.emergencies,
      dashboardStats: dashboardStats ?? this.dashboardStats,
      emergencyTrends: emergencyTrends ?? this.emergencyTrends,
      systemSettings: systemSettings ?? this.systemSettings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }
}

// Admin provider
class AdminNotifier extends StateNotifier<AdminState> {
  AdminNotifier() : super(AdminState());

  // Load all data
  Future<void> loadAllData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final futures = await Future.wait([
        AdminService.getAllUsers(),
        AdminService.getAllEmergencies(),
        AdminService.getDashboardStats(),
        AdminService.getEmergencyTrends(),
        AdminService.getSystemSettings(),
      ]);

      state = state.copyWith(
        users: futures[0] as List<UserModel>,
        emergencies: futures[1] as List<Emergency>,
        dashboardStats: futures[2] as Map<String, dynamic>,
        emergencyTrends: futures[3] as List<Map<String, dynamic>>,
        systemSettings: futures[4] as Map<String, dynamic>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // User management
  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final users = await AdminService.getAllUsers();
      state = state.copyWith(users: users, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await AdminService.updateUserRole(userId, newRole);
      await loadUsers(); // Refresh the list
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateUserDepartment(String userId, String? department) async {
    try {
      await AdminService.updateUserDepartment(userId, department);
      await loadUsers(); // Refresh the list
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deactivateUser(String userId) async {
    try {
      await AdminService.deactivateUser(userId);
      await loadUsers(); // Refresh the list
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> activateUser(String userId) async {
    try {
      await AdminService.activateUser(userId);
      await loadUsers(); // Refresh the list
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await AdminService.deleteUser(userId);
      await loadUsers(); // Refresh the list
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Emergency management
  Future<void> loadEmergencies() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final emergencies = await AdminService.getAllEmergencies();
      state = state.copyWith(emergencies: emergencies, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadEmergenciesByStatus(String status) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final emergencies = await AdminService.getEmergenciesByStatus(status);
      state = state.copyWith(
        emergencies: emergencies,
        selectedFilter: status,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadEmergenciesByType(String type) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final emergencies = await AdminService.getEmergenciesByType(type);
      state = state.copyWith(
        emergencies: emergencies,
        selectedFilter: type,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateEmergencyStatus(
    String emergencyId,
    String newStatus,
  ) async {
    try {
      await AdminService.updateEmergencyStatus(emergencyId, newStatus);
      await loadEmergencies(); // Refresh the list
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> assignResponderToEmergency(
    String emergencyId,
    String responderId,
  ) async {
    try {
      await AdminService.assignResponderToEmergency(emergencyId, responderId);
      await loadEmergencies(); // Refresh the list
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteEmergency(String emergencyId) async {
    try {
      await AdminService.deleteEmergency(emergencyId);
      await loadEmergencies(); // Refresh the list
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Dashboard and analytics
  Future<void> loadDashboardStats() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final stats = await AdminService.getDashboardStats();
      state = state.copyWith(dashboardStats: stats, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadEmergencyTrends() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final trends = await AdminService.getEmergencyTrends();
      state = state.copyWith(emergencyTrends: trends, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // System settings
  Future<void> loadSystemSettings() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final settings = await AdminService.getSystemSettings();
      state = state.copyWith(systemSettings: settings, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateSystemSettings(Map<String, dynamic> settings) async {
    try {
      await AdminService.updateSystemSettings(settings);
      await loadSystemSettings(); // Refresh the settings
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Search functionality
  Future<void> searchUsers(String query) async {
    state = state.copyWith(isLoading: true, error: null, searchQuery: query);

    try {
      final users = await AdminService.searchUsers(query);
      state = state.copyWith(users: users, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> searchEmergencies(String query) async {
    state = state.copyWith(isLoading: true, error: null, searchQuery: query);

    try {
      final emergencies = await AdminService.searchEmergencies(query);
      state = state.copyWith(emergencies: emergencies, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Bulk operations
  Future<void> bulkUpdateUserRoles(Map<String, String> userRoleUpdates) async {
    try {
      await AdminService.bulkUpdateUserRoles(userRoleUpdates);
      await loadUsers(); // Refresh the list
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> bulkUpdateEmergencyStatuses(
    Map<String, String> emergencyStatusUpdates,
  ) async {
    try {
      await AdminService.bulkUpdateEmergencyStatuses(emergencyStatusUpdates);
      await loadEmergencies(); // Refresh the list
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Clear search
  void clearSearch() {
    state = state.copyWith(searchQuery: '', selectedFilter: 'all');
  }
}

// Providers
final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  return AdminNotifier();
});

// Filtered providers
final filteredUsersProvider = Provider<List<UserModel>>((ref) {
  final adminState = ref.watch(adminProvider);
  final users = adminState.users;
  final searchQuery = adminState.searchQuery.toLowerCase();

  if (searchQuery.isEmpty) return users;

  return users.where((user) {
    return user.name.toLowerCase().contains(searchQuery) ||
        user.email.toLowerCase().contains(searchQuery) ||
        user.role.toLowerCase().contains(searchQuery);
  }).toList();
});

final filteredEmergenciesProvider = Provider<List<Emergency>>((ref) {
  final adminState = ref.watch(adminProvider);
  final emergencies = adminState.emergencies;
  final searchQuery = adminState.searchQuery.toLowerCase();

  if (searchQuery.isEmpty) return emergencies;

  return emergencies.where((emergency) {
    return emergency.type.toLowerCase().contains(searchQuery) ||
        emergency.description.toLowerCase().contains(searchQuery) ||
        emergency.status.toLowerCase().contains(searchQuery);
  }).toList();
});

// Statistics providers
final userStatsProvider = Provider<Map<String, int>>((ref) {
  final adminState = ref.watch(adminProvider);
  final users = adminState.users;

  final roleCounts = <String, int>{};
  final departmentCounts = <String, int>{};

  for (final user in users) {
    roleCounts[user.role] = (roleCounts[user.role] ?? 0) + 1;
    if (user.department != null) {
      departmentCounts[user.department!] =
          (departmentCounts[user.department!] ?? 0) + 1;
    }
  }

  return {
    'total': users.length,
    'citizens': roleCounts['citizen'] ?? 0,
    'responders': roleCounts['responder'] ?? 0,
    'admins': roleCounts['admin'] ?? 0,
    'medical': departmentCounts['Medical'] ?? 0,
    'fire': departmentCounts['Fire'] ?? 0,
    'police': departmentCounts['Police'] ?? 0,
  };
});

final emergencyStatsProvider = Provider<Map<String, int>>((ref) {
  final adminState = ref.watch(adminProvider);
  final emergencies = adminState.emergencies;

  final statusCounts = <String, int>{};
  final typeCounts = <String, int>{};

  for (final emergency in emergencies) {
    statusCounts[emergency.status] = (statusCounts[emergency.status] ?? 0) + 1;
    typeCounts[emergency.type] = (typeCounts[emergency.type] ?? 0) + 1;
  }

  return {
    'total': emergencies.length,
    'pending': statusCounts['Pending'] ?? 0,
    'inProgress': statusCounts['In Progress'] ?? 0,
    'resolved': statusCounts['Resolved'] ?? 0,
    'medical': typeCounts['Medical'] ?? 0,
    'fire': typeCounts['Fire'] ?? 0,
    'police': typeCounts['Police'] ?? 0,
  };
});
