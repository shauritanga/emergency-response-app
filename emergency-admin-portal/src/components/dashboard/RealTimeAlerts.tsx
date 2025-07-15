import React from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  AlertTriangle,
  Clock,
  MapPin,
  User,
  ArrowRight,
  Zap,
} from "lucide-react";
import { formatDistanceToNow } from "date-fns";

interface RealTimeAlertsProps {
  emergencies: any[];
  loading?: boolean;
}

export const RealTimeAlerts: React.FC<RealTimeAlertsProps> = ({
  emergencies,
  loading,
}) => {
  // Get recent active emergencies (last 24 hours, reported, dispatched, or in progress)
  const recentActiveEmergencies = emergencies
    .filter((emergency) => {
      const isActive =
        emergency.status === "reported" ||
        emergency.status === "dispatched" ||
        emergency.status === "in_progress";
      const isRecent =
        emergency.createdAt &&
        new Date().getTime() - new Date(emergency.createdAt).getTime() <
          24 * 60 * 60 * 1000;
      return isActive && isRecent;
    })
    .sort(
      (a, b) =>
        new Date(b.createdAt || 0).getTime() -
        new Date(a.createdAt || 0).getTime()
    )
    .slice(0, 5);

  const getStatusColor = (status: string) => {
    switch (status) {
      case "reported":
        return "destructive";
      case "dispatched":
        return "default";
      case "in_progress":
        return "default";
      case "resolved":
        return "secondary";
      default:
        return "secondary";
    }
  };

  const getPriorityLevel = (emergency: any) => {
    // Simple priority logic based on type and time
    const hoursSinceReport = emergency.createdAt
      ? (new Date().getTime() - new Date(emergency.createdAt).getTime()) /
        (1000 * 60 * 60)
      : 0;

    if (emergency.type === "medical" || emergency.type === "fire")
      return "high";
    if (hoursSinceReport > 2) return "high";
    if (hoursSinceReport > 1) return "medium";
    return "low";
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case "high":
        return "text-red-600 bg-red-50 border-red-200";
      case "medium":
        return "text-yellow-600 bg-yellow-50 border-yellow-200";
      case "low":
        return "text-green-600 bg-green-50 border-green-200";
      default:
        return "text-gray-600 bg-gray-50 border-gray-200";
    }
  };

  const getTypeIcon = (type: string) => {
    switch (type?.toLowerCase()) {
      case "medical":
        return "🚑";
      case "fire":
        return "🔥";
      case "police":
        return "🚔";
      case "accident":
        return "🚗";
      default:
        return "⚠️";
    }
  };

  if (loading) {
    return (
      <Card className="border-0 shadow-lg">
        <CardHeader className="bg-gradient-to-r from-red-50 to-orange-50 border-b">
          <CardTitle className="flex items-center gap-2 text-lg">
            <div className="p-2 bg-red-500 rounded-lg animate-pulse">
              <Zap className="h-5 w-5 text-white" />
            </div>
            Real-time Alerts
          </CardTitle>
        </CardHeader>
        <CardContent className="p-6">
          <div className="space-y-4">
            {[1, 2, 3].map((i) => (
              <div key={i} className="animate-pulse">
                <div className="flex items-center gap-4">
                  <div className="w-12 h-12 bg-gray-200 rounded-lg"></div>
                  <div className="flex-1 space-y-2">
                    <div className="h-4 bg-gray-200 rounded w-3/4"></div>
                    <div className="h-3 bg-gray-200 rounded w-1/2"></div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="border-0 shadow-lg">
      <CardHeader className="bg-gradient-to-r from-red-50 to-orange-50 border-b">
        <CardTitle className="flex items-center justify-between">
          <div className="flex items-center gap-2 text-lg">
            <div className="p-2 bg-red-500 rounded-lg">
              <Zap className="h-5 w-5 text-white animate-pulse" />
            </div>
            Real-time Alerts
            <Badge variant="destructive" className="ml-2">
              {recentActiveEmergencies.length} Active
            </Badge>
          </div>
          {recentActiveEmergencies.length > 0 && (
            <Button variant="outline" size="sm" className="cursor-pointer">
              View All
              <ArrowRight className="h-4 w-4 ml-1" />
            </Button>
          )}
        </CardTitle>
      </CardHeader>
      <CardContent className="p-0">
        {recentActiveEmergencies.length === 0 ? (
          <div className="p-8 text-center">
            <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <AlertTriangle className="h-8 w-8 text-green-600" />
            </div>
            <h3 className="text-lg font-semibold text-gray-900 mb-2">
              All Clear
            </h3>
            <p className="text-gray-500">
              No active emergencies in the last 24 hours
            </p>
          </div>
        ) : (
          <div className="divide-y divide-gray-100">
            {recentActiveEmergencies.map((emergency, index) => {
              const priority = getPriorityLevel(emergency);
              return (
                <div
                  key={emergency.id}
                  className="p-4 hover:bg-gray-50 transition-colors cursor-pointer"
                >
                  <div className="flex items-start gap-4">
                    {/* Emergency Type Icon */}
                    <div className="flex-shrink-0">
                      <div className="w-12 h-12 bg-gray-100 rounded-lg flex items-center justify-center text-xl">
                        {getTypeIcon(emergency.type)}
                      </div>
                    </div>

                    {/* Emergency Details */}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-start justify-between mb-2">
                        <div>
                          <h4 className="text-sm font-semibold text-gray-900 truncate">
                            {emergency.description || "Emergency Report"}
                          </h4>
                          <div className="flex items-center gap-2 mt-1">
                            <Badge
                              variant={getStatusColor(emergency.status)}
                              className="text-xs"
                            >
                              {emergency.status
                                ?.replace("_", " ")
                                .toUpperCase()}
                            </Badge>
                            <div
                              className={`px-2 py-1 rounded-full text-xs font-medium border ${getPriorityColor(
                                priority
                              )}`}
                            >
                              {priority.toUpperCase()} PRIORITY
                            </div>
                          </div>
                        </div>
                        <div className="text-xs text-gray-500 text-right">
                          {emergency.createdAt &&
                            formatDistanceToNow(new Date(emergency.createdAt), {
                              addSuffix: true,
                            })}
                        </div>
                      </div>

                      {/* Emergency Metadata */}
                      <div className="flex items-center gap-4 text-xs text-gray-500">
                        <div className="flex items-center gap-1">
                          <MapPin className="h-3 w-3" />
                          <span className="truncate">
                            {emergency.location?.address ||
                              `${emergency.location?.latitude || "N/A"}, ${
                                emergency.location?.longitude || "N/A"
                              }`}
                          </span>
                        </div>
                        <div className="flex items-center gap-1">
                          <User className="h-3 w-3" />
                          <span>{emergency.reportedBy?.name || "Unknown"}</span>
                        </div>
                      </div>
                    </div>

                    {/* Action Button */}
                    <div className="flex-shrink-0">
                      <Button
                        variant="outline"
                        size="sm"
                        className="h-8 cursor-pointer"
                      >
                        Respond
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
