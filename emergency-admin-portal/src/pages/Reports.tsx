import React, { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { EmergencyTrendsChart } from "@/components/charts/EmergencyTrendsChart";
import {
  PieChart,
  colorPalettes,
  getColorForItem,
} from "@/components/charts/PieChart";
import { BarChart } from "@/components/charts/BarChart";
import {
  useEmergencyAnalytics,
  useResponderAnalytics,
  useSystemAnalytics,
  useDateRange,
  useReportGeneration,
} from "@/hooks/useAnalytics";
import { useActionFeedback } from "@/hooks/useActionFeedback";
import {
  BarChart3,
  Download,
  Calendar,
  TrendingUp,
  Users,
  AlertTriangle,
  Clock,
  RefreshCw,
} from "lucide-react";
import { formatDistanceToNow } from "date-fns";

export const Reports: React.FC = () => {
  const [activeTab, setActiveTab] = useState<
    "emergency" | "responder" | "system"
  >("emergency");
  const { dateRange, setPresetRange } = useDateRange();
  const { generateReport, loading: reportLoading } = useReportGeneration();
  const { executeAction, SuccessModal, ErrorModal, LoadingModal } =
    useActionFeedback();

  const {
    analytics: emergencyAnalytics,
    loading: emergencyLoading,
    refresh: refreshEmergency,
  } = useEmergencyAnalytics(dateRange);

  const {
    analytics: responderAnalytics,
    loading: responderLoading,
    refresh: refreshResponder,
  } = useResponderAnalytics(dateRange);

  const {
    analytics: systemAnalytics,
    loading: systemLoading,
    refresh: refreshSystem,
  } = useSystemAnalytics(dateRange);

  const handleGenerateReport = async () => {
    const result = await executeAction(
      async () => {
        return await generateReport(activeTab, dateRange);
      },
      {
        loadingTitle: "Generating Report",
        loadingMessage: `Creating ${activeTab} analytics report...`,
        successTitle: "Report Generated",
        successMessage: `${
          activeTab.charAt(0).toUpperCase() + activeTab.slice(1)
        } report has been generated successfully`,
        errorTitle: "Report Generation Failed",
        errorMessage: "Unable to generate report. Please try again.",
        showDetails: true,
        autoCloseSuccess: false,
        retryable: true,
      }
    );

    if (result) {
      // In a real implementation, this would trigger a download
      console.log("Report generated successfully:", result);
    }
  };

  const tabs = [
    { id: "emergency", label: "Emergency Analytics", icon: AlertTriangle },
    { id: "responder", label: "Responder Performance", icon: Users },
    { id: "system", label: "System Performance", icon: BarChart3 },
  ];

  const presetRanges = [
    { value: "today", label: "Today" },
    { value: "week", label: "Last 7 days" },
    { value: "month", label: "Last 30 days" },
    { value: "quarter", label: "Last 3 months" },
    { value: "year", label: "Last year" },
  ];

  const renderEmergencyAnalytics = () => {
    if (emergencyLoading || !emergencyAnalytics) {
      return (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {[1, 2, 3, 4].map((i) => (
            <Card key={i} className="bg-card border-border">
              <CardContent className="p-6">
                <div className="animate-pulse space-y-4">
                  <div className="h-4 bg-muted rounded w-1/2"></div>
                  <div className="h-32 bg-muted rounded"></div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      );
    }

    if (!emergencyAnalytics) return null;

    const statusData = Object.entries(
      emergencyAnalytics.emergenciesByStatus
    ).map(([status, count], index) => ({
      label: status.replace("_", " ").replace(/\b\w/g, (l) => l.toUpperCase()),
      value: count,
      color: getColorForItem(status, "status", index),
    }));

    const typeData = Object.entries(emergencyAnalytics.emergenciesByType).map(
      ([type, count], index) => ({
        label: type.replace(/\b\w/g, (l) => l.toUpperCase()),
        value: count,
        color: getColorForItem(type, "type", index),
      })
    );

    const priorityData = Object.entries(
      emergencyAnalytics.emergenciesByPriority
    ).map(([priority, count], index) => ({
      label: priority.replace(/\b\w/g, (l) => l.toUpperCase()),
      value: count,
      color: getColorForItem(priority, "priority", index),
    }));

    const hourlyData = emergencyAnalytics.hourlyDistribution.map((item) => ({
      label: `${item.hour}:00`,
      value: item.count,
      color: "#3b82f6",
    }));

    return (
      <div className="space-y-6">
        {/* Key Metrics */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
          <Card className="bg-card border-border">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-muted-foreground">
                    Total Emergencies
                  </p>
                  <p className="text-2xl font-bold text-card-foreground">
                    {emergencyAnalytics.totalEmergencies}
                  </p>
                </div>
                <AlertTriangle className="h-8 w-8 text-red-500" />
              </div>
            </CardContent>
          </Card>

          <Card className="bg-card border-border">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-muted-foreground">
                    Resolution Rate
                  </p>
                  <p className="text-2xl font-bold text-card-foreground">
                    {emergencyAnalytics.resolutionRate.toFixed(1)}%
                  </p>
                </div>
                <TrendingUp className="h-8 w-8 text-green-500" />
              </div>
            </CardContent>
          </Card>

          <Card className="bg-card border-border">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-muted-foreground">
                    Avg Response Time
                  </p>
                  <p className="text-2xl font-bold text-card-foreground">
                    {emergencyAnalytics.averageResponseTime.toFixed(1)}m
                  </p>
                </div>
                <Clock className="h-8 w-8 text-blue-500" />
              </div>
            </CardContent>
          </Card>

          <Card className="bg-card border-border">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-muted-foreground">
                    Resolved
                  </p>
                  <p className="text-2xl font-bold text-card-foreground">
                    {emergencyAnalytics.resolvedEmergencies}
                  </p>
                </div>
                <Users className="h-8 w-8 text-purple-500" />
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Charts */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <EmergencyTrendsChart
            data={emergencyAnalytics.dailyTrends}
            title="Emergency Trends Over Time"
          />
          <PieChart data={statusData} title="Emergency Status Distribution" />
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <PieChart data={typeData} title="Emergency Types" />
          <BarChart data={hourlyData} title="Hourly Distribution" />
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <PieChart data={priorityData} title="Priority Distribution" />
          <Card className="bg-card border-border">
            <CardHeader>
              <CardTitle className="text-card-foreground">
                Top Locations
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {emergencyAnalytics.topLocations
                  .slice(0, 5)
                  .map((location, index) => (
                    <div
                      key={index}
                      className="flex items-center justify-between p-3 rounded-lg bg-muted/30"
                    >
                      <div>
                        <div className="font-medium text-card-foreground">
                          {location.location}
                        </div>
                        <div className="text-sm text-muted-foreground">
                          Avg response: {location.avgResponseTime.toFixed(1)}m
                        </div>
                      </div>
                      <Badge variant="outline">{location.count}</Badge>
                    </div>
                  ))}
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    );
  };

  const renderResponderAnalytics = () => {
    if (responderLoading || !responderAnalytics) {
      return (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {[1, 2, 3, 4].map((i) => (
            <Card key={i} className="bg-card border-border">
              <CardContent className="p-6">
                <div className="animate-pulse space-y-4">
                  <div className="h-4 bg-muted rounded w-1/2"></div>
                  <div className="h-32 bg-muted rounded"></div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      );
    }

    if (!responderAnalytics) return null;

    const departmentData = Object.entries(
      responderAnalytics.departmentStats
    ).map(([dept, stats], index) => ({
      label: dept.replace(/\b\w/g, (l) => l.toUpperCase()),
      value: stats.count,
      color: getColorForItem(dept, "department", index),
    }));

    const responseTimeData = responderAnalytics.responseTimeDistribution.map(
      (item) => ({
        label: item.range,
        value: item.count,
        color: "#22c55e",
      })
    );

    return (
      <div className="space-y-6">
        {/* Key Metrics */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <Card className="bg-card border-border">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-muted-foreground">
                    Total Responders
                  </p>
                  <p className="text-2xl font-bold text-card-foreground">
                    {responderAnalytics.totalResponders}
                  </p>
                </div>
                <Users className="h-8 w-8 text-blue-500" />
              </div>
            </CardContent>
          </Card>

          <Card className="bg-card border-border">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-muted-foreground">
                    Active Now
                  </p>
                  <p className="text-2xl font-bold text-card-foreground">
                    {responderAnalytics.activeResponders}
                  </p>
                </div>
                <TrendingUp className="h-8 w-8 text-green-500" />
              </div>
            </CardContent>
          </Card>

          <Card className="bg-card border-border">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-muted-foreground">
                    Avg Response
                  </p>
                  <p className="text-2xl font-bold text-card-foreground">
                    {responderAnalytics.averageResponseTime.toFixed(1)}m
                  </p>
                </div>
                <Clock className="h-8 w-8 text-purple-500" />
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Charts and Tables */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <PieChart data={departmentData} title="Responders by Department" />
          <BarChart
            data={responseTimeData}
            title="Response Time Distribution"
            horizontal
          />
        </div>

        {/* Top Performers */}
        <Card className="bg-card border-border">
          <CardHeader>
            <CardTitle className="text-card-foreground">
              Top Performers
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {responderAnalytics.topPerformers
                .slice(0, 10)
                .map((performer, index) => (
                  <div
                    key={index}
                    className="flex items-center justify-between p-3 rounded-lg bg-muted/30"
                  >
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 bg-blue-100 dark:bg-blue-900/30 rounded-full flex items-center justify-center">
                        <span className="text-sm font-medium text-blue-600 dark:text-blue-400">
                          #{index + 1}
                        </span>
                      </div>
                      <div>
                        <div className="font-medium text-card-foreground">
                          {performer.name}
                        </div>
                        <div className="text-sm text-muted-foreground">
                          {performer.completedEmergencies} completed •{" "}
                          {performer.averageResponseTime.toFixed(1)}m avg
                        </div>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <div className="text-right">
                        <div className="text-sm font-medium text-card-foreground">
                          ⭐ {performer.rating.toFixed(1)}
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
            </div>
          </CardContent>
        </Card>
      </div>
    );
  };

  const renderSystemAnalytics = () => {
    if (systemLoading || !systemAnalytics) {
      return (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {[1, 2, 3, 4].map((i) => (
            <Card key={i} className="bg-card border-border">
              <CardContent className="p-6">
                <div className="animate-pulse space-y-4">
                  <div className="h-4 bg-muted rounded w-1/2"></div>
                  <div className="h-32 bg-muted rounded"></div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      );
    }

    if (!systemAnalytics) return null;

    const geographicData = systemAnalytics.geographicDistribution.map(
      (item) => ({
        label: item.area,
        value: item.count,
        color: "#8b5cf6",
      })
    );

    const monthlyData = systemAnalytics.monthlyComparison.map((item) => ({
      label: item.month,
      value: item.emergencies,
      color: "#06b6d4",
    }));

    return (
      <div className="space-y-6">
        {/* Key Metrics */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <Card className="bg-card border-border">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-muted-foreground">
                    System Uptime
                  </p>
                  <p className="text-2xl font-bold text-card-foreground">
                    {systemAnalytics.systemUptime}%
                  </p>
                </div>
                <TrendingUp className="h-8 w-8 text-green-500" />
              </div>
            </CardContent>
          </Card>

          <Card className="bg-card border-border">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-muted-foreground">
                    System Load
                  </p>
                  <p className="text-2xl font-bold text-card-foreground">
                    {systemAnalytics.averageSystemLoad}%
                  </p>
                </div>
                <BarChart3 className="h-8 w-8 text-blue-500" />
              </div>
            </CardContent>
          </Card>

          <Card className="bg-card border-border">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-muted-foreground">
                    Peak Hour
                  </p>
                  <p className="text-2xl font-bold text-card-foreground">
                    {systemAnalytics.peakHours[0]?.hour || 0}:00
                  </p>
                </div>
                <Clock className="h-8 w-8 text-purple-500" />
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Charts */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <BarChart data={geographicData} title="Geographic Distribution" />
          <BarChart data={monthlyData} title="Monthly Comparison" />
        </div>
      </div>
    );
  };

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-card-foreground">
            Reports & Analytics
          </h1>
          <p className="text-muted-foreground">
            Comprehensive insights and performance metrics
          </p>
        </div>
        <div className="flex items-center gap-3">
          <Select
            value={
              dateRange.start.getTime() ===
              new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).getTime()
                ? "week"
                : "month"
            }
            onValueChange={setPresetRange}
          >
            <SelectTrigger className="w-40">
              <Calendar className="h-4 w-4 mr-2" />
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {presetRanges.map((range) => (
                <SelectItem key={range.value} value={range.value}>
                  {range.label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>

          <Button
            variant="outline"
            onClick={() => {
              if (activeTab === "emergency") refreshEmergency();
              else if (activeTab === "responder") refreshResponder();
              else refreshSystem();
            }}
            className="cursor-pointer"
          >
            <RefreshCw className="h-4 w-4 mr-2" />
            Refresh
          </Button>

          <Button
            onClick={handleGenerateReport}
            disabled={reportLoading}
            className="cursor-pointer"
          >
            <Download className="h-4 w-4 mr-2" />
            {reportLoading ? "Generating..." : "Export Report"}
          </Button>
        </div>
      </div>

      {/* Date Range Info */}
      <Card className="bg-card border-border">
        <CardContent className="p-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <Calendar className="h-4 w-4" />
              <span>
                Showing data from {dateRange.start.toLocaleDateString()} to{" "}
                {dateRange.end.toLocaleDateString()}
              </span>
            </div>
            <Badge variant="outline" className="text-xs">
              Last updated{" "}
              {formatDistanceToNow(new Date(), { addSuffix: true })}
            </Badge>
          </div>
        </CardContent>
      </Card>

      {/* Tabs */}
      <div className="flex space-x-1 bg-muted p-1 rounded-lg">
        {tabs.map((tab) => {
          const Icon = tab.icon;
          return (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id as any)}
              className={`flex items-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-colors cursor-pointer ${
                activeTab === tab.id
                  ? "bg-card text-card-foreground shadow-sm"
                  : "text-muted-foreground hover:text-card-foreground"
              }`}
            >
              <Icon className="h-4 w-4" />
              {tab.label}
            </button>
          );
        })}
      </div>

      {/* Content */}
      {activeTab === "emergency" && renderEmergencyAnalytics()}
      {activeTab === "responder" && renderResponderAnalytics()}
      {activeTab === "system" && renderSystemAnalytics()}

      {/* Feedback Modals */}
      <SuccessModal />
      <ErrorModal />
      <LoadingModal />
    </div>
  );
};
