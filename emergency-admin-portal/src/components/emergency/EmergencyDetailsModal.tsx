import React from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { type Emergency, EmergencyStatus, EmergencyPriority } from "@/types";
import { formatDistanceToNow } from "date-fns";
import {
  AlertTriangle,
  MapPin,
  Clock,
  User,
  Users,
  Image as ImageIcon,
  Calendar,
  Edit,
  X,
  ExternalLink,
} from "lucide-react";

interface EmergencyDetailsModalProps {
  emergency: Emergency | null;
  isOpen: boolean;
  onClose: () => void;
  onEdit?: (emergency: Emergency) => void;
  onAssignResponder?: (emergency: Emergency) => void;
}

export const EmergencyDetailsModal: React.FC<EmergencyDetailsModalProps> = ({
  emergency,
  isOpen,
  onClose,
  onEdit,
  onAssignResponder,
}) => {
  if (!emergency) return null;

  const getStatusColor = (status: EmergencyStatus | string) => {
    switch (status) {
      case EmergencyStatus.REPORTED:
      case "reported":
        return "bg-red-100 text-red-800 border-red-200";
      case EmergencyStatus.DISPATCHED:
      case "dispatched":
        return "bg-yellow-100 text-yellow-800 border-yellow-200";
      case EmergencyStatus.IN_PROGRESS:
      case "in_progress":
        return "bg-blue-100 text-blue-800 border-blue-200";
      case EmergencyStatus.RESOLVED:
      case "resolved":
        return "bg-green-100 text-green-800 border-green-200";
      default:
        return "bg-gray-100 text-gray-800 border-gray-200";
    }
  };

  const getPriorityColor = (priority: EmergencyPriority | string) => {
    switch (priority) {
      case EmergencyPriority.CRITICAL:
      case "critical":
        return "bg-red-100 text-red-800 border-red-200";
      case EmergencyPriority.HIGH:
      case "high":
        return "bg-orange-100 text-orange-800 border-orange-200";
      case EmergencyPriority.MEDIUM:
      case "medium":
        return "bg-yellow-100 text-yellow-800 border-yellow-200";
      case EmergencyPriority.LOW:
      case "low":
        return "bg-green-100 text-green-800 border-green-200";
      default:
        return "bg-gray-100 text-gray-800 border-gray-200";
    }
  };

  const getTypeIcon = (type: string) => {
    switch (type?.toLowerCase()) {
      case "fire":
        return "🔥";
      case "medical":
        return "🚑";
      case "police":
        return "🚔";
      case "natural_disaster":
        return "🌪️";
      case "accident":
        return "🚗";
      case "security":
        return "🔒";
      default:
        return "⚠️";
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-6xl max-h-[90vh] overflow-y-auto bg-white">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-3">
            <div className="p-2 bg-red-100 rounded-lg">
              <AlertTriangle className="h-5 w-5 text-red-600" />
            </div>
            Emergency Details: {emergency.title}
          </DialogTitle>
        </DialogHeader>

        <div className="space-y-6">
          {/* Emergency Overview */}
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="text-sm font-medium text-gray-600">
                  Type
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="flex items-center gap-2">
                  <span className="text-lg">{getTypeIcon(emergency.type)}</span>
                  <span className="font-medium capitalize">
                    {emergency.type}
                  </span>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="text-sm font-medium text-gray-600">
                  Status
                </CardTitle>
              </CardHeader>
              <CardContent>
                <Badge className={getStatusColor(emergency.status)}>
                  {emergency.status}
                </Badge>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="text-sm font-medium text-gray-600">
                  Priority
                </CardTitle>
              </CardHeader>
              <CardContent>
                <Badge className={getPriorityColor(emergency.priority)}>
                  {emergency.priority}
                </Badge>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="text-sm font-medium text-gray-600">
                  Reported
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="flex items-center gap-2">
                  <Clock className="h-4 w-4 text-gray-400" />
                  <span className="text-sm">
                    {formatDistanceToNow(emergency.createdAt, {
                      addSuffix: true,
                    })}
                  </span>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Description */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <AlertTriangle className="h-5 w-5" />
                Emergency Description
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-gray-700 leading-relaxed">
                {emergency.description || "No description provided"}
              </p>
            </CardContent>
          </Card>

          {/* Location Information */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <MapPin className="h-5 w-5" />
                Location Information
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <p className="text-sm font-medium text-gray-600">Address</p>
                  <p className="text-sm">{emergency.location.address}</p>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-600">
                    Coordinates
                  </p>
                  <p className="text-sm font-mono">
                    {emergency.location.latitude},{" "}
                    {emergency.location.longitude}
                  </p>
                </div>
              </div>
              <Button variant="outline" size="sm" className="cursor-pointer">
                <ExternalLink className="h-4 w-4 mr-2" />
                View on Map
              </Button>
            </CardContent>
          </Card>

          {/* Reporter Information */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <User className="h-5 w-5" />
                Reporter Information
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="flex items-center gap-4">
                <div className="w-10 h-10 bg-gray-200 rounded-full flex items-center justify-center">
                  <User className="h-5 w-5 text-gray-500" />
                </div>
                <div>
                  <p className="font-medium">{emergency.reportedBy.name}</p>
                  <p className="text-sm text-gray-500">
                    User ID: {emergency.reportedBy.userId}
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Assigned Responders */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Users className="h-5 w-5" />
                Assigned Responders ({emergency.assignedResponders?.length || 0}
                )
              </CardTitle>
            </CardHeader>
            <CardContent>
              {emergency.assignedResponders &&
              emergency.assignedResponders.length > 0 ? (
                <div className="space-y-2">
                  {emergency.assignedResponders.map((responderId, index) => (
                    <div
                      key={index}
                      className="flex items-center gap-3 p-2 bg-gray-50 rounded-lg"
                    >
                      <div className="w-8 h-8 bg-blue-200 rounded-full flex items-center justify-center">
                        <User className="h-4 w-4 text-blue-600" />
                      </div>
                      <div>
                        <p className="text-sm font-medium">
                          Responder {responderId.slice(-4)}
                        </p>
                        <p className="text-xs text-gray-500">
                          ID: {responderId}
                        </p>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="text-center py-4">
                  <Users className="h-8 w-8 text-gray-400 mx-auto mb-2" />
                  <p className="text-sm text-gray-500">
                    No responders assigned
                  </p>
                  {onAssignResponder && (
                    <Button
                      variant="outline"
                      size="sm"
                      className="mt-2 cursor-pointer"
                      onClick={() => onAssignResponder(emergency)}
                    >
                      <Users className="h-4 w-4 mr-2" />
                      Assign Responder
                    </Button>
                  )}
                </div>
              )}
            </CardContent>
          </Card>

          {/* Images */}
          {emergency.imageUrls && emergency.imageUrls.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <ImageIcon className="h-5 w-5" />
                  Emergency Images ({emergency.imageUrls.length})
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  {emergency.imageUrls.map((url: string, index: number) => (
                    <div key={index} className="relative group">
                      <img
                        src={url}
                        alt={`Emergency image ${index + 1}`}
                        className="w-full h-24 object-cover rounded-lg border cursor-pointer hover:opacity-75 transition-opacity"
                        onClick={() => window.open(url, "_blank")}
                      />
                      <div className="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-20 transition-all rounded-lg flex items-center justify-center">
                        <ExternalLink className="h-4 w-4 text-white opacity-0 group-hover:opacity-100 transition-opacity" />
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}

          {/* Timeline */}
          {emergency.timeline && emergency.timeline.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Calendar className="h-5 w-5" />
                  Emergency Timeline
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {emergency.timeline.map((event, index) => (
                    <div key={index} className="flex items-start gap-3">
                      <div className="w-2 h-2 bg-blue-500 rounded-full mt-2"></div>
                      <div className="flex-1">
                        <p className="text-sm font-medium">{event.title}</p>
                        <p className="text-xs text-gray-500">
                          {event.description}
                        </p>
                        <p className="text-xs text-gray-400">
                          {formatDistanceToNow(event.timestamp, {
                            addSuffix: true,
                          })}
                        </p>
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={onClose}>
            <X className="h-4 w-4 mr-2" />
            Close
          </Button>
          {onAssignResponder && (
            <Button
              variant="outline"
              onClick={() => onAssignResponder(emergency)}
              className="cursor-pointer"
            >
              <Users className="h-4 w-4 mr-2" />
              Assign Responder
            </Button>
          )}
          {onEdit && (
            <Button
              onClick={() => onEdit(emergency)}
              className="cursor-pointer"
            >
              <Edit className="h-4 w-4 mr-2" />
              Update Status
            </Button>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};
