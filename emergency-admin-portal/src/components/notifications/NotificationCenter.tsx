import React, { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { useNotifications } from "@/hooks/useNotifications";
import {
  Bell,
  AlertTriangle,
  CheckCircle,
  Clock,
  Users,
  MessageSquare,
  Settings,
  X,
  Filter,
  MoreVertical,
  Eye,
  EyeOff,
} from "lucide-react";
import { formatDistanceToNow } from "date-fns";

interface NotificationCenterProps {
  isOpen?: boolean;
  onClose?: () => void;
}

export const NotificationCenter: React.FC<NotificationCenterProps> = ({
  isOpen = true,
  onClose,
}) => {
  const [filter, setFilter] = useState<
    "all" | "unread" | "emergency" | "system"
  >("all");

  // Use real notification data
  const { notifications, unreadCount, loading, markAsRead, markAllAsRead } =
    useNotifications("admin-user-id");

  // Transform notifications to match the expected format
  const transformedNotifications = notifications.map((notification) => ({
    id: notification.id,
    type: notification.type === "emergency" ? "emergency" : "system",
    title: notification.title,
    message: notification.message,
    timestamp: notification.createdAt,
    isRead: notification.read,
    priority: notification.priority,
    actionUrl: notification.actionUrl,
    user: {
      name: "System",
      avatar: null,
    },
  }));

  const filteredNotifications = transformedNotifications.filter(
    (notification) => {
      switch (filter) {
        case "unread":
          return !notification.isRead;
        case "emergency":
          return notification.type === "emergency";
        case "system":
          return notification.type === "system";
        default:
          return true;
      }
    }
  );

  const getNotificationIcon = (type: string, priority: string) => {
    switch (type) {
      case "emergency":
        return priority === "critical" ? (
          <AlertTriangle className="h-5 w-5 text-red-500" />
        ) : (
          <AlertTriangle className="h-5 w-5 text-orange-500" />
        );
      case "responder":
        return <Users className="h-5 w-5 text-blue-500" />;
      case "system":
        return <Settings className="h-5 w-5 text-gray-500" />;
      case "user":
        return <Users className="h-5 w-5 text-green-500" />;
      default:
        return <Bell className="h-5 w-5 text-gray-500" />;
    }
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case "critical":
        return "border-l-red-500 bg-red-50";
      case "high":
        return "border-l-orange-500 bg-orange-50";
      case "medium":
        return "border-l-yellow-500 bg-yellow-50";
      case "low":
        return "border-l-green-500 bg-green-50";
      default:
        return "border-l-gray-500 bg-gray-50";
    }
  };

  const handleMarkAsRead = (notificationId: string) => {
    markAsRead(notificationId);
  };

  const handleDeleteNotification = (notificationId: string) => {
    // TODO: Implement delete notification functionality
    console.log("Delete notification:", notificationId);
  };

  if (!isOpen) return null;

  return (
    <div className="w-full">
      <Card className="bg-card border-border">
        <CardHeader className="pb-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <Bell className="h-6 w-6 text-blue-600" />
              <div>
                <CardTitle className="text-lg text-card-foreground">
                  Notifications
                </CardTitle>
                {unreadCount > 0 && (
                  <p className="text-sm text-muted-foreground">
                    {unreadCount} unread
                  </p>
                )}
              </div>
            </div>
            <div className="flex items-center gap-2">
              <Button
                variant="ghost"
                size="sm"
                onClick={markAllAsRead}
                className="cursor-pointer"
              >
                <CheckCircle className="h-4 w-4" />
              </Button>
              {onClose && (
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={onClose}
                  className="cursor-pointer"
                >
                  <X className="h-4 w-4" />
                </Button>
              )}
            </div>
          </div>

          {/* Filter Tabs */}
          <div className="flex items-center gap-1 mt-4 bg-muted p-1 rounded-lg">
            {[
              {
                id: "all",
                label: "All",
                count: transformedNotifications.length,
              },
              { id: "unread", label: "Unread", count: unreadCount },
              {
                id: "emergency",
                label: "Emergency",
                count: transformedNotifications.filter(
                  (n) => n.type === "emergency"
                ).length,
              },
              {
                id: "system",
                label: "System",
                count: transformedNotifications.filter(
                  (n) => n.type === "system"
                ).length,
              },
            ].map((tab) => (
              <button
                key={tab.id}
                onClick={() => setFilter(tab.id as any)}
                className={`flex items-center gap-2 px-3 py-1.5 rounded-md text-sm font-medium transition-all cursor-pointer ${
                  filter === tab.id
                    ? "bg-background text-blue-600 shadow-sm"
                    : "text-muted-foreground hover:text-foreground"
                }`}
              >
                {tab.label}
                {tab.count > 0 && (
                  <Badge
                    variant="outline"
                    className="text-xs px-1.5 py-0.5 min-w-[20px] h-5"
                  >
                    {tab.count}
                  </Badge>
                )}
              </button>
            ))}
          </div>
        </CardHeader>

        <CardContent className="p-0">
          {filteredNotifications.length === 0 ? (
            <div className="p-8 text-center">
              <Bell className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
              <h3 className="text-lg font-semibold text-card-foreground mb-2">
                No notifications
              </h3>
              <p className="text-muted-foreground">
                {filter === "unread"
                  ? "You're all caught up! No unread notifications."
                  : "No notifications match the selected filter."}
              </p>
            </div>
          ) : (
            <div className="divide-y divide-border">
              {filteredNotifications.map((notification) => (
                <div
                  key={notification.id}
                  className={`p-4 border-l-4 transition-all hover:bg-muted/50 ${
                    !notification.isRead
                      ? getPriorityColor(notification.priority)
                      : "border-l-border bg-card"
                  }`}
                >
                  <div className="flex items-start gap-3">
                    <div className="flex-shrink-0 mt-1">
                      {getNotificationIcon(
                        notification.type,
                        notification.priority
                      )}
                    </div>

                    <div className="flex-1 min-w-0">
                      <div className="flex items-start justify-between mb-1">
                        <h4
                          className={`text-sm font-medium ${
                            !notification.isRead
                              ? "text-card-foreground"
                              : "text-muted-foreground"
                          }`}
                        >
                          {notification.title}
                        </h4>
                        <div className="flex items-center gap-1 ml-2">
                          {!notification.isRead && (
                            <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
                          )}
                          <Button
                            variant="ghost"
                            size="sm"
                            className="h-6 w-6 p-0 cursor-pointer"
                            onClick={() => handleMarkAsRead(notification.id)}
                          >
                            {notification.isRead ? (
                              <EyeOff className="h-3 w-3" />
                            ) : (
                              <Eye className="h-3 w-3" />
                            )}
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            className="h-6 w-6 p-0 cursor-pointer"
                            onClick={() =>
                              handleDeleteNotification(notification.id)
                            }
                          >
                            <X className="h-3 w-3" />
                          </Button>
                        </div>
                      </div>

                      <p className="text-sm text-muted-foreground mb-2 line-clamp-2">
                        {notification.message}
                      </p>

                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                          <Avatar className="h-5 w-5">
                            <AvatarImage src={notification.user.avatar} />
                            <AvatarFallback className="bg-muted text-muted-foreground text-xs">
                              {notification.user.name
                                .split(" ")
                                .map((n) => n[0])
                                .join("")}
                            </AvatarFallback>
                          </Avatar>
                          <span className="text-xs text-muted-foreground">
                            {notification.user.name}
                          </span>
                        </div>

                        <div className="flex items-center gap-2">
                          <span className="text-xs text-muted-foreground">
                            {formatDistanceToNow(notification.timestamp, {
                              addSuffix: true,
                            })}
                          </span>
                          {notification.actionUrl && (
                            <Button
                              variant="outline"
                              size="sm"
                              className="h-6 text-xs px-2"
                            >
                              View
                            </Button>
                          )}
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>

        {/* Footer */}
        <div className="border-t border-border p-4">
          <div className="flex items-center justify-between">
            <Button
              variant="outline"
              size="sm"
              className="flex-1 mr-2 cursor-pointer"
            >
              <Settings className="h-4 w-4 mr-2" />
              Settings
            </Button>
            <Button
              variant="outline"
              size="sm"
              className="flex-1 ml-2 cursor-pointer"
            >
              <Filter className="h-4 w-4 mr-2" />
              Filters
            </Button>
          </div>
        </div>
      </Card>
    </div>
  );
};
