import React, { useState } from "react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { UserCard } from "@/components/users/UserCard";
import { UserStats } from "@/components/users/UserStats";
import { UserEditModal } from "@/components/users/UserEditModal";
import { UserCreateModal } from "@/components/users/UserCreateModal";
import { UserDetailsModal } from "@/components/users/UserDetailsModal";
import { ConfirmationModal } from "@/components/ui/confirmation-modal";
import { FeedbackModal } from "@/components/ui/feedback-modal";
import { useUsersRealtime, useDeleteUser, useUpdateUserStatus } from "@/hooks/useUsers";
import { UserRole, UserStatus, type User } from "@/types";
import {
  Users,
  Plus,
  Activity,
  Search,
  Grid,
  List,
} from "lucide-react";

export const UserManagement: React.FC = () => {
  const [selectedRole, setSelectedRole] = useState<UserRole | "all">("all");
  const [selectedStatus, setSelectedStatus] = useState<UserStatus | "all">(
    "all"
  );
  const [searchQuery, setSearchQuery] = useState("");
  const [viewMode, setViewMode] = useState<"grid" | "list">("grid");

  // Modal states
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [isDetailsModalOpen, setIsDetailsModalOpen] = useState(false);
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);

  // Feedback modal state
  const [feedbackModal, setFeedbackModal] = useState<{
    isOpen: boolean;
    type: "success" | "error";
    title: string;
    description: string;
  }>({
    isOpen: false,
    type: "success",
    title: "",
    description: "",
  });

  // Create stable filters object to prevent infinite re-renders
  const filters = React.useMemo(
    () => ({
      ...(selectedRole !== "all" && { role: [selectedRole] }),
      ...(selectedStatus !== "all" && { status: [selectedStatus] }),
    }),
    [selectedRole, selectedStatus]
  );

  const { users, loading } = useUsersRealtime(filters);

  // Mutations
  const deleteUserMutation = useDeleteUser();
  const updateUserStatusMutation = useUpdateUserStatus();

  // Filter users based on search query
  const filteredUsers = users.filter(
    (user) =>
      user.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      user.email?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      user.role?.toLowerCase().includes(searchQuery.toLowerCase())
  );

  // Event handlers
  const handleEditUser = (user: User) => {
    setSelectedUser(user);
    setIsEditModalOpen(true);
  };

  const handleToggleUserStatus = (user: User) => {
    setSelectedUser(user);
    setIsEditModalOpen(true);
  };

  const handleViewUserDetails = (user: User) => {
    setSelectedUser(user);
    setIsDetailsModalOpen(true);
  };

  const handleAddUser = () => {
    setIsCreateModalOpen(true);
  };

  const handleDeleteUser = (user: User) => {
    // Safety check: prevent deleting admin users if they're the only admin
    if (user.role === UserRole.ADMIN) {
      const adminCount = users.filter(u => u.role === UserRole.ADMIN).length;
      if (adminCount <= 1) {
        setFeedbackModal({
          isOpen: true,
          type: "error",
          title: "Cannot Delete Admin User",
          description: "You cannot delete the last admin user. Please create another admin user first to maintain system access.",
        });
        return;
      }
    }

    setSelectedUser(user);
    setIsDeleteModalOpen(true);
  };

  const handleConfirmDelete = async () => {
    if (!selectedUser) return;

    try {
      await deleteUserMutation.mutateAsync(selectedUser.id);
      setIsDeleteModalOpen(false);

      // Show success feedback
      setFeedbackModal({
        isOpen: true,
        type: "success",
        title: "User Deleted Successfully",
        description: `${selectedUser.name} has been permanently removed from the system.`,
      });

      setSelectedUser(null);
    } catch (error) {
      console.error("Failed to delete user:", error);

      // Show error feedback
      setFeedbackModal({
        isOpen: true,
        type: "error",
        title: "Failed to Delete User",
        description: error instanceof Error ? error.message : "An unexpected error occurred while deleting the user. Please try again.",
      });
    }
  };

  const handleToggleUserStatusAction = async (user: User) => {
    const newStatus = user.status === UserStatus.ACTIVE ? UserStatus.INACTIVE : UserStatus.ACTIVE;

    try {
      await updateUserStatusMutation.mutateAsync({
        id: user.id,
        status: newStatus,
      });
    } catch (error) {
      console.error("Failed to update user status:", error);
      // Error handling is done by the mutation
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-50">
      {/* Header Section */}
      <div className="bg-white border-b border-gray-200 shadow-sm">
        <div className="px-6 py-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-gradient-to-br from-blue-600 to-indigo-700 rounded-xl shadow-lg">
                <Users className="h-8 w-8 text-white" />
              </div>
              <div>
                <h1 className="text-3xl font-bold text-gray-900">
                  User Management
                </h1>
                <p className="text-gray-600 mt-1 flex items-center gap-4">
                  Manage users, responders, and system access
                  <Badge variant="outline" className="ml-2">
                    <Activity className="h-3 w-3 mr-1" />
                    {users.length} Users
                  </Badge>
                </p>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <div className="flex items-center gap-1 bg-gray-100 p-1 rounded-lg">
                <button
                  onClick={() => setViewMode("grid")}
                  className={`p-2 rounded-md transition-all cursor-pointer ${
                    viewMode === "grid"
                      ? "bg-white text-blue-600 shadow-sm"
                      : "text-gray-600 hover:text-gray-900"
                  }`}
                >
                  <Grid className="h-4 w-4" />
                </button>
                <button
                  onClick={() => setViewMode("list")}
                  className={`p-2 rounded-md transition-all cursor-pointer ${
                    viewMode === "list"
                      ? "bg-white text-blue-600 shadow-sm"
                      : "text-gray-600 hover:text-gray-900"
                  }`}
                >
                  <List className="h-4 w-4" />
                </button>
              </div>

              <Button
                size="sm"
                onClick={handleAddUser}
                className="cursor-pointer bg-blue-500 text-white"
              >
                <Plus className="h-4 w-4 mr-2" />
                Add User
              </Button>
            </div>
          </div>

          {/* Search and Filters */}
          <div className="flex items-center gap-4 mt-6">
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
              <input
                type="text"
                placeholder="Search users by name, email, or role..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>

            <select
              value={selectedRole}
              onChange={(e) =>
                setSelectedRole(e.target.value as UserRole | "all")
              }
              className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="all">All Roles</option>
              <option value={UserRole.ADMIN}>Admin</option>
              <option value={UserRole.RESPONDER}>Responder</option>
              <option value={UserRole.CITIZEN}>Citizen</option>
            </select>

            <select
              value={selectedStatus}
              onChange={(e) =>
                setSelectedStatus(e.target.value as UserStatus | "all")
              }
              className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="all">All Status</option>
              <option value={UserStatus.ACTIVE}>Active</option>
              <option value={UserStatus.INACTIVE}>Inactive</option>
              <option value={UserStatus.PENDING}>Pending</option>
            </select>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="px-6 py-6">
        {/* User Statistics */}
        <UserStats users={users} loading={loading} />

        {/* User Grid/List */}
        <div className="mt-8">
          {loading ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {[1, 2, 3, 4, 5, 6].map((i) => (
                <Card key={i} className="border-0 shadow-lg">
                  <CardContent className="p-6">
                    <div className="animate-pulse space-y-4">
                      <div className="flex items-center gap-4">
                        <div className="w-12 h-12 bg-gray-200 rounded-full"></div>
                        <div className="space-y-2">
                          <div className="h-4 bg-gray-200 rounded w-24"></div>
                          <div className="h-3 bg-gray-200 rounded w-16"></div>
                        </div>
                      </div>
                      <div className="space-y-2">
                        <div className="h-3 bg-gray-200 rounded w-full"></div>
                        <div className="h-3 bg-gray-200 rounded w-3/4"></div>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          ) : filteredUsers.length === 0 ? (
            <Card className="border-0 shadow-lg">
              <CardContent className="p-12 text-center">
                <Users className="h-16 w-16 text-gray-400 mx-auto mb-4" />
                <h3 className="text-lg font-semibold text-gray-900 mb-2">
                  No users found
                </h3>
                <p className="text-gray-500 mb-6">
                  {searchQuery
                    ? `No users match your search "${searchQuery}"`
                    : "No users match the selected filters"}
                </p>
                <Button onClick={handleAddUser} className="cursor-pointer">
                  <Plus className="h-4 w-4 mr-2" />
                  Add First User
                </Button>
              </CardContent>
            </Card>
          ) : (
            <div
              className={
                viewMode === "grid"
                  ? "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6"
                  : "space-y-4"
              }
            >
              {filteredUsers.map((user) => {
                const adminCount = users.filter(u => u.role === UserRole.ADMIN).length;
                const canDelete = !(user.role === UserRole.ADMIN && adminCount <= 1);

                return (
                  <UserCard
                    key={user.id}
                    user={user}
                    onEdit={handleEditUser}
                    onToggleStatus={handleToggleUserStatusAction}
                    onViewDetails={handleViewUserDetails}
                    onDelete={handleDeleteUser}
                    canDelete={canDelete}
                  />
                );
              })}
            </div>
          )}
        </div>
      </div>

      {/* Modals */}
      <UserCreateModal
        isOpen={isCreateModalOpen}
        onClose={() => setIsCreateModalOpen(false)}
      />

      <UserEditModal
        user={selectedUser}
        isOpen={isEditModalOpen}
        onClose={() => {
          setIsEditModalOpen(false);
          setSelectedUser(null);
        }}
      />

      <UserDetailsModal
        user={selectedUser}
        isOpen={isDetailsModalOpen}
        onClose={() => {
          setIsDetailsModalOpen(false);
          setSelectedUser(null);
        }}
        onEdit={(user) => {
          setIsDetailsModalOpen(false);
          setSelectedUser(user);
          setIsEditModalOpen(true);
        }}
      />

      <ConfirmationModal
        isOpen={isDeleteModalOpen}
        onClose={() => {
          setIsDeleteModalOpen(false);
          setSelectedUser(null);
        }}
        onConfirm={handleConfirmDelete}
        title="Delete User"
        description={
          selectedUser
            ? `Are you sure you want to delete "${selectedUser.name}"? This action cannot be undone and will permanently remove the user from the system.`
            : "Are you sure you want to delete this user?"
        }
        confirmText="Delete User"
        cancelText="Cancel"
        variant="danger"
        isLoading={deleteUserMutation.isPending}
      />

      <FeedbackModal
        isOpen={feedbackModal.isOpen}
        onClose={() => setFeedbackModal(prev => ({ ...prev, isOpen: false }))}
        type={feedbackModal.type}
        title={feedbackModal.title}
        description={feedbackModal.description}
        autoClose={feedbackModal.type === "success"}
        autoCloseDelay={3000}
      />
    </div>
  );
};
