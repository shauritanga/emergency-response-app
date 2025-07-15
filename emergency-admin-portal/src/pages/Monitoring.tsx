import React from "react";
import { SystemMetricsCard } from "@/components/monitoring/SystemMetricsCard";
import { LiveEmergencyMap } from "@/components/monitoring/LiveEmergencyMap";
import { ActivityFeed } from "@/components/monitoring/ActivityFeed";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import {
  useActiveEmergenciesCount,
  useOnlineRespondersCount,
  useEmergencyStats,
} from "@/hooks/useRealtime";
import {
  AlertTriangle,
  Users,
  TrendingUp,
  Clock,
  CheckCircle,
  XCircle,
} from "lucide-react";

const StatCard: React.FC<{
  title: string;
  value: string | number;
  subtitle?: string;
  icon: React.ReactNode;
  trend?: {
    value: number;
    isPositive: boolean;
  };
  color?: string;
}> = ({ title, value, subtitle, icon, trend, color = "blue" }) => {
  return (
    <Card className="bg-card border-border">
      <CardContent className="p-6">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-sm font-medium text-muted-foreground">{title}</p>
            <div className="flex items-baseline gap-2">
              <p className="text-2xl font-bold text-card-foreground">{value}</p>
              {trend && (
                <Badge
                  variant="outline"
                  className={`text-xs ${
                    trend.isPositive
                      ? "text-green-600 border-green-200 dark:text-green-400 dark:border-green-800"
                      : "text-red-600 border-red-200 dark:text-red-400 dark:border-red-800"
                  }`}
                >
                  <TrendingUp
                    className={`h-3 w-3 mr-1 ${
                      trend.isPositive ? "" : "rotate-180"
                    }`}
                  />
                  {Math.abs(trend.value)}%
                </Badge>
              )}
            </div>
            {subtitle && (
              <p className="text-xs text-muted-foreground mt-1">{subtitle}</p>
            )}
          </div>
          <div
            className={`p-3 rounded-full bg-${color}-100 dark:bg-${color}-900/30`}
          >
            <div className={`text-${color}-600 dark:text-${color}-400`}>
              {icon}
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
};

export const Monitoring: React.FC = () => {
  const { count: activeEmergencies, loading: emergenciesLoading } =
    useActiveEmergenciesCount();
  const {
    onlineCount,
    totalCount,
    percentage: onlinePercentage,
    loading: respondersLoading,
  } = useOnlineRespondersCount();
  const { stats, loading: statsLoading } = useEmergencyStats();

  const resolvedToday = stats.byStatus?.resolved || 0;
  const totalToday = stats.total || 0;
  const resolutionRate = totalToday > 0 ? (resolvedToday / totalToday) * 100 : 0;

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-card-foreground">
            Real-time Monitoring
          </h1>
          <p className="text-muted-foreground">
            Live system status and emergency tracking
          </p>
        </div>
        <Badge
          variant="outline"
          className="text-green-600 border-green-200 dark:text-green-400 dark:border-green-800"
        >
          <div className="w-2 h-2 bg-green-500 rounded-full mr-2 animate-pulse"></div>
          Live
        </Badge>
      </div>

      {/* Key Metrics Row */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard
          title="Active Emergencies"
          value={emergenciesLoading ? "..." : activeEmergencies}
          subtitle="Requiring attention"
          icon={<AlertTriangle className="h-5 w-5" />}
          color="red"
        />
        
        <StatCard
          title="Online Responders"
          value={respondersLoading ? "..." : `${onlineCount}/${totalCount}`}
          subtitle={`${onlinePercentage.toFixed(1)}% availability`}
          icon={<Users className="h-5 w-5" />}
          color="green"
        />
        
        <StatCard
          title="Resolution Rate"
          value={statsLoading ? "..." : `${resolutionRate.toFixed(1)}%`}
          subtitle="Today's performance"
          icon={<CheckCircle className="h-5 w-5" />}
          color="blue"
        />
        
        <StatCard
          title="Avg Response Time"
          value={statsLoading ? "..." : "4.2 min"}
          subtitle="Last 24 hours"
          icon={<Clock className="h-5 w-5" />}
          color="purple"
        />
      </div>

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column - System Metrics */}
        <div className="space-y-6">
          <SystemMetricsCard />
          
          {/* Emergency Status Breakdown */}
          <Card className="bg-card border-border">
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-card-foreground">
                <AlertTriangle className="h-5 w-5 text-orange-500" />
                Emergency Status
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {[
                  {
                    status: "reported",
                    count: stats.byStatus?.reported || 0,
                    color: "red",
                    icon: <AlertTriangle className="h-4 w-4" />,
                  },
                  {
                    status: "dispatched",
                    count: stats.byStatus?.dispatched || 0,
                    color: "yellow",
                    icon: <Clock className="h-4 w-4" />,
                  },
                  {
                    status: "in_progress",
                    count: stats.byStatus?.in_progress || 0,
                    color: "blue",
                    icon: <Users className="h-4 w-4" />,
                  },
                  {
                    status: "resolved",
                    count: stats.byStatus?.resolved || 0,
                    color: "green",
                    icon: <CheckCircle className="h-4 w-4" />,
                  },
                ].map((item) => (
                  <div
                    key={item.status}
                    className="flex items-center justify-between p-2 rounded-lg bg-muted/30"
                  >
                    <div className="flex items-center gap-2">
                      <div className={`text-${item.color}-600 dark:text-${item.color}-400`}>
                        {item.icon}
                      </div>
                      <span className="text-sm font-medium text-card-foreground capitalize">
                        {item.status.replace("_", " ")}
                      </span>
                    </div>
                    <Badge
                      variant="outline"
                      className={`text-${item.color}-600 border-${item.color}-200 dark:text-${item.color}-400 dark:border-${item.color}-800`}
                    >
                      {item.count}
                    </Badge>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Center Column - Live Map */}
        <div className="lg:col-span-2">
          <LiveEmergencyMap />
        </div>
      </div>

      {/* Bottom Row - Activity Feed */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2">
          <ActivityFeed />
        </div>
        
        {/* Emergency Types Breakdown */}
        <Card className="bg-card border-border">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-card-foreground">
              <TrendingUp className="h-5 w-5 text-blue-500" />
              Emergency Types
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {Object.entries(stats.byType || {}).map(([type, count]) => (
                <div
                  key={type}
                  className="flex items-center justify-between p-2 rounded-lg bg-muted/30"
                >
                  <div className="flex items-center gap-2">
                    <span className="text-lg">
                      {type === "fire"
                        ? "🔥"
                        : type === "medical"
                        ? "🚑"
                        : type === "police"
                        ? "🚔"
                        : "⚠️"}
                    </span>
                    <span className="text-sm font-medium text-card-foreground capitalize">
                      {type}
                    </span>
                  </div>
                  <Badge variant="outline">{count}</Badge>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};
