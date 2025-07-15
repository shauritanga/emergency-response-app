import React, { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { NotificationCenter } from "@/components/notifications/NotificationCenter";
import { NotificationPreferencesComponent } from "@/components/notifications/NotificationPreferences";
import {
  useNotifications,
  useNotificationStats,
} from "@/hooks/useNotifications";
import {
  Bell,
  Settings,
  Filter,
  Search,
  MoreVertical,
  AlertTriangle,
  CheckCircle,
  Clock,
  Users,
  MessageSquare,
} from "lucide-react";

export const Notifications: React.FC = () => {
  const [searchQuery, setSearchQuery] = useState("");
  const [activeTab, setActiveTab] = useState("all");

  // Use real notification data
  const { notifications, unreadCount, loading } =
    useNotifications("admin-user-id");
  const { stats } = useNotificationStats("admin-user-id");

  // Calculate notification stats from real data
  const notificationStats = {
    total: notifications.length,
    unread: unreadCount,
    critical: notifications.filter((n) => n.priority === "critical").length,
    high: notifications.filter((n) => n.priority === "high").length,
    medium: notifications.filter((n) => n.priority === "medium").length,
    low: notifications.filter((n) => n.priority === "low").length,
  };

  const StatCard: React.FC<{
    title: string;
    value: number;
    icon: React.ReactNode;
    variant?: "blue" | "orange" | "red" | "green";
  }> = ({ title, value, icon, variant = "blue" }) => {
    const getIconClasses = () => {
      switch (variant) {
        case "orange":
          return "p-2 rounded-lg bg-orange-100 text-orange-600";
        case "red":
          return "p-2 rounded-lg bg-red-100 text-red-600";
        case "green":
          return "p-2 rounded-lg bg-green-100 text-green-600";
        default:
          return "p-2 rounded-lg bg-blue-100 text-blue-600";
      }
    };

    return (
      <Card className="bg-card border-border">
        <CardContent className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-muted-foreground">
                {title}
              </p>
              <p className="text-2xl font-bold text-card-foreground">{value}</p>
            </div>
            <div className={getIconClasses()}>{icon}</div>
          </div>
        </CardContent>
      </Card>
    );
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-foreground">Notifications</h1>
          <p className="text-muted-foreground">
            Manage system notifications and preferences
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm">
            <Settings className="h-4 w-4 mr-2" />
            Settings
          </Button>
          <Button variant="outline" size="sm">
            <Filter className="h-4 w-4 mr-2" />
            Filter
          </Button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          title="Total Notifications"
          value={notificationStats.total}
          icon={<Bell className="h-5 w-5" />}
          variant="blue"
        />
        <StatCard
          title="Unread"
          value={notificationStats.unread}
          icon={<MessageSquare className="h-5 w-5" />}
          variant="orange"
        />
        <StatCard
          title="Critical"
          value={notificationStats.critical}
          icon={<AlertTriangle className="h-5 w-5" />}
          variant="red"
        />
        <StatCard
          title="Resolved Today"
          value={16}
          icon={<CheckCircle className="h-5 w-5" />}
          variant="green"
        />
      </div>

      {/* Search Bar */}
      <Card className="bg-card border-border">
        <CardContent className="p-4">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input
              placeholder="Search notifications..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-10"
            />
          </div>
        </CardContent>
      </Card>

      {/* Main Content */}
      <Tabs
        value={activeTab}
        onValueChange={setActiveTab}
        className="space-y-4"
      >
        <TabsList className="grid w-full grid-cols-3">
          <TabsTrigger value="all">All Notifications</TabsTrigger>
          <TabsTrigger value="preferences">Preferences</TabsTrigger>
          <TabsTrigger value="templates">Templates</TabsTrigger>
        </TabsList>

        <TabsContent value="all" className="space-y-4">
          <NotificationCenter />
        </TabsContent>

        <TabsContent value="preferences" className="space-y-4">
          <NotificationPreferencesComponent userId="admin-user-id" />
        </TabsContent>

        <TabsContent value="templates" className="space-y-4">
          <Card className="bg-card border-border">
            <CardHeader>
              <CardTitle className="text-card-foreground">
                Notification Templates
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-center py-8">
                <Bell className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                <h3 className="text-lg font-medium text-card-foreground mb-2">
                  Template Management
                </h3>
                <p className="text-muted-foreground mb-4">
                  Notification template management coming soon
                </p>
                <Button variant="outline">
                  <Settings className="h-4 w-4 mr-2" />
                  Configure Templates
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
};
