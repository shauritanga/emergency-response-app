import React from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Activity,
  AlertTriangle,
  CheckCircle,
  Clock,
  User,
  MapPin,
  RefreshCw,
  ExternalLink,
} from "lucide-react";
import { useRecentActivity } from "@/hooks/useRealtime";
import { formatDistanceToNow } from "date-fns";

export const ActivityFeed: React.FC = () => {
  const { recentActivity, loading, error } = useRecentActivity(15);

  const getActivityIcon = (type: string) => {
    switch (type) {
      case "new_emergency":
        return <AlertTriangle className="h-4 w-4 text-red-500" />;
      case "status_change":
        return <RefreshCw className="h-4 w-4 text-blue-500" />;
      case "assignment":
        return <User className="h-4 w-4 text-purple-500" />;
      case "resolved":
        return <CheckCircle className="h-4 w-4 text-green-500" />;
      default:
        return <Activity className="h-4 w-4 text-gray-500" />;
    }
  };

  const getActivityColor = (type: string) => {
    switch (type) {
      case "new_emergency":
        return "border-l-red-500";
      case "status_change":
        return "border-l-blue-500";
      case "assignment":
        return "border-l-purple-500";
      case "resolved":
        return "border-l-green-500";
      default:
        return "border-l-gray-500";
    }
  };

  const getEmergencyTypeIcon = (type: string) => {
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

  if (loading) {
    return (
      <Card className="bg-card border-border">
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-card-foreground">
            <Activity className="h-5 w-5 text-blue-500" />
            Recent Activity
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {[1, 2, 3, 4, 5].map((i) => (
              <div key={i} className="animate-pulse">
                <div className="flex items-start gap-3">
                  <div className="w-8 h-8 bg-muted rounded-full"></div>
                  <div className="flex-1 space-y-2">
                    <div className="h-4 bg-muted rounded w-3/4"></div>
                    <div className="h-3 bg-muted rounded w-1/2"></div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    );
  }

  if (error) {
    return (
      <Card className="bg-card border-border">
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-card-foreground">
            <Activity className="h-5 w-5 text-red-500" />
            Recent Activity
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center gap-2 text-red-600 dark:text-red-400">
            <AlertTriangle className="h-4 w-4" />
            <span className="text-sm">Failed to load activity feed</span>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="bg-card border-border">
      <CardHeader>
        <CardTitle className="flex items-center justify-between text-card-foreground">
          <div className="flex items-center gap-2">
            <Activity className="h-5 w-5 text-blue-500" />
            Recent Activity
          </div>
          <Badge variant="outline" className="text-xs">
            Live
          </Badge>
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-4 max-h-96 overflow-y-auto">
          {recentActivity.length === 0 ? (
            <div className="text-center py-8">
              <Activity className="h-12 w-12 text-muted-foreground mx-auto mb-3" />
              <p className="text-muted-foreground text-sm">
                No recent activity to display
              </p>
            </div>
          ) : (
            recentActivity.map((activity) => (
              <div
                key={activity.id}
                className={`flex items-start gap-3 p-3 rounded-lg border-l-4 bg-muted/30 ${getActivityColor(
                  activity.type
                )}`}
              >
                <div className="flex-shrink-0 mt-0.5">
                  {getActivityIcon(activity.type)}
                </div>
                
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-2">
                    <div className="flex-1">
                      <p className="text-sm font-medium text-card-foreground">
                        {activity.message}
                      </p>
                      
                      <div className="flex items-center gap-4 mt-1 text-xs text-muted-foreground">
                        <div className="flex items-center gap-1">
                          <span className="text-lg">
                            {getEmergencyTypeIcon(activity.emergency.type)}
                          </span>
                          <span>{activity.emergency.type}</span>
                        </div>
                        
                        {activity.emergency.location && (
                          <div className="flex items-center gap-1">
                            <MapPin className="h-3 w-3" />
                            <span className="truncate max-w-32">
                              {activity.emergency.location.address}
                            </span>
                          </div>
                        )}
                        
                        <Badge
                          variant="outline"
                          className="text-xs px-1 py-0"
                        >
                          {activity.emergency.status.replace("_", " ")}
                        </Badge>
                      </div>
                    </div>
                    
                    <div className="flex items-center gap-2 flex-shrink-0">
                      <div className="text-xs text-muted-foreground">
                        {formatDistanceToNow(activity.timestamp, {
                          addSuffix: true,
                        })}
                      </div>
                      
                      <Button
                        variant="ghost"
                        size="sm"
                        className="h-6 w-6 p-0 cursor-pointer"
                        title="View emergency details"
                      >
                        <ExternalLink className="h-3 w-3" />
                      </Button>
                    </div>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
        
        {recentActivity.length > 0 && (
          <div className="mt-4 pt-4 border-t border-border">
            <Button
              variant="outline"
              size="sm"
              className="w-full cursor-pointer"
            >
              View All Activity
            </Button>
          </div>
        )}
      </CardContent>
    </Card>
  );
};
