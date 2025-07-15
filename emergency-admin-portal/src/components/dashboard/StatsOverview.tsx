import React from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import {
  TrendingUp,
  TrendingDown,
  Users,
  Clock,
  CheckCircle2,
  AlertTriangle,
  MapPin,
  Calendar,
} from "lucide-react";

interface StatsOverviewProps {
  emergencies: any[];
  loading?: boolean;
}

export const StatsOverview: React.FC<StatsOverviewProps> = ({
  emergencies,
  loading = false,
}) => {
  if (loading) {
    return (
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {[1, 2, 3].map((i) => (
          <Card key={i} className="border-0 shadow-lg">
            <CardContent className="p-6">
              <div className="animate-pulse space-y-4">
                <div className="h-4 bg-gray-200 rounded w-1/2"></div>
                <div className="h-8 bg-gray-200 rounded w-3/4"></div>
                <div className="h-2 bg-gray-200 rounded"></div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    );
  }

  const statusCounts = emergencies.reduce((acc, emergency) => {
    const status = emergency.status || "unknown";
    acc[status] = (acc[status] || 0) + 1;
    return acc;
  }, {});

  const typeCounts = emergencies.reduce((acc, emergency) => {
    const type = emergency.type || "unknown";
    acc[type] = (acc[type] || 0) + 1;
    return acc;
  }, {});

  const totalEmergencies = emergencies.length;
  const activeEmergencies =
    (statusCounts.reported || 0) +
    (statusCounts.dispatched || 0) +
    (statusCounts.in_progress || 0);
  const resolvedEmergencies = statusCounts.resolved || 0;
  const resolutionRate =
    totalEmergencies > 0 ? (resolvedEmergencies / totalEmergencies) * 100 : 0;

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      {/* Emergency Status Overview */}
      <Card className="border-0 shadow-lg bg-gradient-to-br from-white to-blue-50">
        <CardHeader className="pb-3">
          <CardTitle className="flex items-center gap-2 text-lg">
            <div className="p-2 bg-blue-500 rounded-lg">
              <AlertTriangle className="h-5 w-5 text-white" />
            </div>
            Emergency Status
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-3">
            <div className="flex justify-between items-center">
              <span className="text-sm font-medium text-gray-600">Active</span>
              <Badge variant="destructive" className="font-semibold">
                {activeEmergencies}
              </Badge>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm font-medium text-gray-600">
                Resolved
              </span>
              <Badge variant="outline" className="font-semibold">
                {resolvedEmergencies}
              </Badge>
            </div>
            <div className="pt-2">
              <div className="flex justify-between text-sm mb-2">
                <span className="font-medium text-gray-600">
                  Resolution Rate
                </span>
                <span className="font-bold text-green-600">
                  {resolutionRate.toFixed(1)}%
                </span>
              </div>
              <Progress value={resolutionRate} className="h-2" />
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Emergency Types */}
      <Card className="border-0 shadow-lg bg-gradient-to-br from-white to-green-50">
        <CardHeader className="pb-3">
          <CardTitle className="flex items-center gap-2 text-lg">
            <div className="p-2 bg-green-500 rounded-lg">
              <MapPin className="h-5 w-5 text-white" />
            </div>
            Emergency Types
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {Object.entries(typeCounts).map(([type, count]) => (
              <div key={type} className="flex justify-between items-center">
                <span className="text-sm font-medium text-gray-600 capitalize">
                  {type.replace("_", " ")}
                </span>
                <div className="flex items-center gap-2">
                  <div className="w-16 bg-gray-200 rounded-full h-2">
                    <div
                      className="bg-green-500 h-2 rounded-full transition-all duration-500"
                      style={{ width: `${(count / totalEmergencies) * 100}%` }}
                    ></div>
                  </div>
                  <span className="text-sm font-bold text-gray-900 w-6 text-right">
                    {count}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Quick Stats */}
      <Card className="border-0 shadow-lg bg-gradient-to-br from-white to-purple-50">
        <CardHeader className="pb-3">
          <CardTitle className="flex items-center gap-2 text-lg">
            <div className="p-2 bg-purple-500 rounded-lg">
              <TrendingUp className="h-5 w-5 text-white" />
            </div>
            Quick Stats
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="text-center p-3 bg-white rounded-lg shadow-sm">
              <div className="text-2xl font-bold text-gray-900">
                {totalEmergencies}
              </div>
              <div className="text-xs text-gray-500 font-medium">Total</div>
            </div>
            <div className="text-center p-3 bg-white rounded-lg shadow-sm">
              <div className="text-2xl font-bold text-red-600">
                {activeEmergencies}
              </div>
              <div className="text-xs text-gray-500 font-medium">Active</div>
            </div>
          </div>
          <div className="flex items-center justify-between pt-2">
            <div className="flex items-center gap-2">
              <Calendar className="h-4 w-4 text-gray-400" />
              <span className="text-sm text-gray-600">Today</span>
            </div>
            <Badge variant="secondary" className="font-semibold">
              {
                emergencies.filter((e) => {
                  const today = new Date();
                  const emergencyDate = e.createdAt || new Date();
                  return emergencyDate.toDateString() === today.toDateString();
                }).length
              }{" "}
              new
            </Badge>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};
