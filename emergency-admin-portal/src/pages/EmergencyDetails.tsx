import React, { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { ImagePreview } from "@/components/emergency/ImagePreview";
import { ImageGallery } from "@/components/emergency/ImageGallery";
import {
  ArrowLeft,
  MapPin,
  Clock,
  User,
  Phone,
  Mail,
  AlertTriangle,
  CheckCircle,
  Users,
  MessageSquare,
  Camera,
  Edit,
  Share,
  Download,
  MoreVertical,
} from "lucide-react";
import { formatDistanceToNow } from "date-fns";

interface EmergencyDetailsProps {
  emergencyId: string;
  onBack?: () => void;
}

export const EmergencyDetails: React.FC<EmergencyDetailsProps> = ({
  emergencyId,
  onBack,
}) => {
  const [activeTab, setActiveTab] = useState<
    "overview" | "timeline" | "responders" | "images"
  >("overview");

  // Mock emergency data - replace with actual data fetching
  const emergency = {
    id: emergencyId,
    title: "Medical Emergency - Cardiac Arrest",
    description:
      "Patient experiencing cardiac arrest at downtown office building. CPR in progress.",
    type: "medical",
    status: "in_progress",
    priority: "critical",
    location: {
      address: "123 Main Street, Downtown",
      latitude: 40.7128,
      longitude: -74.006,
    },
    reportedBy: {
      id: "user1",
      name: "John Smith",
      phone: "+1 (555) 123-4567",
      email: "john.smith@email.com",
      avatar: null,
    },
    assignedResponders: [
      {
        id: "resp1",
        name: "Dr. Sarah Johnson",
        role: "Paramedic",
        status: "en_route",
        eta: "3 minutes",
        avatar: null,
      },
      {
        id: "resp2",
        name: "Mike Wilson",
        role: "EMT",
        status: "dispatched",
        eta: "5 minutes",
        avatar: null,
      },
    ],
    timeline: [
      {
        id: "1",
        timestamp: new Date(Date.now() - 5 * 60 * 1000),
        action: "Emergency reported",
        user: "John Smith",
        details: "Initial report received via mobile app",
      },
      {
        id: "2",
        timestamp: new Date(Date.now() - 4 * 60 * 1000),
        action: "Responders dispatched",
        user: "System",
        details: "2 responders assigned and notified",
      },
      {
        id: "3",
        timestamp: new Date(Date.now() - 2 * 60 * 1000),
        action: "Status update",
        user: "Dr. Sarah Johnson",
        details: "En route to location, ETA 3 minutes",
      },
    ],
    createdAt: new Date(Date.now() - 5 * 60 * 1000),
    updatedAt: new Date(Date.now() - 2 * 60 * 1000),
    images: [
      {
        id: "img1",
        url: "https://images.unsplash.com/photo-1584515933487-779824d29309?w=800",
        thumbnail:
          "https://images.unsplash.com/photo-1584515933487-779824d29309?w=300",
        filename: "emergency_scene_1.jpg",
        size: 2048576,
        uploadedAt: new Date(Date.now() - 4 * 60 * 1000),
        uploadedBy: {
          id: "user1",
          name: "John Smith",
          role: "Reporter",
        },
        location: {
          latitude: 40.7128,
          longitude: -74.006,
          address: "123 Main Street, Downtown",
        },
        metadata: {
          width: 1920,
          height: 1080,
          type: "image/jpeg",
        },
      },
      {
        id: "img2",
        url: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800",
        thumbnail:
          "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300",
        filename: "emergency_scene_2.jpg",
        size: 1536000,
        uploadedAt: new Date(Date.now() - 3 * 60 * 1000),
        uploadedBy: {
          id: "resp1",
          name: "Dr. Sarah Johnson",
          role: "Paramedic",
        },
        metadata: {
          width: 1600,
          height: 1200,
          type: "image/jpeg",
        },
      },
      {
        id: "img3",
        url: "https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=800",
        thumbnail:
          "https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=300",
        filename: "patient_status.jpg",
        size: 1024000,
        uploadedAt: new Date(Date.now() - 1 * 60 * 1000),
        uploadedBy: {
          id: "resp2",
          name: "Mike Wilson",
          role: "EMT",
        },
        metadata: {
          width: 1280,
          height: 960,
          type: "image/jpeg",
        },
      },
    ],
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case "pending":
        return "destructive";
      case "in_progress":
        return "default";
      case "resolved":
        return "outline";
      default:
        return "secondary";
    }
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case "critical":
        return "text-red-600 bg-red-50 border-red-200";
      case "high":
        return "text-orange-600 bg-orange-50 border-orange-200";
      case "medium":
        return "text-yellow-600 bg-yellow-50 border-yellow-200";
      case "low":
        return "text-green-600 bg-green-50 border-green-200";
      default:
        return "text-gray-600 bg-gray-50 border-gray-200";
    }
  };

  const getTypeIcon = (type: string) => {
    switch (type?.toLowerCase()) {
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

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 shadow-sm">
        <div className="px-6 py-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <Button variant="ghost" onClick={onBack} className="p-2">
                <ArrowLeft className="h-5 w-5" />
              </Button>
              <div className="flex items-center gap-4">
                <div className="text-3xl p-3 bg-gray-100 rounded-lg">
                  {getTypeIcon(emergency.type)}
                </div>
                <div>
                  <h1 className="text-2xl font-bold text-gray-900">
                    {emergency.title}
                  </h1>
                  <div className="flex items-center gap-3 mt-1">
                    <Badge variant={getStatusColor(emergency.status)}>
                      {emergency.status.replace("_", " ").toUpperCase()}
                    </Badge>
                    <div
                      className={`px-3 py-1 rounded-full text-xs font-medium border ${getPriorityColor(
                        emergency.priority
                      )}`}
                    >
                      {emergency.priority.toUpperCase()} PRIORITY
                    </div>
                    <span className="text-sm text-gray-500">
                      {formatDistanceToNow(emergency.createdAt, {
                        addSuffix: true,
                      })}
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <Button variant="outline" size="sm" className="cursor-pointer">
                <Share className="h-4 w-4 mr-2" />
                Share
              </Button>
              <Button variant="outline" size="sm" className="cursor-pointer">
                <Download className="h-4 w-4 mr-2" />
                Export
              </Button>
              <Button variant="outline" size="sm" className="cursor-pointer">
                <Edit className="h-4 w-4 mr-2" />
                Edit
              </Button>
              <Button variant="outline" size="sm" className="cursor-pointer">
                <MoreVertical className="h-4 w-4" />
              </Button>
            </div>
          </div>

          {/* Tab Navigation */}
          <div className="flex items-center gap-1 mt-6 bg-gray-100 p-1 rounded-lg w-fit">
            {[
              { id: "overview", label: "Overview", icon: AlertTriangle },
              { id: "timeline", label: "Timeline", icon: Clock },
              { id: "responders", label: "Responders", icon: Users },
              { id: "images", label: "Images", icon: Camera },
            ].map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as any)}
                className={`flex items-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-all cursor-pointer ${
                  activeTab === tab.id
                    ? "bg-white text-blue-600 shadow-sm"
                    : "text-gray-600 hover:text-gray-900"
                }`}
              >
                <tab.icon className="h-4 w-4" />
                {tab.label}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="px-6 py-6">
        {activeTab === "overview" && (
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Main Details */}
            <div className="lg:col-span-2 space-y-6">
              {/* Description */}
              <Card className="border-0 shadow-lg">
                <CardHeader>
                  <CardTitle>Emergency Details</CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-gray-700 leading-relaxed mb-4">
                    {emergency.description}
                  </p>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div className="flex items-center gap-2 text-sm text-gray-600">
                      <MapPin className="h-4 w-4 text-blue-500" />
                      <span>{emergency.location.address}</span>
                    </div>
                    <div className="flex items-center gap-2 text-sm text-gray-600">
                      <Clock className="h-4 w-4 text-green-500" />
                      <span>
                        Reported{" "}
                        {formatDistanceToNow(emergency.createdAt, {
                          addSuffix: true,
                        })}
                      </span>
                    </div>
                  </div>
                </CardContent>
              </Card>

              {/* Reporter Information */}
              <Card className="border-0 shadow-lg">
                <CardHeader>
                  <CardTitle>Reported By</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="flex items-center gap-4">
                    <Avatar className="h-12 w-12">
                      <AvatarImage src={emergency.reportedBy.avatar} />
                      <AvatarFallback className="bg-blue-500 text-white">
                        {emergency.reportedBy.name
                          .split(" ")
                          .map((n) => n[0])
                          .join("")}
                      </AvatarFallback>
                    </Avatar>
                    <div className="flex-1">
                      <h3 className="font-semibold text-gray-900">
                        {emergency.reportedBy.name}
                      </h3>
                      <div className="space-y-1 mt-2">
                        <div className="flex items-center gap-2 text-sm text-gray-600">
                          <Phone className="h-4 w-4" />
                          <span>{emergency.reportedBy.phone}</span>
                        </div>
                        <div className="flex items-center gap-2 text-sm text-gray-600">
                          <Mail className="h-4 w-4" />
                          <span>{emergency.reportedBy.email}</span>
                        </div>
                      </div>
                    </div>
                    <div className="flex gap-2">
                      <Button
                        variant="outline"
                        size="sm"
                        className="cursor-pointer"
                      >
                        <Phone className="h-4 w-4 mr-2" />
                        Call
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        className="cursor-pointer"
                      >
                        <MessageSquare className="h-4 w-4 mr-2" />
                        Message
                      </Button>
                    </div>
                  </div>
                </CardContent>
              </Card>

              {/* Emergency Images Preview */}
              <ImagePreview
                images={emergency.images}
                maxPreview={4}
                onViewAll={() => setActiveTab("images")}
                onImageClick={(index) => {
                  setActiveTab("images");
                  // Could also open lightbox directly here
                }}
              />
            </div>

            {/* Sidebar */}
            <div className="space-y-6">
              {/* Quick Actions */}
              <Card className="border-0 shadow-lg">
                <CardHeader>
                  <CardTitle>Quick Actions</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-3">
                    <Button
                      className="w-full justify-start cursor-pointer"
                      variant="default"
                    >
                      <CheckCircle className="h-4 w-4 mr-2" />
                      Mark as Resolved
                    </Button>
                    <Button
                      className="w-full justify-start cursor-pointer"
                      variant="outline"
                    >
                      <Users className="h-4 w-4 mr-2" />
                      Assign Responder
                    </Button>
                    <Button
                      className="w-full justify-start cursor-pointer"
                      variant="outline"
                    >
                      <MessageSquare className="h-4 w-4 mr-2" />
                      Send Update
                    </Button>
                    <Button
                      className="w-full justify-start cursor-pointer"
                      variant="outline"
                    >
                      <Camera className="h-4 w-4 mr-2" />
                      Add Photos
                    </Button>
                  </div>
                </CardContent>
              </Card>

              {/* Assigned Responders */}
              <Card className="border-0 shadow-lg">
                <CardHeader>
                  <CardTitle>
                    Assigned Responders ({emergency.assignedResponders.length})
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-3">
                    {emergency.assignedResponders.map((responder) => (
                      <div
                        key={responder.id}
                        className="flex items-center gap-3 p-3 bg-gray-50 rounded-lg"
                      >
                        <Avatar className="h-8 w-8">
                          <AvatarImage src={responder.avatar} />
                          <AvatarFallback className="bg-green-500 text-white text-xs">
                            {responder.name
                              .split(" ")
                              .map((n) => n[0])
                              .join("")}
                          </AvatarFallback>
                        </Avatar>
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-medium text-gray-900">
                            {responder.name}
                          </p>
                          <p className="text-xs text-gray-500">
                            {responder.role}
                          </p>
                        </div>
                        <div className="text-right">
                          <Badge variant="outline" className="text-xs">
                            {responder.status.replace("_", " ")}
                          </Badge>
                          <p className="text-xs text-gray-500 mt-1">
                            ETA: {responder.eta}
                          </p>
                        </div>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>
            </div>
          </div>
        )}

        {/* Timeline Tab Content */}
        {activeTab === "timeline" && (
          <Card className="border-0 shadow-lg">
            <CardHeader>
              <CardTitle>Emergency Timeline</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {emergency.timeline.map((event, index) => (
                  <div key={event.id} className="flex gap-4">
                    <div className="flex flex-col items-center">
                      <div className="w-3 h-3 bg-blue-500 rounded-full"></div>
                      {index < emergency.timeline.length - 1 && (
                        <div className="w-px h-12 bg-gray-200 mt-2"></div>
                      )}
                    </div>
                    <div className="flex-1 pb-4">
                      <div className="flex items-center justify-between mb-1">
                        <h4 className="font-medium text-gray-900">
                          {event.action}
                        </h4>
                        <span className="text-xs text-gray-500">
                          {formatDistanceToNow(event.timestamp, {
                            addSuffix: true,
                          })}
                        </span>
                      </div>
                      <p className="text-sm text-gray-600 mb-1">
                        {event.details}
                      </p>
                      <p className="text-xs text-gray-500">by {event.user}</p>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        )}

        {/* Responders Tab Content */}
        {activeTab === "responders" && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {emergency.assignedResponders.map((responder) => (
              <Card key={responder.id} className="border-0 shadow-lg">
                <CardContent className="p-6">
                  <div className="flex items-center gap-4 mb-4">
                    <Avatar className="h-12 w-12">
                      <AvatarImage src={responder.avatar} />
                      <AvatarFallback className="bg-green-500 text-white">
                        {responder.name
                          .split(" ")
                          .map((n) => n[0])
                          .join("")}
                      </AvatarFallback>
                    </Avatar>
                    <div>
                      <h3 className="font-semibold text-gray-900">
                        {responder.name}
                      </h3>
                      <p className="text-sm text-gray-600">{responder.role}</p>
                    </div>
                  </div>

                  <div className="space-y-2 mb-4">
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-600">Status:</span>
                      <Badge variant="outline">
                        {responder.status.replace("_", " ")}
                      </Badge>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-600">ETA:</span>
                      <span className="text-sm font-medium">
                        {responder.eta}
                      </span>
                    </div>
                  </div>

                  <div className="flex gap-2">
                    <Button
                      variant="outline"
                      size="sm"
                      className="flex-1 cursor-pointer"
                    >
                      <Phone className="h-4 w-4 mr-2" />
                      Call
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      className="flex-1 cursor-pointer"
                    >
                      <MessageSquare className="h-4 w-4 mr-2" />
                      Message
                    </Button>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        )}

        {/* Images Tab Content */}
        {activeTab === "images" && (
          <ImageGallery
            images={emergency.images}
            emergencyId={emergencyId}
            onImageUpload={(files) => {
              console.log("Upload images:", files);
              // TODO: Implement image upload functionality
            }}
          />
        )}
      </div>
    </div>
  );
};
