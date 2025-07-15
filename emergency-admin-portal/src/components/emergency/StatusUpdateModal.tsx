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
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { type Emergency, EmergencyStatus } from "@/types";
import {
  useUpdateEmergencyStatus,
  useAddTimelineEvent,
} from "@/hooks/useEmergencies";
import { useAuth } from "@/contexts/AuthContext";
import { useEmergencyActionFeedback } from "@/hooks/useActionFeedback";
import {
  AlertTriangle,
  CheckCircle,
  Clock,
  Save,
  X,
  AlertCircle,
} from "lucide-react";

interface StatusUpdateModalProps {
  emergency: Emergency | null;
  isOpen: boolean;
  onClose: () => void;
}

export const StatusUpdateModal: React.FC<StatusUpdateModalProps> = ({
  emergency,
  isOpen,
  onClose,
}) => {
  const [selectedStatus, setSelectedStatus] = useState<EmergencyStatus | "">(
    ""
  );
  const [notes, setNotes] = useState("");
  const [error, setError] = useState<string | null>(null);

  const { currentUser } = useAuth();
  const updateStatusMutation = useUpdateEmergencyStatus();
  const addTimelineEventMutation = useAddTimelineEvent();
  const { updateStatus, isExecuting, SuccessModal, ErrorModal, LoadingModal } =
    useEmergencyActionFeedback();

  const getStatusColor = (status: EmergencyStatus | string) => {
    switch (status) {
      case EmergencyStatus.REPORTED:
        return "bg-red-100 text-red-800 border-red-200";
      case EmergencyStatus.DISPATCHED:
        return "bg-yellow-100 text-yellow-800 border-yellow-200";
      case EmergencyStatus.IN_PROGRESS:
        return "bg-blue-100 text-blue-800 border-blue-200";
      case EmergencyStatus.RESOLVED:
        return "bg-green-100 text-green-800 border-green-200";
      default:
        return "bg-gray-100 text-gray-800 border-gray-200";
    }
  };

  const getStatusIcon = (status: EmergencyStatus | string) => {
    switch (status) {
      case EmergencyStatus.REPORTED:
        return <AlertTriangle className="h-5 w-5 text-red-600" />;
      case EmergencyStatus.DISPATCHED:
        return <Clock className="h-5 w-5 text-yellow-600" />;
      case EmergencyStatus.IN_PROGRESS:
        return <AlertCircle className="h-5 w-5 text-blue-600" />;
      case EmergencyStatus.RESOLVED:
        return <CheckCircle className="h-5 w-5 text-green-600" />;
      default:
        return <AlertTriangle className="h-5 w-5 text-gray-600" />;
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!emergency || !selectedStatus || !currentUser) {
      setError("Missing required information");
      return;
    }

    const result = await updateStatus(async () => {
      // Update emergency status
      await updateStatusMutation.mutateAsync({
        id: emergency.id,
        status: selectedStatus,
        userId: currentUser.uid,
        userName: currentUser.displayName || "Admin",
      });

      // Add timeline event with notes if provided
      if (notes.trim()) {
        await addTimelineEventMutation.mutateAsync({
          emergencyId: emergency.id,
          type: "status_update",
          title: `Status updated to ${selectedStatus}`,
          description: notes,
          userId: currentUser.uid,
          userName: currentUser.displayName || "Admin",
          userRole: "admin",
          timestamp: new Date(),
        });
      }

      return { status: selectedStatus };
    });

    if (result) {
      // Reset form and close modal on success
      setSelectedStatus("");
      setNotes("");
      setError(null);
      onClose();
    }
  };

  const handleClose = () => {
    setSelectedStatus("");
    setNotes("");
    setError(null);
    onClose();
  };

  if (!emergency) return null;

  return (
    <>
      <Dialog open={isOpen} onOpenChange={handleClose}>
        <DialogContent className="max-w-md bg-card border-border">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-3 text-card-foreground">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <AlertCircle className="h-5 w-5 text-blue-600 dark:text-blue-400" />
              </div>
              Update Emergency Status
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

              {/* Current Status */}
              <div className="space-y-2">
                <Label className="text-card-foreground">Current Status</Label>
                <div className="flex items-center gap-2 p-3 bg-muted rounded-lg">
                  {getStatusIcon(emergency.status)}
                  <Badge className={getStatusColor(emergency.status)}>
                    {emergency.status}
                  </Badge>
                </div>
              </div>

              {/* New Status */}
              <div className="space-y-2">
                <Label htmlFor="status" className="text-card-foreground">
                  New Status
                </Label>
                <Select
                  value={selectedStatus}
                  onValueChange={(value: EmergencyStatus) =>
                    setSelectedStatus(value)
                  }
                >
                  <SelectTrigger className="bg-background border-input">
                    <SelectValue placeholder="Select new status" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value={EmergencyStatus.REPORTED}>
                      <div className="flex items-center gap-2">
                        <div className="w-2 h-2 bg-red-500 rounded-full"></div>
                        Reported
                      </div>
                    </SelectItem>
                    <SelectItem value={EmergencyStatus.DISPATCHED}>
                      <div className="flex items-center gap-2">
                        <div className="w-2 h-2 bg-yellow-500 rounded-full"></div>
                        Dispatched
                      </div>
                    </SelectItem>
                    <SelectItem value={EmergencyStatus.IN_PROGRESS}>
                      <div className="flex items-center gap-2">
                        <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
                        In Progress
                      </div>
                    </SelectItem>
                    <SelectItem value={EmergencyStatus.RESOLVED}>
                      <div className="flex items-center gap-2">
                        <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                        Resolved
                      </div>
                    </SelectItem>
                  </SelectContent>
                </Select>
              </div>

              {/* Notes */}
              <div className="space-y-2">
                <Label htmlFor="notes" className="text-card-foreground">
                  Notes (Optional)
                </Label>
                <Textarea
                  id="notes"
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  placeholder="Add any additional information about this status change"
                  rows={3}
                  className="bg-background border-input text-foreground placeholder:text-muted-foreground"
                />
              </div>

              {/* Warning for Resolved Status */}
              {selectedStatus === EmergencyStatus.RESOLVED && (
                <div className="p-3 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg">
                  <div className="flex items-start gap-2">
                    <AlertTriangle className="h-5 w-5 text-yellow-600 dark:text-yellow-400 mt-0.5" />
                    <div>
                      <p className="text-sm font-medium text-yellow-800 dark:text-yellow-200">
                        Marking as Resolved
                      </p>
                      <p className="text-sm text-yellow-700 dark:text-yellow-300">
                        This will close the emergency and notify all involved
                        parties that the situation has been resolved.
                      </p>
                    </div>
                  </div>
                </div>
              )}

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
                  disabled={isExecuting || !selectedStatus}
                  className="bg-primary text-primary-foreground hover:bg-primary/90"
                >
                  <Save className="h-4 w-4 mr-2" />
                  {isExecuting ? "Updating..." : "Update Status"}
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
