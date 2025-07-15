import React from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { type User, UserRole, UserStatus } from "@/types";
import { formatDistanceToNow } from "date-fns";
import {
  User as UserIcon,
  Mail,
  Phone,
  MapPin,
  Shield,
  Activity,
  Clock,
  Calendar,
  Edit,
  X,
  Globe,
} from "lucide-react";

interface UserDetailsModalProps {
  user: User | null;
  isOpen: boolean;
  onClose: () => void;
  onEdit?: (user: User) => void;
}

export const UserDetailsModal: React.FC<UserDetailsModalProps> = ({
  user,
  isOpen,
  onClose,
  onEdit,
}) => {
  if (!user) return null;

  const getRoleColor = (role: UserRole) => {
    switch (role) {
      case UserRole.ADMIN:
        return "bg-red-100 text-red-800 border-red-200";
      case UserRole.RESPONDER:
        return "bg-blue-100 text-blue-800 border-blue-200";
      case UserRole.CITIZEN:
        return "bg-green-100 text-green-800 border-green-200";
      default:
        return "bg-gray-100 text-gray-800 border-gray-200";
    }
  };

  const getStatusColor = (status: UserStatus) => {
    switch (status) {
      case UserStatus.ACTIVE:
        return "bg-green-100 text-green-800 border-green-200";
      case UserStatus.INACTIVE:
        return "bg-gray-100 text-gray-800 border-gray-200";
      case UserStatus.PENDING:
        return "bg-yellow-100 text-yellow-800 border-yellow-200";
      default:
        return "bg-gray-100 text-gray-800 border-gray-200";
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto bg-white">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-3">
            <div className="p-2 bg-blue-100 rounded-lg">
              <UserIcon className="h-5 w-5 text-blue-600" />
            </div>
            User Details: {user.name}
          </DialogTitle>
        </DialogHeader>

        <div className="space-y-6">
          {/* User Overview */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="text-sm font-medium text-gray-600">
                  Role
                </CardTitle>
              </CardHeader>
              <CardContent>
                <Badge className={getRoleColor(user.role)}>{user.role}</Badge>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="text-sm font-medium text-gray-600">
                  Status
                </CardTitle>
              </CardHeader>
              <CardContent>
                <Badge className={getStatusColor(user.status)}>
                  {user.status}
                </Badge>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="text-sm font-medium text-gray-600">
                  Online Status
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="flex items-center gap-2">
                  <div
                    className={`w-2 h-2 rounded-full ${
                      user.isOnline ? "bg-green-500" : "bg-gray-400"
                    }`}
                  ></div>
                  <span className="text-sm font-medium">
                    {user.isOnline ? "Online" : "Offline"}
                  </span>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Contact Information */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Mail className="h-5 w-5" />
                Contact Information
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="flex items-center gap-3">
                  <Mail className="h-4 w-4 text-gray-400" />
                  <div>
                    <p className="text-sm font-medium text-gray-600">Email</p>
                    <p className="text-sm">{user.email || "Not provided"}</p>
                  </div>
                </div>

                <div className="flex items-center gap-3">
                  <Phone className="h-4 w-4 text-gray-400" />
                  <div>
                    <p className="text-sm font-medium text-gray-600">Phone</p>
                    <p className="text-sm">{user.phone || "Not provided"}</p>
                  </div>
                </div>
              </div>

              {user.location && (
                <div className="flex items-start gap-3">
                  <MapPin className="h-4 w-4 text-gray-400 mt-1" />
                  <div>
                    <p className="text-sm font-medium text-gray-600">
                      Location
                    </p>
                    <p className="text-sm">
                      {user.location.address || "Address not available"}
                    </p>
                    <p className="text-xs text-gray-500">
                      {user.location.city}, {user.location.state}
                    </p>
                    <p className="text-xs text-gray-500">
                      Coordinates: {user.location.latitude},{" "}
                      {user.location.longitude}
                    </p>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Professional Information */}
          {(user.role === UserRole.RESPONDER ||
            user.role === UserRole.ADMIN) && (
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Shield className="h-5 w-5" />
                  Professional Information
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                {user.department && (
                  <div className="flex items-center gap-3">
                    <Shield className="h-4 w-4 text-gray-400" />
                    <div>
                      <p className="text-sm font-medium text-gray-600">
                        Department
                      </p>
                      <p className="text-sm">{user.department}</p>
                    </div>
                  </div>
                )}

                {user.specializations && user.specializations.length > 0 && (
                  <div className="flex items-start gap-3">
                    <Activity className="h-4 w-4 text-gray-400 mt-1" />
                    <div>
                      <p className="text-sm font-medium text-gray-600">
                        Specializations
                      </p>
                      <div className="flex flex-wrap gap-2 mt-1">
                        {user.specializations.map((spec, index) => (
                          <Badge
                            key={index}
                            variant="outline"
                            className="text-xs"
                          >
                            {spec}
                          </Badge>
                        ))}
                      </div>
                    </div>
                  </div>
                )}
              </CardContent>
            </Card>
          )}

          {/* Activity Information */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Activity className="h-5 w-5" />
                Activity Information
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="flex items-center gap-3">
                  <Clock className="h-4 w-4 text-gray-400" />
                  <div>
                    <p className="text-sm font-medium text-gray-600">
                      Last Seen
                    </p>
                    <p className="text-sm">
                      {formatDistanceToNow(user.lastSeen, { addSuffix: true })}
                    </p>
                  </div>
                </div>

                <div className="flex items-center gap-3">
                  <Activity className="h-4 w-4 text-gray-400" />
                  <div>
                    <p className="text-sm font-medium text-gray-600">
                      Last Active
                    </p>
                    <p className="text-sm">
                      {formatDistanceToNow(user.lastActive, {
                        addSuffix: true,
                      })}
                    </p>
                  </div>
                </div>

                <div className="flex items-center gap-3">
                  <Calendar className="h-4 w-4 text-gray-400" />
                  <div>
                    <p className="text-sm font-medium text-gray-600">
                      Member Since
                    </p>
                    <p className="text-sm">
                      {user.createdAt.toLocaleDateString()}
                    </p>
                  </div>
                </div>

                <div className="flex items-center gap-3">
                  <Globe className="h-4 w-4 text-gray-400" />
                  <div>
                    <p className="text-sm font-medium text-gray-600">
                      Profile Updated
                    </p>
                    <p className="text-sm">
                      {user.updatedAt.toLocaleDateString()}
                    </p>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* System Information */}
          {user.metadata && Object.keys(user.metadata).length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Activity className="h-5 w-5" />
                  System Information
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {user.metadata.deviceToken && (
                    <div>
                      <p className="text-sm font-medium text-gray-600">
                        Device Token
                      </p>
                      <p className="text-xs text-gray-500 font-mono break-all">
                        {user.metadata.deviceToken}
                      </p>
                    </div>
                  )}

                  {user.metadata.notificationPreferences && (
                    <div>
                      <p className="text-sm font-medium text-gray-600">
                        Notification Preferences
                      </p>
                      <p className="text-sm text-gray-500">
                        {JSON.stringify(user.metadata.notificationPreferences)}
                      </p>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
          )}
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={onClose}>
            <X className="h-4 w-4 mr-2" />
            Close
          </Button>
          {onEdit && (
            <Button onClick={() => onEdit(user)}>
              <Edit className="h-4 w-4 mr-2" />
              Edit User
            </Button>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};
