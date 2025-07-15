import React from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";
import { Badge } from "@/components/ui/badge";
import {
  PieChart,
  BarChart3,
  TrendingUp,
  AlertTriangle,
  Clock,
  MapPin,
  Users,
  Activity,
} from "lucide-react";

interface EmergencyChartsProps {
  emergencies: any[];
  loading?: boolean;
}

export const EmergencyStatusChart: React.FC<{ emergencies: any[] }> = ({
  emergencies,
}) => {
  const statusCounts = emergencies.reduce((acc, emergency) => {
    const status = emergency.status || "unknown";
    acc[status] = (acc[status] || 0) + 1;
    return acc;
  }, {});

  const total = emergencies.length;
  const statusData = [
    {
      name: "Reported",
      count: statusCounts.reported || 0,
      color: "bg-red-500",
      textColor: "text-red-700",
    },
    {
      name: "Dispatched",
      count: statusCounts.dispatched || 0,
      color: "bg-orange-500",
      textColor: "text-orange-700",
    },
    {
      name: "In Progress",
      count: statusCounts.in_progress || 0,
      color: "bg-yellow-500",
      textColor: "text-yellow-700",
    },
    {
      name: "Resolved",
      count: statusCounts.resolved || 0,
      color: "bg-green-500",
      textColor: "text-green-700",
    },
  ];

  return (
    <Card className="border-0 shadow-lg">
      <CardHeader className="pb-3">
        <CardTitle className="flex items-center gap-2 text-lg">
          <div className="p-2 bg-blue-500 rounded-lg">
            <PieChart className="h-5 w-5 text-white" />
          </div>
          Emergency Status Distribution
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {statusData.map((status) => (
            <div key={status.name} className="space-y-2">
              <div className="flex justify-between items-center">
                <span className="text-sm font-medium text-gray-700">
                  {status.name}
                </span>
                <div className="flex items-center gap-2">
                  <span className="text-sm font-bold">{status.count}</span>
                  <Badge variant="outline" className="text-xs">
                    {total > 0 ? Math.round((status.count / total) * 100) : 0}%
                  </Badge>
                </div>
              </div>
              <div className="relative">
                <div className="w-full bg-gray-200 rounded-full h-3">
                  <div
                    className={`h-3 rounded-full transition-all duration-700 ${status.color}`}
                    style={{
                      width: `${total > 0 ? (status.count / total) * 100 : 0}%`,
                    }}
                  ></div>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Summary */}
        <div className="mt-6 p-4 bg-gray-50 rounded-lg">
          <div className="grid grid-cols-3 gap-4 text-center">
            <div>
              <div className="text-2xl font-bold text-red-600">
                {statusCounts.pending || 0}
              </div>
              <div className="text-xs text-gray-500">Critical</div>
            </div>
            <div>
              <div className="text-2xl font-bold text-yellow-600">
                {statusCounts.in_progress || 0}
              </div>
              <div className="text-xs text-gray-500">Active</div>
            </div>
            <div>
              <div className="text-2xl font-bold text-green-600">
                {statusCounts.resolved || 0}
              </div>
              <div className="text-xs text-gray-500">Resolved</div>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
};

export const EmergencyTypeChart: React.FC<{ emergencies: any[] }> = ({
  emergencies,
}) => {
  const typeCounts = emergencies.reduce((acc, emergency) => {
    const type = emergency.type || "unknown";
    acc[type] = (acc[type] || 0) + 1;
    return acc;
  }, {});

  const typeData = Object.entries(typeCounts)
    .map(([type, count]) => ({
      name: type.charAt(0).toUpperCase() + type.slice(1),
      count: count as number,
      percentage:
        emergencies.length > 0
          ? ((count as number) / emergencies.length) * 100
          : 0,
    }))
    .sort((a, b) => b.count - a.count);

  const getTypeIcon = (type: string) => {
    switch (type.toLowerCase()) {
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

  const getTypeColor = (index: number) => {
    const colors = [
      "bg-red-500",
      "bg-blue-500",
      "bg-green-500",
      "bg-yellow-500",
      "bg-purple-500",
    ];
    return colors[index % colors.length];
  };

  return (
    <Card className="border-0 shadow-lg">
      <CardHeader className="pb-3">
        <CardTitle className="flex items-center gap-2 text-lg">
          <div className="p-2 bg-green-500 rounded-lg">
            <BarChart3 className="h-5 w-5 text-white" />
          </div>
          Emergency Types
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {typeData.map((type, index) => (
            <div
              key={type.name}
              className="flex items-center justify-between p-3 bg-gray-50 rounded-lg"
            >
              <div className="flex items-center gap-3">
                <div className="text-2xl">{getTypeIcon(type.name)}</div>
                <div>
                  <div className="font-medium text-gray-900">{type.name}</div>
                  <div className="text-sm text-gray-500">
                    {type.percentage.toFixed(1)}% of total
                  </div>
                </div>
              </div>
              <div className="flex items-center gap-3">
                <div className="text-right">
                  <div className="text-lg font-bold text-gray-900">
                    {type.count}
                  </div>
                  <div className="text-xs text-gray-500">cases</div>
                </div>
                <div className="w-16 bg-gray-200 rounded-full h-2">
                  <div
                    className={`h-2 rounded-full transition-all duration-700 ${getTypeColor(
                      index
                    )}`}
                    style={{ width: `${type.percentage}%` }}
                  ></div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
};

export const RecentActivityChart: React.FC<{ emergencies: any[] }> = ({
  emergencies,
}) => {
  // Get emergencies from last 7 days
  const last7Days = Array.from({ length: 7 }, (_, i) => {
    const date = new Date();
    date.setDate(date.getDate() - i);
    return date;
  }).reverse();

  const dailyData = last7Days.map((date) => {
    const dayEmergencies = emergencies.filter((emergency) => {
      const emergencyDate = emergency.createdAt || new Date();
      return emergencyDate.toDateString() === date.toDateString();
    });

    return {
      date: date.toLocaleDateString("en-US", {
        weekday: "short",
        month: "short",
        day: "numeric",
      }),
      count: dayEmergencies.length,
      resolved: dayEmergencies.filter((e) => e.status === "resolved").length,
    };
  });

  const maxCount = Math.max(...dailyData.map((d) => d.count), 1);

  return (
    <Card className="border-0 shadow-lg">
      <CardHeader className="pb-3">
        <CardTitle className="flex items-center gap-2 text-lg">
          <div className="p-2 bg-purple-500 rounded-lg">
            <TrendingUp className="h-5 w-5 text-white" />
          </div>
          7-Day Activity Trend
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {dailyData.map((day, index) => (
            <div key={index} className="flex items-center gap-4">
              <div className="w-16 text-sm font-medium text-gray-600">
                {day.date}
              </div>
              <div className="flex-1 flex items-center gap-2">
                <div className="flex-1 bg-gray-200 rounded-full h-6 relative overflow-hidden">
                  <div
                    className="bg-blue-500 h-full transition-all duration-700 rounded-full"
                    style={{ width: `${(day.count / maxCount) * 100}%` }}
                  ></div>
                  <div
                    className="bg-green-500 h-full absolute top-0 left-0 transition-all duration-700 rounded-full"
                    style={{ width: `${(day.resolved / maxCount) * 100}%` }}
                  ></div>
                </div>
                <div className="text-sm font-bold text-gray-900 w-8 text-right">
                  {day.count}
                </div>
              </div>
            </div>
          ))}
        </div>

        <div className="mt-4 flex items-center gap-4 text-sm">
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 bg-blue-500 rounded-full"></div>
            <span className="text-gray-600">Total Reports</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 bg-green-500 rounded-full"></div>
            <span className="text-gray-600">Resolved</span>
          </div>
        </div>
      </CardContent>
    </Card>
  );
};
