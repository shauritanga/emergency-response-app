import React from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { type User, UserRole, UserStatus } from "@/types";
import {
  Users,
  Clock,
  MapPin,
  Phone,
  Mail,
  Eye,
  Edit,
  Shield,
  Activity,
  UserCheck,
  UserX,
} from "lucide-react";
import { formatDistanceToNow } from "date-fns";

interface UserListProps {
  users: User[];
  loading?: boolean;
  onViewDetails: (user: User) => void;
  onEditUser: (user: User) => void;
  onUpdateStatus: (user: User) => void;
  onUpdateRole: (user: User) => void;
}

export const UserList: React.FC<UserListProps> = ({
  users,
  loading,
  onViewDetails,
  onEditUser,
  onUpdateStatus,
  onUpdateRole: _onUpdateRole, // Renamed to indicate it's intentionally unused
}) => {
  const getStatusColor = (status: UserStatus) => {
    switch (status) {
      case UserStatus.ACTIVE:
        return "default";
      case UserStatus.INACTIVE:
        return "secondary";
      case UserStatus.SUSPENDED:
        return "destructive";
      case UserStatus.PENDING:
        return "outline";
      default:
        return "secondary";
    }
  };

  const getRoleColor = (role: UserRole) => {
    switch (role) {
      case UserRole.ADMIN:
        return "text-purple-600 bg-purple-50";
      case UserRole.RESPONDER:
        return "text-blue-600 bg-blue-50";
      case UserRole.CITIZEN:
        return "text-green-600 bg-green-50";
      default:
        return "text-gray-600 bg-gray-50";
    }
  };

  const getRoleIcon = (role: UserRole) => {
    switch (role) {
      case UserRole.ADMIN:
        return Shield;
      case UserRole.RESPONDER:
        return UserCheck;
      case UserRole.CITIZEN:
        return Users;
      default:
        return Users;
    }
  };

  if (loading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Users</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center justify-center h-32">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Users className="h-5 w-5" />
          Users ({users.length})
        </CardTitle>
      </CardHeader>
      <CardContent>
        {users.length === 0 ? (
          <div className="text-center py-8 text-muted-foreground">
            No users found
          </div>
        ) : (
          <div className="space-y-4">
            {users.map((user) => {
              const RoleIcon = getRoleIcon(user.role);

              return (
                <div
                  key={user.id}
                  className="border rounded-lg p-4 hover:bg-gray-50 transition-colors"
                >
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="flex items-center gap-3 mb-2">
                        <div className="relative">
                          <div className="w-10 h-10 bg-gray-200 rounded-full flex items-center justify-center">
                            {user.avatar ? (
                              <img
                                src={user.avatar}
                                alt={user.name}
                                className="w-10 h-10 rounded-full object-cover"
                              />
                            ) : (
                              <span className="text-gray-600 font-medium">
                                {user.name.charAt(0).toUpperCase()}
                              </span>
                            )}
                          </div>
                          {user.isOnline && (
                            <div className="absolute -bottom-1 -right-1 w-3 h-3 bg-green-500 rounded-full border-2 border-white"></div>
                          )}
                        </div>

                        <div className="flex-1">
                          <h3 className="font-semibold text-gray-900">
                            {user.name}
                          </h3>
                          <div className="flex items-center gap-2 mt-1">
                            <Badge
                              variant={getStatusColor(user.status)}
                              className="text-xs"
                            >
                              {user.status.replace("_", " ").toUpperCase()}
                            </Badge>
                            <div
                              className={`px-2 py-1 rounded-full text-xs font-medium flex items-center gap-1 ${getRoleColor(
                                user.role
                              )}`}
                            >
                              <RoleIcon className="h-3 w-3" />
                              {user.role.toUpperCase()}
                            </div>
                          </div>
                        </div>
                      </div>

                      <div className="grid grid-cols-1 md:grid-cols-2 gap-2 text-sm text-gray-600 mb-3">
                        <div className="flex items-center gap-1">
                          <Mail className="h-3 w-3" />
                          {user.email}
                        </div>
                        {user.phone && (
                          <div className="flex items-center gap-1">
                            <Phone className="h-3 w-3" />
                            {user.phone}
                          </div>
                        )}
                        {user.department && (
                          <div className="flex items-center gap-1">
                            <Shield className="h-3 w-3" />
                            {user.department}
                          </div>
                        )}
                        {user.location?.address && (
                          <div className="flex items-center gap-1">
                            <MapPin className="h-3 w-3" />
                            {user.location.address}
                          </div>
                        )}
                      </div>

                      <div className="flex items-center gap-4 text-xs text-muted-foreground">
                        <div className="flex items-center gap-1">
                          <Clock className="h-3 w-3" />
                          Joined{" "}
                          {formatDistanceToNow(user.createdAt, {
                            addSuffix: true,
                          })}
                        </div>
                        <div className="flex items-center gap-1">
                          <Activity className="h-3 w-3" />
                          {user.isOnline ? (
                            <span className="text-green-600">Online</span>
                          ) : (
                            <span>
                              Last seen{" "}
                              {formatDistanceToNow(user.lastSeen, {
                                addSuffix: true,
                              })}
                            </span>
                          )}
                        </div>

                        {/* Responder specific info */}
                        {user.role === UserRole.RESPONDER &&
                          "availability" in user && (
                            <div className="flex items-center gap-1">
                              <UserCheck className="h-3 w-3" />
                              <span
                                className={
                                  user.availability === "available"
                                    ? "text-green-600"
                                    : user.availability === "busy"
                                    ? "text-red-600"
                                    : "text-gray-600"
                                }
                              >
                                {typeof user.availability === "string"
                                  ? user.availability
                                      .replace("_", " ")
                                      .toUpperCase()
                                  : ""}
                              </span>
                            </div>
                          )}
                      </div>
                    </div>

                    <div className="flex flex-col gap-2 ml-4">
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => onViewDetails(user)}
                        className="text-xs"
                      >
                        <Eye className="h-3 w-3 mr-1" />
                        View
                      </Button>
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => onEditUser(user)}
                        className="text-xs"
                      >
                        <Edit className="h-3 w-3 mr-1" />
                        Edit
                      </Button>
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => onUpdateStatus(user)}
                        className="text-xs"
                      >
                        {user.status === UserStatus.ACTIVE ? (
                          <UserX className="h-3 w-3 mr-1" />
                        ) : (
                          <UserCheck className="h-3 w-3 mr-1" />
                        )}
                        Status
                      </Button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </CardContent>
    </Card>
  );
};
