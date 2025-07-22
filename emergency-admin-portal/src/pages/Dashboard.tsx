import React from "react";
import { MetricsCard } from "@/components/dashboard/MetricsCard";
import { RealTimeAlerts } from "@/components/dashboard/RealTimeAlerts";
import {
  EmergencyStatusChart,
  EmergencyTypeChart,
  RecentActivityChart,
} from "@/components/charts/EmergencyCharts";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";

import { useEmergenciesRealtime } from "@/hooks/useEmergencies";
import {
  AlertTriangle,
  Clock,
  CheckCircle,
  Activity,
  BarChart3,
} from "lucide-react";

export const Dashboard: React.FC = () => {
  // Get all emergencies for comprehensive dashboard view
  const { emergencies, loading: emergenciesLoading } = useEmergenciesRealtime();

  // Get emergency statistics (for future use)
  // const { data: stats } = useEmergencyStats();

  // Calculate key metrics
  const activeEmergencies = emergencies.filter(
    (e: any) =>
      e.status === "reported" ||
      e.status === "dispatched" ||
      e.status === "in_progress"
  );
  const resolvedToday = emergencies.filter((e: any) => {
    const today = new Date();
    const emergencyDate = new Date(e.createdAt || new Date());
    return (
      e.status === "resolved" &&
      emergencyDate.toDateString() === today.toDateString()
    );
  });

  const criticalEmergencies = emergencies.filter(
    (e: any) =>
      (e.status === "pending" || e.status === "in_progress") &&
      (e.type === "medical" || e.type === "fire")
  );

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-50">
      {/* Header Section */}
      <div className="bg-white border-b border-gray-200 shadow-sm">
        <div className="px-6 py-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-gradient-to-br from-blue-600 to-indigo-700 rounded-xl shadow-lg">
                <BarChart3 className="h-8 w-8 text-white" />
              </div>
              <div>
                <h1 className="text-3xl font-bold text-gray-900">
                  Emergency Response Dashboard
                </h1>
                <p className="text-gray-600 mt-1 flex items-center gap-4">
                  Real-time monitoring and emergency management overview
                  <Badge variant="outline" className="ml-2">
                    <Activity className="h-3 w-3 mr-1" />
                    Live
                  </Badge>
                </p>
              </div>
            </div>


          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="px-6 py-6">
        {/* Key Metrics Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <MetricsCard
            title="Critical Alerts"
            value={criticalEmergencies.length}
            description="Requires immediate attention"
            icon={AlertTriangle}
            gradient="from-red-500 to-red-600"
            iconBg="bg-red-500"
            badge={{
              text: criticalEmergencies.length > 0 ? "URGENT" : "Clear",
              variant:
                criticalEmergencies.length > 0 ? "destructive" : "outline",
            }}
          />

          <MetricsCard
            title="Active Cases"
            value={activeEmergencies.length}
            description="Currently being handled"
            icon={Activity}
            gradient="from-blue-500 to-indigo-600"
            iconBg="bg-blue-500"
            trend={{
              value: 12,
              isPositive: false,
            }}
          />

          <MetricsCard
            title="Response Time"
            value="4.2 min"
            description="Average response time"
            icon={Clock}
            gradient="from-amber-500 to-orange-600"
            iconBg="bg-amber-500"
            trend={{
              value: 8,
              isPositive: true,
            }}
          />

          <MetricsCard
            title="Resolved Today"
            value={resolvedToday.length}
            description="Successfully completed"
            icon={CheckCircle}
            gradient="from-emerald-500 to-green-600"
            iconBg="bg-emerald-500"
            badge={{
              text: "Excellent",
              variant: "outline",
            }}
          />
        </div>

        {/* Dashboard Content */}
        <div className="space-y-8">
          {/* Charts Section */}
          <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
            <EmergencyStatusChart emergencies={emergencies} />
            <EmergencyTypeChart emergencies={emergencies} />
            <RecentActivityChart emergencies={emergencies} />
          </div>

          {/* Real-time Alerts */}
          <RealTimeAlerts
            emergencies={emergencies}
            loading={emergenciesLoading}
          />
        </div>
      </div>
    </div>
  );
};
