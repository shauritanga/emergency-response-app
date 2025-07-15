import React from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import {
  Activity,
  Users,
  AlertTriangle,
  Clock,
  Wifi,
  WifiOff,
  AlertCircle,
} from "lucide-react";
import { useSystemMetrics } from "@/hooks/useRealtime";
import { formatDistanceToNow } from "date-fns";

export const SystemMetricsCard: React.FC = () => {
  const { metrics, loading, error } = useSystemMetrics();

  if (loading) {
    return (
      <Card className="bg-card border-border">
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-card-foreground">
            <Activity className="h-5 w-5 text-blue-500" />
            System Metrics
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {[1, 2, 3, 4].map((i) => (
              <div key={i} className="animate-pulse">
                <div className="h-4 bg-muted rounded w-3/4 mb-2"></div>
                <div className="h-6 bg-muted rounded w-1/2"></div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    );
  }

  if (error || !metrics) {
    return (
      <Card className="bg-card border-border">
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-card-foreground">
            <Activity className="h-5 w-5 text-red-500" />
            System Metrics
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center gap-2 text-red-600 dark:text-red-400">
            <AlertCircle className="h-4 w-4" />
            <span className="text-sm">Failed to load system metrics</span>
          </div>
        </CardContent>
      </Card>
    );
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case "online":
        return "bg-green-100 text-green-800 border-green-200 dark:bg-green-900/20 dark:text-green-400 dark:border-green-800";
      case "degraded":
        return "bg-yellow-100 text-yellow-800 border-yellow-200 dark:bg-yellow-900/20 dark:text-yellow-400 dark:border-yellow-800";
      case "offline":
        return "bg-red-100 text-red-800 border-red-200 dark:bg-red-900/20 dark:text-red-400 dark:border-red-800";
      default:
        return "bg-gray-100 text-gray-800 border-gray-200 dark:bg-gray-900/20 dark:text-gray-400 dark:border-gray-800";
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case "online":
        return <Wifi className="h-4 w-4" />;
      case "degraded":
        return <AlertTriangle className="h-4 w-4" />;
      case "offline":
        return <WifiOff className="h-4 w-4" />;
      default:
        return <AlertCircle className="h-4 w-4" />;
    }
  };

  const responderOnlinePercentage =
    metrics.totalResponders > 0
      ? (metrics.onlineResponders / metrics.totalResponders) * 100
      : 0;

  return (
    <Card className="bg-card border-border">
      <CardHeader>
        <CardTitle className="flex items-center justify-between text-card-foreground">
          <div className="flex items-center gap-2">
            <Activity className="h-5 w-5 text-blue-500" />
            System Metrics
          </div>
          <Badge className={getStatusColor(metrics.systemStatus)}>
            {getStatusIcon(metrics.systemStatus)}
            <span className="ml-1 capitalize">{metrics.systemStatus}</span>
          </Badge>
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-6">
        {/* Active Emergencies */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <AlertTriangle className="h-4 w-4 text-red-500" />
            <span className="text-sm font-medium text-card-foreground">
              Active Emergencies
            </span>
          </div>
          <div className="text-right">
            <div className="text-2xl font-bold text-card-foreground">
              {metrics.activeEmergencies}
            </div>
          </div>
        </div>

        {/* Responder Status */}
        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Users className="h-4 w-4 text-blue-500" />
              <span className="text-sm font-medium text-card-foreground">
                Responders Online
              </span>
            </div>
            <div className="text-right">
              <div className="text-lg font-semibold text-card-foreground">
                {metrics.onlineResponders} / {metrics.totalResponders}
              </div>
              <div className="text-xs text-muted-foreground">
                {responderOnlinePercentage.toFixed(1)}% online
              </div>
            </div>
          </div>
          
          {/* Progress bar */}
          <div className="w-full bg-muted rounded-full h-2">
            <div
              className={`h-2 rounded-full transition-all duration-300 ${
                responderOnlinePercentage >= 70
                  ? "bg-green-500"
                  : responderOnlinePercentage >= 30
                  ? "bg-yellow-500"
                  : "bg-red-500"
              }`}
              style={{ width: `${responderOnlinePercentage}%` }}
            ></div>
          </div>
        </div>

        {/* Average Response Time */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Clock className="h-4 w-4 text-green-500" />
            <span className="text-sm font-medium text-card-foreground">
              Avg Response Time
            </span>
          </div>
          <div className="text-right">
            <div className="text-lg font-semibold text-card-foreground">
              {metrics.averageResponseTime > 0
                ? `${metrics.averageResponseTime.toFixed(1)} min`
                : "N/A"}
            </div>
          </div>
        </div>

        {/* Last Updated */}
        <div className="pt-2 border-t border-border">
          <div className="flex items-center justify-between text-xs text-muted-foreground">
            <span>Last updated</span>
            <span>
              {formatDistanceToNow(metrics.lastUpdated, { addSuffix: true })}
            </span>
          </div>
        </div>
      </CardContent>
    </Card>
  );
};
