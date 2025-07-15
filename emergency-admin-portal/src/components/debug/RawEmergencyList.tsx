import React from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

interface RawEmergencyListProps {
  emergencies: any[];
  loading: boolean;
}

export const RawEmergencyList: React.FC<RawEmergencyListProps> = ({
  emergencies,
  loading,
}) => {
  if (loading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Raw Emergency Data (Loading...)</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center justify-center h-32">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Raw Emergency Data ({emergencies.length} items)</CardTitle>
      </CardHeader>
      <CardContent>
        {emergencies.length === 0 ? (
          <div className="text-center py-8 text-muted-foreground">
            No emergencies found
          </div>
        ) : (
          <div className="space-y-4">
            {emergencies.map((emergency, index) => (
              <div
                key={emergency.id || index}
                className="border rounded-lg p-4 bg-gray-50"
              >
                <h3 className="font-semibold mb-2">Emergency {index + 1}</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <h4 className="font-medium text-sm text-gray-700 mb-1">Basic Info:</h4>
                    <ul className="text-sm space-y-1">
                      <li><strong>ID:</strong> {emergency.id || 'N/A'}</li>
                      <li><strong>Title:</strong> {emergency.title || emergency.description || 'N/A'}</li>
                      <li><strong>Status:</strong> {emergency.status || emergency.emergencyStatus || 'N/A'}</li>
                      <li><strong>Type:</strong> {emergency.type || emergency.emergencyType || 'N/A'}</li>
                      <li><strong>Priority:</strong> {emergency.priority || emergency.emergencyPriority || 'N/A'}</li>
                    </ul>
                  </div>
                  <div>
                    <h4 className="font-medium text-sm text-gray-700 mb-1">Timestamps:</h4>
                    <ul className="text-sm space-y-1">
                      <li><strong>Created:</strong> {emergency.createdAt?.toString() || emergency.timestamp?.toString() || emergency.dateCreated?.toString() || 'N/A'}</li>
                      <li><strong>Updated:</strong> {emergency.updatedAt?.toString() || emergency.lastUpdated?.toString() || 'N/A'}</li>
                    </ul>
                    <h4 className="font-medium text-sm text-gray-700 mb-1 mt-3">Location:</h4>
                    <ul className="text-sm space-y-1">
                      <li><strong>Address:</strong> {emergency.location?.address || emergency.address || 'N/A'}</li>
                      <li><strong>Lat/Lng:</strong> {emergency.location?.latitude || emergency.latitude || 'N/A'}, {emergency.location?.longitude || emergency.longitude || 'N/A'}</li>
                    </ul>
                  </div>
                </div>
                <details className="mt-3">
                  <summary className="cursor-pointer text-sm font-medium text-blue-600">
                    View Full Object
                  </summary>
                  <pre className="mt-2 text-xs bg-white p-2 rounded border overflow-auto max-h-40">
                    {JSON.stringify(emergency, null, 2)}
                  </pre>
                </details>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
};
