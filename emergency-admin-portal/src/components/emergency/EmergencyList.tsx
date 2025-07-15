import React from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { EmergencyStatus, EmergencyPriority, EmergencyType } from "@/types";
import {
  AlertTriangle,
  Clock,
  MapPin,
  User,
  Eye,
  UserPlus,
} from "lucide-react";
import { formatDistanceToNow } from "date-fns";

interface EmergencyListProps {
  emergencies: any[]; // Use any[] to handle flexible data structure
  loading?: boolean;
  onViewDetails: (emergency: any) => void;
  onAssignResponder: (emergency: any) => void;
  onUpdateStatus: (emergency: any) => void;
}

export const EmergencyList: React.FC<EmergencyListProps> = ({
  emergencies,
  loading,
  onViewDetails,
  onAssignResponder,
  onUpdateStatus,
}) => {
  const getStatusColor = (status: EmergencyStatus | string | undefined) => {
    if (!status) return "secondary";

    switch (status) {
      case EmergencyStatus.REPORTED:
      case "reported":
        return "destructive";
      case EmergencyStatus.DISPATCHED:
      case "dispatched":
        return "default";
      case EmergencyStatus.IN_PROGRESS:
      case "in_progress":
      case "active":
        return "secondary";
      case EmergencyStatus.RESOLVED:
      case "resolved":
        return "outline";
      default:
        return "default";
    }
  };

  const getPriorityColor = (
    priority: EmergencyPriority | string | undefined
  ) => {
    if (!priority) return "text-gray-600 bg-gray-50";

    switch (priority) {
      case EmergencyPriority.CRITICAL:
      case "critical":
        return "text-red-600 bg-red-50";
      case EmergencyPriority.HIGH:
      case "high":
        return "text-orange-600 bg-orange-50";
      case EmergencyPriority.MEDIUM:
      case "medium":
        return "text-yellow-600 bg-yellow-50";
      case EmergencyPriority.LOW:
      case "low":
        return "text-green-600 bg-green-50";
      default:
        return "text-gray-600 bg-gray-50";
    }
  };

  const getTypeIcon = (type: EmergencyType | string | undefined) => {
    if (!type) return "⚠️";

    switch (type) {
      case EmergencyType.FIRE:
      case "fire":
        return "🔥";
      case EmergencyType.MEDICAL:
      case "medical":
        return "🚑";
      case EmergencyType.POLICE:
      case "police":
        return "🚔";
      case EmergencyType.NATURAL_DISASTER:
      case "natural_disaster":
        return "🌪️";
      case EmergencyType.ACCIDENT:
      case "accident":
        return "🚗";
      case EmergencyType.SECURITY:
      case "security":
        return "🔒";
      default:
        return "⚠️";
    }
  };

  if (loading) {
    return (
      <Card className="border-0 shadow-lg">
        <CardHeader className="bg-gradient-to-r from-gray-50 to-gray-100 border-b">
          <CardTitle className="text-xl font-bold text-gray-800">
            Active Emergencies
          </CardTitle>
        </CardHeader>
        <CardContent className="p-8">
          <div className="flex flex-col items-center justify-center h-32 space-y-4">
            <div className="relative">
              <div className="animate-spin rounded-full h-12 w-12 border-4 border-blue-200"></div>
              <div className="animate-spin rounded-full h-12 w-12 border-4 border-blue-600 border-t-transparent absolute top-0"></div>
            </div>
            <p className="text-gray-500 font-medium">Loading emergencies...</p>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="border-0 shadow-lg">
      <CardHeader className="bg-gradient-to-r from-red-50 to-orange-50 border-b">
        <CardTitle className="flex items-center gap-3 text-xl font-bold text-gray-800">
          <div className="p-2 bg-red-500 rounded-lg shadow-sm">
            <AlertTriangle className="h-5 w-5 text-white" />
          </div>
          Active Emergencies ({emergencies.length})
        </CardTitle>
      </CardHeader>
      <CardContent>
        {emergencies.length === 0 ? (
          <div className="text-center py-8 text-muted-foreground">
            No active emergencies
          </div>
        ) : (
          <div className="space-y-4">
            {emergencies.map((emergency) => (
              <div
                key={emergency.id}
                className="bg-white border border-gray-200 rounded-xl p-6 hover:shadow-lg hover:border-gray-300 transition-all duration-300 transform hover:-translate-y-1"
              >
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-3 mb-3">
                      <div className="text-2xl p-2 bg-gray-100 rounded-lg">
                        {getTypeIcon(emergency.type)}
                      </div>
                      <h3 className="font-bold text-lg text-gray-900">
                        {emergency.title ||
                          emergency.description ||
                          "Untitled Emergency"}
                      </h3>
                      <div className="flex items-center gap-2 ml-auto">
                        <Badge
                          variant={getStatusColor(emergency.status)}
                          className="text-xs font-semibold px-3 py-1"
                        >
                          {emergency.status
                            ? emergency.status.replace("_", " ").toUpperCase()
                            : "UNKNOWN"}
                        </Badge>
                        <div
                          className={`px-3 py-1 rounded-full text-xs font-semibold shadow-sm ${getPriorityColor(
                            emergency.priority
                          )}`}
                        >
                          {emergency.priority
                            ? emergency.priority.toUpperCase()
                            : "MEDIUM"}
                        </div>
                      </div>
                    </div>

                    <p className="text-gray-600 mb-4 leading-relaxed">
                      {emergency.description ||
                        emergency.title ||
                        "No description available"}
                    </p>

                    <div className="flex items-center gap-6 text-sm text-gray-500 bg-gray-50 rounded-lg p-3">
                      <div className="flex items-center gap-2">
                        <MapPin className="h-4 w-4 text-blue-500" />
                        <span className="font-medium">
                          {emergency.location?.address ||
                            (emergency.location?.latitude &&
                            emergency.location?.longitude
                              ? `${emergency.location.latitude}, ${emergency.location.longitude}`
                              : "Location not available")}
                        </span>
                      </div>
                      <div className="flex items-center gap-2">
                        <User className="h-4 w-4 text-green-500" />
                        <span className="font-medium">
                          {emergency.reportedBy?.name || "Unknown reporter"}
                        </span>
                      </div>
                      <div className="flex items-center gap-2">
                        <Clock className="h-4 w-4 text-amber-500" />
                        <span className="font-medium">
                          {emergency.createdAt
                            ? formatDistanceToNow(emergency.createdAt, {
                                addSuffix: true,
                              })
                            : "Time not available"}
                        </span>
                      </div>
                      {emergency.assignedResponders &&
                        emergency.assignedResponders.length > 0 && (
                          <div className="flex items-center gap-1">
                            <UserPlus className="h-3 w-3" />
                            {emergency.assignedResponders.length} responder(s)
                          </div>
                        )}
                    </div>
                  </div>

                  <div className="flex flex-col gap-2 ml-4">
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => onViewDetails(emergency)}
                      className="text-xs"
                    >
                      <Eye className="h-3 w-3 mr-1" />
                      View
                    </Button>
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => onAssignResponder(emergency)}
                      className="text-xs"
                    >
                      <UserPlus className="h-3 w-3 mr-1" />
                      Assign
                    </Button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
};
