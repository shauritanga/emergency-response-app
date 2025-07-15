import React, { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { EmergencyList } from "@/components/emergency/EmergencyList";
import { EmergencyDetailsModal } from "@/components/emergency/EmergencyDetailsModal";
import { StatusUpdateModal } from "@/components/emergency/StatusUpdateModal";
import { ResponderAssignmentModal } from "@/components/emergency/ResponderAssignmentModal";
import { useEmergenciesRealtime } from "@/hooks/useEmergencies";
import { type Emergency, EmergencyStatus } from "@/types";
import { AlertTriangle, Filter, Download, RefreshCw } from "lucide-react";

export const EmergencyManagement: React.FC = () => {
  // Get real-time emergency data
  const { emergencies, loading } = useEmergenciesRealtime();

  // Calculate average response time from real data
  const resolvedEmergencies = emergencies.filter(
    (e) => e.status === "resolved" && e.actualResponseTime
  );
  const averageResponseTime =
    resolvedEmergencies.length > 0
      ? resolvedEmergencies.reduce(
          (sum, e) => sum + (e.actualResponseTime || 0),
          0
        ) / resolvedEmergencies.length
      : 0;

  // Modal states
  const [selectedEmergency, setSelectedEmergency] = useState<Emergency | null>(
    null
  );
  const [isDetailsModalOpen, setIsDetailsModalOpen] = useState(false);
  const [isStatusModalOpen, setIsStatusModalOpen] = useState(false);
  const [isAssignModalOpen, setIsAssignModalOpen] = useState(false);

  // Event handlers
  const handleViewDetails = (emergency: Emergency) => {
    setSelectedEmergency(emergency);
    setIsDetailsModalOpen(true);
  };

  const handleAssignResponder = (emergency: Emergency) => {
    setSelectedEmergency(emergency);
    setIsAssignModalOpen(true);
  };

  const handleUpdateStatus = (emergency: Emergency) => {
    setSelectedEmergency(emergency);
    setIsStatusModalOpen(true);
  };

  const activeEmergencies = emergencies.filter(
    (e) =>
      e.status !== EmergencyStatus.RESOLVED &&
      e.status !== EmergencyStatus.CANCELLED
  );

  const criticalEmergencies = emergencies.filter(
    (e) => e.priority === "critical"
  );
  const highPriorityEmergencies = emergencies.filter(
    (e) => e.priority === "high"
  );

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">
            Emergency Management
          </h1>
          <p className="text-gray-600 mt-1">
            Monitor and manage all emergency responses
          </p>
        </div>
        <div className="flex items-center space-x-3">
          <Button variant="outline" size="sm">
            <Filter className="h-4 w-4 mr-2" />
            Filter
          </Button>
          <Button variant="outline" size="sm">
            <Download className="h-4 w-4 mr-2" />
            Export
          </Button>
          <Button variant="outline" size="sm">
            <RefreshCw className="h-4 w-4 mr-2" />
            Refresh
          </Button>
        </div>
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Active</CardTitle>
            <AlertTriangle className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{activeEmergencies.length}</div>
            <p className="text-xs text-muted-foreground">
              Currently in progress
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Critical</CardTitle>
            <div className="w-3 h-3 bg-red-500 rounded-full"></div>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-red-600">
              {criticalEmergencies.length}
            </div>
            <p className="text-xs text-muted-foreground">
              Requires immediate attention
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">High Priority</CardTitle>
            <div className="w-3 h-3 bg-orange-500 rounded-full"></div>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-orange-600">
              {highPriorityEmergencies.length}
            </div>
            <p className="text-xs text-muted-foreground">High priority cases</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Response Time</CardTitle>
            <div className="w-3 h-3 bg-green-500 rounded-full"></div>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-green-600">
              {averageResponseTime > 0
                ? `${averageResponseTime.toFixed(1)} min`
                : "N/A"}
            </div>
            <p className="text-xs text-muted-foreground">
              Average response time
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Emergency List */}
      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
        <div className="lg:col-span-3">
          <EmergencyList
            emergencies={emergencies}
            loading={loading}
            onViewDetails={handleViewDetails}
            onAssignResponder={handleAssignResponder}
            onUpdateStatus={handleUpdateStatus}
          />
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Recent Activity */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Recent Activity</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                <div className="flex items-start space-x-3">
                  <div className="w-2 h-2 bg-red-500 rounded-full mt-2"></div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-gray-900">
                      New fire emergency reported
                    </p>
                    <p className="text-xs text-gray-500">
                      Downtown Plaza • 2 min ago
                    </p>
                  </div>
                </div>
                <div className="flex items-start space-x-3">
                  <div className="w-2 h-2 bg-blue-500 rounded-full mt-2"></div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-gray-900">
                      Responder assigned
                    </p>
                    <p className="text-xs text-gray-500">
                      John Doe • 5 min ago
                    </p>
                  </div>
                </div>
                <div className="flex items-start space-x-3">
                  <div className="w-2 h-2 bg-green-500 rounded-full mt-2"></div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-gray-900">
                      Emergency resolved
                    </p>
                    <p className="text-xs text-gray-500">
                      Medical case • 10 min ago
                    </p>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Priority Distribution */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Priority Distribution</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-2">
                    <div className="w-3 h-3 bg-red-500 rounded-full"></div>
                    <span className="text-sm">Critical</span>
                  </div>
                  <Badge variant="destructive">
                    {criticalEmergencies.length}
                  </Badge>
                </div>
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-2">
                    <div className="w-3 h-3 bg-orange-500 rounded-full"></div>
                    <span className="text-sm">High</span>
                  </div>
                  <Badge variant="secondary">
                    {highPriorityEmergencies.length}
                  </Badge>
                </div>
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-2">
                    <div className="w-3 h-3 bg-yellow-500 rounded-full"></div>
                    <span className="text-sm">Medium</span>
                  </div>
                  <Badge variant="outline">
                    {emergencies.filter((e) => e.priority === "medium").length}
                  </Badge>
                </div>
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-2">
                    <div className="w-3 h-3 bg-green-500 rounded-full"></div>
                    <span className="text-sm">Low</span>
                  </div>
                  <Badge variant="outline">
                    {emergencies.filter((e) => e.priority === "low").length}
                  </Badge>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Modals */}
      <EmergencyDetailsModal
        emergency={selectedEmergency}
        isOpen={isDetailsModalOpen}
        onClose={() => {
          setIsDetailsModalOpen(false);
          setSelectedEmergency(null);
        }}
        onEdit={(emergency) => {
          setIsDetailsModalOpen(false);
          setSelectedEmergency(emergency);
          setIsStatusModalOpen(true);
        }}
        onAssignResponder={(emergency) => {
          setIsDetailsModalOpen(false);
          setSelectedEmergency(emergency);
          setIsAssignModalOpen(true);
        }}
      />

      <StatusUpdateModal
        emergency={selectedEmergency}
        isOpen={isStatusModalOpen}
        onClose={() => {
          setIsStatusModalOpen(false);
          setSelectedEmergency(null);
        }}
      />

      <ResponderAssignmentModal
        emergency={selectedEmergency}
        isOpen={isAssignModalOpen}
        onClose={() => {
          setIsAssignModalOpen(false);
          setSelectedEmergency(null);
        }}
      />
    </div>
  );
};
