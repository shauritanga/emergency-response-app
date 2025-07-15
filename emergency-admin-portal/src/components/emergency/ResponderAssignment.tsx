import React, { useState } from "react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import {
  Search,
  MapPin,
  Clock,
  User,
  Phone,
  CheckCircle,
  Users,
  Star,
  Activity,
} from "lucide-react";

interface ResponderAssignmentProps {
  emergencyId: string;
  emergencyType: string;
  emergencyLocation: {
    latitude: number;
    longitude: number;
    address: string;
  };
  onAssign?: (responderId: string) => void;
  onClose?: () => void;
}

export const ResponderAssignment: React.FC<ResponderAssignmentProps> = ({
  emergencyId: _emergencyId,
  emergencyType,
  emergencyLocation,
  onAssign,
  onClose,
}) => {
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedSpecialty, setSelectedSpecialty] = useState<string>("all");
  const [sortBy, setSortBy] = useState<"distance" | "rating" | "availability">(
    "distance"
  );

  // Mock responder data - replace with actual data fetching
  const availableResponders = [
    {
      id: "resp1",
      name: "Dr. Sarah Johnson",
      role: "Paramedic",
      specialty: "medical",
      rating: 4.9,
      responseTime: "2.3 min avg",
      distance: "0.8 miles",
      status: "available",
      location: { lat: 40.713, lng: -74.0061 },
      avatar: null,
      completedEmergencies: 156,
      phone: "+1 (555) 123-4567",
      lastActive: new Date(Date.now() - 5 * 60 * 1000),
      skills: ["CPR", "Advanced Life Support", "Trauma Care"],
    },
    {
      id: "resp2",
      name: "Mike Wilson",
      role: "EMT",
      specialty: "medical",
      rating: 4.7,
      responseTime: "3.1 min avg",
      distance: "1.2 miles",
      status: "available",
      location: { lat: 40.7125, lng: -74.0055 },
      avatar: null,
      completedEmergencies: 89,
      phone: "+1 (555) 234-5678",
      lastActive: new Date(Date.now() - 2 * 60 * 1000),
      skills: ["Basic Life Support", "Emergency Response", "Patient Transport"],
    },
    {
      id: "resp3",
      name: "Captain Lisa Rodriguez",
      role: "Fire Captain",
      specialty: "fire",
      rating: 4.8,
      responseTime: "4.2 min avg",
      distance: "2.1 miles",
      status: "busy",
      location: { lat: 40.714, lng: -74.007 },
      avatar: null,
      completedEmergencies: 203,
      phone: "+1 (555) 345-6789",
      lastActive: new Date(Date.now() - 10 * 60 * 1000),
      skills: ["Fire Suppression", "Rescue Operations", "Hazmat"],
    },
    {
      id: "resp4",
      name: "Officer James Chen",
      role: "Police Officer",
      specialty: "police",
      rating: 4.6,
      responseTime: "3.8 min avg",
      distance: "1.5 miles",
      status: "available",
      location: { lat: 40.7135, lng: -74.0065 },
      avatar: null,
      completedEmergencies: 134,
      phone: "+1 (555) 456-7890",
      lastActive: new Date(Date.now() - 1 * 60 * 1000),
      skills: ["Emergency Response", "Traffic Control", "Investigation"],
    },
  ];

  // Filter responders based on search and specialty
  const filteredResponders = availableResponders
    .filter((responder) => {
      const matchesSearch =
        responder.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        responder.role.toLowerCase().includes(searchQuery.toLowerCase()) ||
        responder.skills.some((skill) =>
          skill.toLowerCase().includes(searchQuery.toLowerCase())
        );

      const matchesSpecialty =
        selectedSpecialty === "all" ||
        responder.specialty === selectedSpecialty;

      return matchesSearch && matchesSpecialty;
    })
    .sort((a, b) => {
      switch (sortBy) {
        case "distance":
          return parseFloat(a.distance) - parseFloat(b.distance);
        case "rating":
          return b.rating - a.rating;
        case "availability":
          if (a.status === "available" && b.status !== "available") return -1;
          if (a.status !== "available" && b.status === "available") return 1;
          return 0;
        default:
          return 0;
      }
    });

  const getStatusColor = (status: string) => {
    switch (status) {
      case "available":
        return "text-green-600 bg-green-50 border-green-200";
      case "busy":
        return "text-red-600 bg-red-50 border-red-200";
      case "offline":
        return "text-gray-600 bg-gray-50 border-gray-200";
      default:
        return "text-gray-600 bg-gray-50 border-gray-200";
    }
  };

  const getSpecialtyIcon = (specialty: string) => {
    switch (specialty) {
      case "medical":
        return "🚑";
      case "fire":
        return "🔥";
      case "police":
        return "🚔";
      default:
        return "⚠️";
    }
  };

  const handleAssign = (responderId: string) => {
    onAssign?.(responderId);
    onClose?.();
  };

  return (
    <div className="max-w-6xl mx-auto p-6">
      {/* Header */}
      <div className="mb-6">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h2 className="text-2xl font-bold text-gray-900">
              Assign Responder
            </h2>
            <p className="text-gray-600">
              Select the best available responder for this {emergencyType}{" "}
              emergency
            </p>
          </div>
          <Button
            variant="outline"
            onClick={onClose}
            className="cursor-pointer"
          >
            Cancel
          </Button>
        </div>

        {/* Emergency Info */}
        <Card className="border-0 shadow-sm bg-blue-50">
          <CardContent className="p-4">
            <div className="flex items-center gap-4">
              <div className="text-2xl">{getSpecialtyIcon(emergencyType)}</div>
              <div>
                <h3 className="font-semibold text-gray-900">
                  Emergency Location
                </h3>
                <div className="flex items-center gap-2 text-sm text-gray-600">
                  <MapPin className="h-4 w-4" />
                  <span>{emergencyLocation.address}</span>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Search and Filters */}
      <div className="flex items-center gap-4 mb-6">
        <div className="flex-1 relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
          <input
            type="text"
            placeholder="Search responders by name, role, or skills..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          />
        </div>

        <select
          value={selectedSpecialty}
          onChange={(e) => setSelectedSpecialty(e.target.value)}
          className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
        >
          <option value="all">All Specialties</option>
          <option value="medical">Medical</option>
          <option value="fire">Fire</option>
          <option value="police">Police</option>
        </select>

        <select
          value={sortBy}
          onChange={(e) => setSortBy(e.target.value as any)}
          className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
        >
          <option value="distance">Sort by Distance</option>
          <option value="rating">Sort by Rating</option>
          <option value="availability">Sort by Availability</option>
        </select>
      </div>

      {/* Responder List */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {filteredResponders.map((responder) => (
          <Card
            key={responder.id}
            className="border-0 shadow-lg hover:shadow-xl transition-all duration-300"
          >
            <CardContent className="p-6">
              <div className="flex items-start justify-between mb-4">
                <div className="flex items-center gap-4">
                  <Avatar className="h-12 w-12">
                    <AvatarImage src={responder.avatar || undefined} />
                    <AvatarFallback className="bg-gradient-to-br from-blue-500 to-indigo-600 text-white font-semibold">
                      {responder.name
                        .split(" ")
                        .map((n) => n[0])
                        .join("")}
                    </AvatarFallback>
                  </Avatar>
                  <div>
                    <h3 className="font-semibold text-lg text-gray-900">
                      {responder.name}
                    </h3>
                    <p className="text-gray-600">{responder.role}</p>
                    <div className="flex items-center gap-2 mt-1">
                      <div
                        className={`px-2 py-1 rounded-full text-xs font-medium border ${getStatusColor(
                          responder.status
                        )}`}
                      >
                        {responder.status.toUpperCase()}
                      </div>
                      <div className="flex items-center gap-1">
                        <Star className="h-3 w-3 text-yellow-500 fill-current" />
                        <span className="text-sm font-medium">
                          {responder.rating}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>

                <Button
                  onClick={() => handleAssign(responder.id)}
                  disabled={responder.status !== "available"}
                  className={`shrink-0 ${
                    responder.status === "available"
                      ? "cursor-pointer"
                      : "cursor-not-allowed"
                  }`}
                >
                  {responder.status === "available" ? "Assign" : "Unavailable"}
                </Button>
              </div>

              <div className="grid grid-cols-2 gap-4 mb-4">
                <div className="flex items-center gap-2 text-sm text-gray-600">
                  <MapPin className="h-4 w-4 text-blue-500" />
                  <span>{responder.distance} away</span>
                </div>
                <div className="flex items-center gap-2 text-sm text-gray-600">
                  <Clock className="h-4 w-4 text-green-500" />
                  <span>{responder.responseTime}</span>
                </div>
                <div className="flex items-center gap-2 text-sm text-gray-600">
                  <CheckCircle className="h-4 w-4 text-purple-500" />
                  <span>{responder.completedEmergencies} completed</span>
                </div>
                <div className="flex items-center gap-2 text-sm text-gray-600">
                  <Activity className="h-4 w-4 text-orange-500" />
                  <span>
                    Active{" "}
                    {Math.floor(
                      (Date.now() - responder.lastActive.getTime()) / 60000
                    )}
                    m ago
                  </span>
                </div>
              </div>

              <div className="mb-4">
                <h4 className="text-sm font-medium text-gray-900 mb-2">
                  Skills & Certifications
                </h4>
                <div className="flex flex-wrap gap-1">
                  {responder.skills.map((skill, index) => (
                    <Badge key={index} variant="outline" className="text-xs">
                      {skill}
                    </Badge>
                  ))}
                </div>
              </div>

              <div className="flex gap-2 pt-4 border-t border-gray-100">
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
                  <User className="h-4 w-4 mr-2" />
                  Profile
                </Button>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {filteredResponders.length === 0 && (
        <Card className="border-0 shadow-lg">
          <CardContent className="p-12 text-center">
            <Users className="h-16 w-16 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-semibold text-gray-900 mb-2">
              No responders found
            </h3>
            <p className="text-gray-500 mb-6">
              {searchQuery
                ? `No responders match your search "${searchQuery}"`
                : "No responders match the selected filters"}
            </p>
            <Button
              variant="outline"
              onClick={() => {
                setSearchQuery("");
                setSelectedSpecialty("all");
              }}
              className="cursor-pointer"
            >
              Clear Filters
            </Button>
          </CardContent>
        </Card>
      )}
    </div>
  );
};
