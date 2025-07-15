import React, { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  MapPin,
  Zap,
  RefreshCw,
  AlertTriangle,
  Clock,
  User,
  Maximize2,
  Minimize2,
} from "lucide-react";
import {
  useRealtimeEmergencies,
  useRealtimeResponders,
} from "@/hooks/useRealtime";
import { EmergencyStatus, EmergencyPriority } from "@/types/emergency";
import { formatDistanceToNow } from "date-fns";

export const LiveEmergencyMap: React.FC = () => {
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [selectedEmergency, setSelectedEmergency] = useState<string | null>(
    null
  );

  const { emergencies, loading: emergenciesLoading } = useRealtimeEmergencies({
    status: [
      EmergencyStatus.REPORTED,
      EmergencyStatus.DISPATCHED,
      EmergencyStatus.IN_PROGRESS,
    ],
  });

  const { responders, loading: respondersLoading } = useRealtimeResponders();

  const getStatusColor = (status: EmergencyStatus) => {
    switch (status) {
      case EmergencyStatus.REPORTED:
        return "bg-red-500";
      case EmergencyStatus.DISPATCHED:
        return "bg-yellow-500";
      case EmergencyStatus.IN_PROGRESS:
        return "bg-blue-500";
      default:
        return "bg-gray-500";
    }
  };

  const getPriorityColor = (priority: EmergencyPriority) => {
    switch (priority) {
      case "critical":
        return "text-red-600 dark:text-red-400";
      case "high":
        return "text-orange-600 dark:text-orange-400";
      case "medium":
        return "text-yellow-600 dark:text-yellow-400";
      case "low":
        return "text-green-600 dark:text-green-400";
      default:
        return "text-gray-600 dark:text-gray-400";
    }
  };

  const getEmergencyIcon = (type: string) => {
    switch (type.toLowerCase()) {
      case "fire":
        return "🔥";
      case "medical":
        return "🚑";
      case "police":
        return "🚔";
      case "accident":
        return "🚗";
      default:
        return "⚠️";
    }
  };

  const onlineResponders = responders.filter((r) => r.isOnline);

  if (emergenciesLoading || respondersLoading) {
    return (
      <Card
        className={`bg-card border-border ${
          isFullscreen ? "fixed inset-4 z-50" : ""
        }`}
      >
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-card-foreground">
            <MapPin className="h-5 w-5 text-blue-500" />
            Live Emergency Map
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="h-96 flex items-center justify-center">
            <div className="animate-spin">
              <RefreshCw className="h-8 w-8 text-blue-500" />
            </div>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card
      className={`bg-card border-border ${
        isFullscreen ? "fixed inset-4 z-50" : ""
      }`}
    >
      <CardHeader>
        <CardTitle className="flex items-center justify-between text-card-foreground">
          <div className="flex items-center gap-2">
            <MapPin className="h-5 w-5 text-blue-500" />
            Live Emergency Map
            <Badge variant="outline" className="ml-2">
              {emergencies.length} Active
            </Badge>
          </div>
          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => setIsFullscreen(!isFullscreen)}
              className="cursor-pointer"
            >
              {isFullscreen ? (
                <Minimize2 className="h-4 w-4" />
              ) : (
                <Maximize2 className="h-4 w-4" />
              )}
            </Button>
          </div>
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div
          className={`${
            isFullscreen ? "h-[calc(100vh-8rem)]" : "h-96"
          } relative`}
        >
          {/* Loading State */}
          {emergenciesLoading && (
            <div className="w-full h-full bg-muted rounded-lg flex items-center justify-center">
              <div className="text-center">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500 mx-auto mb-4"></div>
                <p className="text-muted-foreground">
                  Loading emergency locations...
                </p>
              </div>
            </div>
          )}

          {/* No Emergencies State */}
          {!emergenciesLoading && emergencies.length === 0 && (
            <div className="w-full h-full bg-muted rounded-lg flex items-center justify-center">
              <div className="text-center">
                <MapPin className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                <h3 className="text-lg font-semibold text-card-foreground mb-2">
                  No Active Emergencies
                </h3>
                <p className="text-muted-foreground">
                  All clear! No emergencies are currently being tracked.
                </p>
              </div>
            </div>
          )}

          {/* Map Container with Emergencies */}
          {!emergenciesLoading && emergencies.length > 0 && (
            <div className="w-full h-full bg-muted rounded-lg relative overflow-hidden">
              {/* Map Background */}
              <div className="absolute inset-0 bg-gradient-to-br from-blue-50 to-green-50 dark:from-blue-950 dark:to-green-950">
                <div className="absolute inset-0 opacity-20">
                  <svg className="w-full h-full">
                    <defs>
                      <pattern
                        id="grid"
                        width="40"
                        height="40"
                        patternUnits="userSpaceOnUse"
                      >
                        <path
                          d="M 40 0 L 0 0 0 40"
                          fill="none"
                          stroke="currentColor"
                          strokeWidth="1"
                        />
                      </pattern>
                    </defs>
                    <rect width="100%" height="100%" fill="url(#grid)" />
                  </svg>
                </div>
              </div>

              {/* Emergency Markers */}
              {emergencies.map((emergency, index) => {
                // Use real coordinates if available, otherwise use distributed positioning
                const hasRealLocation =
                  emergency.location?.latitude && emergency.location?.longitude;
                const position = hasRealLocation
                  ? {
                      // Convert lat/lng to percentage (this is a simplified approach)
                      // In a real map, you'd use proper projection
                      left: `${Math.min(
                        Math.max(
                          ((emergency.location.longitude + 180) / 360) * 100,
                          5
                        ),
                        95
                      )}%`,
                      top: `${Math.min(
                        Math.max(
                          ((90 - emergency.location.latitude) / 180) * 100,
                          5
                        ),
                        95
                      )}%`,
                    }
                  : {
                      left: `${20 + ((index * 15) % 60)}%`,
                      top: `${20 + ((index * 20) % 60)}%`,
                    };

                return (
                  <div
                    key={emergency.id}
                    className={`absolute cursor-pointer transform -translate-x-1/2 -translate-y-1/2 transition-all duration-200 hover:scale-110 ${
                      selectedEmergency === emergency.id ? "z-20" : "z-10"
                    }`}
                    style={position}
                    onClick={() =>
                      setSelectedEmergency(
                        selectedEmergency === emergency.id ? null : emergency.id
                      )
                    }
                  >
                    {/* Emergency Marker */}
                    <div className="relative">
                      <div
                        className={`w-4 h-4 rounded-full ${getStatusColor(
                          emergency.status
                        )} animate-pulse`}
                      ></div>
                      <div className="absolute -top-1 -left-1 text-lg">
                        {getEmergencyIcon(emergency.type)}
                      </div>

                      {/* Ripple Effect */}
                      <div
                        className={`absolute inset-0 rounded-full ${getStatusColor(
                          emergency.status
                        )} opacity-30 animate-ping`}
                      ></div>
                    </div>

                    {/* Emergency Details Popup */}
                    {selectedEmergency === emergency.id && (
                      <div className="absolute top-8 left-1/2 transform -translate-x-1/2 bg-card border border-border rounded-lg shadow-lg p-3 min-w-64 z-30">
                        <div className="space-y-2">
                          <div className="flex items-center justify-between">
                            <span className="font-semibold text-card-foreground">
                              {emergency.type} Emergency
                            </span>
                            <Badge
                              className={`${getPriorityColor(
                                emergency.priority
                              )} border-current`}
                              variant="outline"
                            >
                              {emergency.priority}
                            </Badge>
                          </div>

                          <div className="text-sm text-muted-foreground">
                            <div className="flex items-center gap-1">
                              <MapPin className="h-3 w-3" />
                              {emergency.location.address}
                            </div>
                            <div className="flex items-center gap-1 mt-1">
                              <Clock className="h-3 w-3" />
                              {formatDistanceToNow(emergency.createdAt, {
                                addSuffix: true,
                              })}
                            </div>
                            {emergency.assignedResponders &&
                              emergency.assignedResponders.length > 0 && (
                                <div className="flex items-center gap-1 mt-1">
                                  <User className="h-3 w-3" />
                                  {emergency.assignedResponders.length}{" "}
                                  responder(s) assigned
                                </div>
                              )}
                          </div>

                          <Badge
                            className={`${getStatusColor(
                              emergency.status
                            )} text-white border-0`}
                          >
                            {emergency.status.replace("_", " ")}
                          </Badge>
                        </div>
                      </div>
                    )}
                  </div>
                );
              })}

              {/* Online Responder Markers */}
              {onlineResponders.slice(0, 10).map((responder, index) => (
                <div
                  key={responder.id}
                  className="absolute transform -translate-x-1/2 -translate-y-1/2 z-5"
                  style={{
                    left: `${30 + ((index * 12) % 50)}%`,
                    top: `${30 + ((index * 18) % 50)}%`,
                  }}
                >
                  <div className="w-3 h-3 bg-green-500 rounded-full border-2 border-white dark:border-gray-800">
                    <div className="absolute -top-1 -right-1 w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
                  </div>
                </div>
              ))}

              {/* Legend */}
              <div className="absolute bottom-4 left-4 bg-card/90 backdrop-blur-sm border border-border rounded-lg p-3">
                <div className="text-xs font-semibold text-card-foreground mb-2">
                  Legend
                </div>
                <div className="space-y-1 text-xs">
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 bg-red-500 rounded-full"></div>
                    <span className="text-muted-foreground">Reported</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 bg-yellow-500 rounded-full"></div>
                    <span className="text-muted-foreground">Dispatched</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 bg-blue-500 rounded-full"></div>
                    <span className="text-muted-foreground">In Progress</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 bg-green-500 rounded-full"></div>
                    <span className="text-muted-foreground">
                      Online Responder
                    </span>
                  </div>
                </div>
              </div>

              {/* Stats Overlay */}
              <div className="absolute top-4 right-4 bg-card/90 backdrop-blur-sm border border-border rounded-lg p-3">
                <div className="text-xs font-semibold text-card-foreground mb-2">
                  Live Stats
                </div>
                <div className="space-y-1 text-xs">
                  <div className="flex justify-between gap-4">
                    <span className="text-muted-foreground">Active:</span>
                    <span className="font-medium text-card-foreground">
                      {emergencies.length}
                    </span>
                  </div>
                  <div className="flex justify-between gap-4">
                    <span className="text-muted-foreground">Online:</span>
                    <span className="font-medium text-card-foreground">
                      {onlineResponders.length}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      </CardContent>
    </Card>
  );
};
