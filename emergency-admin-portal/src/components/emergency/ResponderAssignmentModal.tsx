import React, { useState } from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent } from "@/components/ui/card";
import { type Emergency } from "@/types";
import { useResponders } from "@/hooks/useUsers";
import { useAssignResponder } from "@/hooks/useEmergencies";
import { useAuth } from "@/contexts/AuthContext";
import { useEmergencyActionFeedback } from "@/hooks/useActionFeedback";
import {
  Users,
  Search,
  UserPlus,
  Save,
  X,
  MapPin,
  Shield,
  Activity,
} from "lucide-react";

interface ResponderAssignmentModalProps {
  emergency: Emergency | null;
  isOpen: boolean;
  onClose: () => void;
}

export const ResponderAssignmentModal: React.FC<
  ResponderAssignmentModalProps
> = ({ emergency, isOpen, onClose }) => {
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedResponders, setSelectedResponders] = useState<string[]>([]);
  const [error, setError] = useState<string | null>(null);

  const { currentUser } = useAuth();
  const { data: responders = [], isLoading: loadingResponders } =
    useResponders();
  const assignResponderMutation = useAssignResponder();
  const {
    assignResponder,
    isExecuting,
    SuccessModal,
    ErrorModal,
    LoadingModal,
  } = useEmergencyActionFeedback();

  // Filter responders based on search query
  const filteredResponders = responders.filter(
    (responder) =>
      responder.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      responder.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
      responder.department?.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const handleResponderToggle = (responderId: string) => {
    setSelectedResponders((prev) =>
      prev.includes(responderId)
        ? prev.filter((id) => id !== responderId)
        : [...prev, responderId]
    );
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!emergency || selectedResponders.length === 0 || !currentUser) {
      setError("Please select at least one responder");
      return;
    }

    const result = await assignResponder(async () => {
      // Assign each selected responder
      for (const responderId of selectedResponders) {
        const responder = responders.find((r) => r.id === responderId);
        if (responder) {
          await assignResponderMutation.mutateAsync({
            emergencyId: emergency.id,
            responderId: responder.id,
            responderName: responder.name,
            adminId: currentUser.uid,
            adminName: currentUser.displayName || "Admin",
          });
        }
      }

      return { assignedCount: selectedResponders.length };
    });

    if (result) {
      // Reset form and close modal on success
      setSelectedResponders([]);
      setSearchQuery("");
      setError(null);
      onClose();
    }
  };

  const handleClose = () => {
    setSelectedResponders([]);
    setSearchQuery("");
    setError(null);
    onClose();
  };

  if (!emergency) return null;

  return (
    <>
      <Dialog open={isOpen} onOpenChange={handleClose}>
        <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto bg-white border-border">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-3 text-card-foreground">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <UserPlus className="h-5 w-5 text-blue-600 dark:text-blue-400" />
              </div>
              Assign Responders to Emergency
            </DialogTitle>
          </DialogHeader>

          <div className="bg-card border border-border rounded-lg p-6">
            <form onSubmit={handleSubmit} className="space-y-6">
              {error && (
                <div className="p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
                  <p className="text-sm text-red-600 dark:text-red-400">
                    {error}
                  </p>
                </div>
              )}

              {/* Emergency Info */}
              <Card>
                <CardContent className="p-4">
                  <div className="flex items-start gap-4">
                    <div className="flex-1">
                      <h3 className="font-semibold text-lg">
                        {emergency.title}
                      </h3>
                      <p className="text-sm text-gray-600 mt-1">
                        {emergency.description}
                      </p>
                      <div className="flex items-center gap-4 mt-2">
                        <Badge variant="outline" className="text-xs">
                          {emergency.type}
                        </Badge>
                        <div className="flex items-center gap-1 text-xs text-gray-500">
                          <MapPin className="h-3 w-3" />
                          {emergency.location.address}
                        </div>
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>

              {/* Search */}
              <div className="space-y-2">
                <Label htmlFor="search">Search Responders</Label>
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
                  <Input
                    id="search"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="pl-10"
                    placeholder="Search by name, email, or department"
                  />
                </div>
              </div>

              {/* Selected Responders */}
              {selectedResponders.length > 0 && (
                <div className="space-y-2">
                  <Label>
                    Selected Responders ({selectedResponders.length})
                  </Label>
                  <div className="flex flex-wrap gap-2">
                    {selectedResponders.map((responderId) => {
                      const responder = responders.find(
                        (r) => r.id === responderId
                      );
                      return responder ? (
                        <Badge
                          key={responderId}
                          variant="secondary"
                          className="cursor-pointer hover:bg-red-100 hover:text-red-800"
                          onClick={() => handleResponderToggle(responderId)}
                        >
                          {responder.name}
                          <X className="h-3 w-3 ml-1" />
                        </Badge>
                      ) : null;
                    })}
                  </div>
                </div>
              )}

              {/* Available Responders */}
              <div className="space-y-2">
                <Label>Available Responders</Label>
                {loadingResponders ? (
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {[1, 2, 3, 4].map((i) => (
                      <Card key={i} className="animate-pulse">
                        <CardContent className="p-4">
                          <div className="flex items-center gap-3">
                            <div className="w-10 h-10 bg-gray-200 rounded-full"></div>
                            <div className="flex-1 space-y-2">
                              <div className="h-4 bg-gray-200 rounded w-3/4"></div>
                              <div className="h-3 bg-gray-200 rounded w-1/2"></div>
                            </div>
                          </div>
                        </CardContent>
                      </Card>
                    ))}
                  </div>
                ) : filteredResponders.length === 0 ? (
                  <Card>
                    <CardContent className="p-8 text-center">
                      <Users className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                      <p className="text-gray-500">
                        {searchQuery
                          ? "No responders match your search"
                          : "No responders available"}
                      </p>
                    </CardContent>
                  </Card>
                ) : (
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4 max-h-96 overflow-y-auto">
                    {filteredResponders.map((responder) => (
                      <Card
                        key={responder.id}
                        className={`cursor-pointer transition-all hover:shadow-md ${
                          selectedResponders.includes(responder.id)
                            ? "ring-2 ring-blue-500 bg-blue-50"
                            : "hover:bg-gray-50"
                        }`}
                        onClick={() => handleResponderToggle(responder.id)}
                      >
                        <CardContent className="p-4">
                          <div className="flex items-center gap-3">
                            <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
                              <Users className="h-5 w-5 text-blue-600" />
                            </div>
                            <div className="flex-1">
                              <div className="flex items-center gap-2">
                                <h4 className="font-medium">
                                  {responder.name}
                                </h4>
                                <div
                                  className={`w-2 h-2 rounded-full ${
                                    responder.isOnline
                                      ? "bg-green-500"
                                      : "bg-gray-400"
                                  }`}
                                ></div>
                              </div>
                              <p className="text-sm text-gray-600">
                                {responder.email}
                              </p>
                              <div className="flex items-center gap-4 mt-1">
                                {responder.department && (
                                  <div className="flex items-center gap-1 text-xs text-gray-500">
                                    <Shield className="h-3 w-3" />
                                    {responder.department}
                                  </div>
                                )}
                                <div className="flex items-center gap-1 text-xs text-gray-500">
                                  <Activity className="h-3 w-3" />
                                  {responder.isOnline ? "Online" : "Offline"}
                                </div>
                              </div>
                              {responder.specializations &&
                                responder.specializations.length > 0 && (
                                  <div className="flex flex-wrap gap-1 mt-2">
                                    {responder.specializations
                                      .slice(0, 2)
                                      .map((spec, index) => (
                                        <Badge
                                          key={index}
                                          variant="outline"
                                          className="text-xs"
                                        >
                                          {spec}
                                        </Badge>
                                      ))}
                                    {responder.specializations.length > 2 && (
                                      <Badge
                                        variant="outline"
                                        className="text-xs"
                                      >
                                        +{responder.specializations.length - 2}
                                      </Badge>
                                    )}
                                  </div>
                                )}
                            </div>
                          </div>
                        </CardContent>
                      </Card>
                    ))}
                  </div>
                )}
              </div>

              <DialogFooter className="pt-6">
                <Button
                  type="button"
                  variant="outline"
                  onClick={handleClose}
                  disabled={isExecuting}
                  className="bg-background border-input hover:bg-accent"
                >
                  <X className="h-4 w-4 mr-2" />
                  Cancel
                </Button>
                <Button
                  type="submit"
                  disabled={isExecuting || selectedResponders.length === 0}
                  className="bg-primary text-primary-foreground hover:bg-primary/90"
                >
                  <Save className="h-4 w-4 mr-2" />
                  {isExecuting
                    ? "Assigning..."
                    : `Assign ${selectedResponders.length} Responder${
                        selectedResponders.length !== 1 ? "s" : ""
                      }`}
                </Button>
              </DialogFooter>
            </form>
          </div>
        </DialogContent>
      </Dialog>

      {/* Feedback Modals */}
      <SuccessModal />
      <ErrorModal />
      <LoadingModal />
    </>
  );
};
