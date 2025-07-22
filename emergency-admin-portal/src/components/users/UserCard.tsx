import React from "react";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import {
  User,
  Mail,
  Phone,
  MapPin,
  Calendar,
  Shield,
  UserCheck,
  UserX,
  Edit,
  MoreVertical,
  Activity,
  Trash2,
} from "lucide-react";
import { formatDistanceToNow } from "date-fns";

interface UserCardProps {
  user: any;
  onEdit?: (user: any) => void;
  onToggleStatus?: (user: any) => void;
  onViewDetails?: (user: any) => void;
  onDelete?: (user: any) => void;
  canDelete?: boolean;
}

export const UserCard: React.FC<UserCardProps> = ({
  user,
  onEdit,
  onToggleStatus,
  onViewDetails,
  onDelete,
  canDelete = true,
}) => {
  const getRoleColor = (role: string) => {
    switch (role?.toLowerCase()) {
      case "admin":
        return "bg-purple-100 text-purple-800 border-purple-200";
      case "responder":
        return "bg-blue-100 text-blue-800 border-blue-200";
      case "citizen":
        return "bg-green-100 text-green-800 border-green-200";
      default:
        return "bg-gray-100 text-gray-800 border-gray-200";
    }
  };

  const getStatusColor = (status: string) => {
    switch (status?.toLowerCase()) {
      case "active":
        return "bg-green-100 text-green-800 border-green-200";
      case "inactive":
        return "bg-red-100 text-red-800 border-red-200";
      case "pending":
        return "bg-yellow-100 text-yellow-800 border-yellow-200";
      default:
        return "bg-gray-100 text-gray-800 border-gray-200";
    }
  };

  const getRoleIcon = (role: string) => {
    switch (role?.toLowerCase()) {
      case "admin":
        return Shield;
      case "responder":
        return UserCheck;
      case "citizen":
        return User;
      default:
        return User;
    }
  };

  const RoleIcon = getRoleIcon(user.role);

  return (
    <Card className="hover:shadow-lg transition-all duration-300 border-0 shadow-md">
      <CardContent className="p-6">
        <div className="flex items-start justify-between mb-4">
          <div className="flex items-center gap-4">
            <Avatar className="h-12 w-12">
              <AvatarImage src={user.avatar} alt={user.name} />
              <AvatarFallback className="bg-gradient-to-br from-blue-500 to-indigo-600 text-white font-semibold">
                {user.name
                  ?.split(" ")
                  .map((n: string) => n[0])
                  .join("")
                  .toUpperCase() || "U"}
              </AvatarFallback>
            </Avatar>
            <div>
              <h3 className="font-semibold text-lg text-gray-900">
                {user.name || "Unknown User"}
              </h3>
              <div className="flex items-center gap-2 mt-1">
                <div
                  className={`flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium border ${getRoleColor(
                    user.role
                  )}`}
                >
                  <RoleIcon className="h-3 w-3" />
                  {user.role?.toUpperCase() || "UNKNOWN"}
                </div>
                <div
                  className={`px-2 py-1 rounded-full text-xs font-medium border ${getStatusColor(
                    user.status
                  )}`}
                >
                  {user.status?.toUpperCase() || "UNKNOWN"}
                </div>
              </div>
            </div>
          </div>

          <Button
            variant="ghost"
            size="sm"
            className="h-8 w-8 p-0 cursor-pointer"
          >
            <MoreVertical className="h-4 w-4" />
          </Button>
        </div>

        <div className="space-y-3 mb-4">
          {user.email && (
            <div className="flex items-center gap-2 text-sm text-gray-600">
              <Mail className="h-4 w-4 text-blue-500" />
              <span>{user.email}</span>
            </div>
          )}

          {user.phone && (
            <div className="flex items-center gap-2 text-sm text-gray-600">
              <Phone className="h-4 w-4 text-green-500" />
              <span>{user.phone}</span>
            </div>
          )}

          {user.location && (
            <div className="flex items-center gap-2 text-sm text-gray-600">
              <MapPin className="h-4 w-4 text-red-500" />
              <span>
                {user.location.address ||
                  `${user.location.city || ""}, ${user.location.state || ""}`
                    .trim()
                    .replace(/^,\s*/, "") ||
                  "Location available"}
              </span>
            </div>
          )}

          {user.createdAt && (
            <div className="flex items-center gap-2 text-sm text-gray-600">
              <Calendar className="h-4 w-4 text-purple-500" />
              <span>
                Joined{" "}
                {formatDistanceToNow(new Date(user.createdAt), {
                  addSuffix: true,
                })}
              </span>
            </div>
          )}

          {user.lastActive && (
            <div className="flex items-center gap-2 text-sm text-gray-600">
              <Activity className="h-4 w-4 text-orange-500" />
              <span>
                Last active{" "}
                {formatDistanceToNow(new Date(user.lastActive), {
                  addSuffix: true,
                })}
              </span>
            </div>
          )}
        </div>

        <div className="flex items-center gap-2 pt-4 border-t border-gray-100">
          <Button
            variant="outline"
            size="sm"
            onClick={() => onViewDetails?.(user)}
            className="flex-1 cursor-pointer"
          >
            View Details
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={() => onEdit?.(user)}
            className="cursor-pointer"
          >
            <Edit className="h-4 w-4" />
          </Button>
          <Button
            variant={user.status === "active" ? "destructive" : "default"}
            size="sm"
            onClick={() => onToggleStatus?.(user)}
            className="cursor-pointer"
          >
            {user.status === "active" ? (
              <UserX className="h-4 w-4" />
            ) : (
              <UserCheck className="h-4 w-4" />
            )}
          </Button>
          {canDelete && (
            <Button
              variant="destructive"
              size="sm"
              onClick={() => onDelete?.(user)}
              className="cursor-pointer"
            >
              <Trash2 className="h-4 w-4" />
            </Button>
          )}
        </div>
      </CardContent>
    </Card>
  );
};
