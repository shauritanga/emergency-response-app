import React, { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import {
  Clock,
  CheckCircle,
  AlertTriangle,
  PlayCircle,
  PauseCircle,
  XCircle,
  MessageSquare,
  Camera,
  MapPin,
  Users,
  Send,
  Paperclip,
} from "lucide-react";
import { formatDistanceToNow } from "date-fns";

interface StatusUpdateProps {
  emergencyId: string;
  currentStatus: string;
  onStatusUpdate?: (
    newStatus: string,
    message?: string,
    attachments?: File[]
  ) => void;
  onClose?: () => void;
}

export const StatusUpdate: React.FC<StatusUpdateProps> = ({
  emergencyId,
  currentStatus,
  onStatusUpdate,
  onClose,
}) => {
  const [selectedStatus, setSelectedStatus] = useState(currentStatus);
  const [updateMessage, setUpdateMessage] = useState("");
  const [attachments, setAttachments] = useState<File[]>([]);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const statusOptions = [
    {
      value: "pending",
      label: "Pending",
      description: "Emergency reported, awaiting response",
      icon: Clock,
      color: "text-yellow-600 bg-yellow-50 border-yellow-200",
      buttonColor: "bg-yellow-500 hover:bg-yellow-600",
    },
    {
      value: "dispatched",
      label: "Dispatched",
      description: "Responders have been assigned and notified",
      icon: PlayCircle,
      color: "text-blue-600 bg-blue-50 border-blue-200",
      buttonColor: "bg-blue-500 hover:bg-blue-600",
    },
    {
      value: "in_progress",
      label: "In Progress",
      description: "Responders are actively handling the emergency",
      icon: AlertTriangle,
      color: "text-orange-600 bg-orange-50 border-orange-200",
      buttonColor: "bg-orange-500 hover:bg-orange-600",
    },
    {
      value: "resolved",
      label: "Resolved",
      description: "Emergency has been successfully handled",
      icon: CheckCircle,
      color: "text-green-600 bg-green-50 border-green-200",
      buttonColor: "bg-green-500 hover:bg-green-600",
    },
    {
      value: "cancelled",
      label: "Cancelled",
      description: "Emergency was cancelled or false alarm",
      icon: XCircle,
      color: "text-red-600 bg-red-50 border-red-200",
      buttonColor: "bg-red-500 hover:bg-red-600",
    },
  ];

  const currentStatusOption = statusOptions.find(
    (option) => option.value === currentStatus
  );
  const selectedStatusOption = statusOptions.find(
    (option) => option.value === selectedStatus
  );

  const handleFileUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(event.target.files || []);
    setAttachments((prev) => [...prev, ...files]);
  };

  const removeAttachment = (index: number) => {
    setAttachments((prev) => prev.filter((_, i) => i !== index));
  };

  const handleSubmit = async () => {
    if (!selectedStatus || selectedStatus === currentStatus) return;

    setIsSubmitting(true);

    try {
      await onStatusUpdate?.(selectedStatus, updateMessage, attachments);
      onClose?.();
    } catch (error) {
      console.error("Failed to update status:", error);
    } finally {
      setIsSubmitting(false);
    }
  };

  const getStatusTransitions = (current: string) => {
    const transitions: { [key: string]: string[] } = {
      pending: ["dispatched", "cancelled"],
      dispatched: ["in_progress", "cancelled"],
      in_progress: ["resolved", "cancelled"],
      resolved: [],
      cancelled: ["pending"],
    };
    return transitions[current] || [];
  };

  const allowedTransitions = getStatusTransitions(currentStatus);
  const availableStatusOptions = statusOptions.filter((option) =>
    allowedTransitions.includes(option.value)
  );

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-2xl max-h-[90vh] overflow-y-auto border-0 shadow-2xl">
        <CardHeader className="border-b border-gray-200">
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="text-xl">Update Emergency Status</CardTitle>
              <p className="text-sm text-gray-600 mt-1">
                Change the status and add updates for emergency #{emergencyId}
              </p>
            </div>
            <Button
              variant="ghost"
              onClick={onClose}
              className="cursor-pointer"
            >
              <XCircle className="h-5 w-5" />
            </Button>
          </div>
        </CardHeader>

        <CardContent className="p-6">
          {/* Current Status */}
          <div className="mb-6">
            <h3 className="text-sm font-medium text-gray-900 mb-3">
              Current Status
            </h3>
            <div
              className={`flex items-center gap-3 p-4 rounded-lg border ${currentStatusOption?.color}`}
            >
              {currentStatusOption?.icon && (
                <currentStatusOption.icon className="h-6 w-6" />
              )}
              <div>
                <h4 className="font-semibold">{currentStatusOption?.label}</h4>
                <p className="text-sm opacity-80">
                  {currentStatusOption?.description}
                </p>
              </div>
            </div>
          </div>

          {/* Status Options */}
          <div className="mb-6">
            <h3 className="text-sm font-medium text-gray-900 mb-3">
              Update to
            </h3>
            {availableStatusOptions.length === 0 ? (
              <div className="text-center py-8 text-gray-500">
                <CheckCircle className="h-12 w-12 mx-auto mb-3 text-gray-400" />
                <p>No status updates available for this emergency.</p>
                <p className="text-sm">The emergency is in its final state.</p>
              </div>
            ) : (
              <div className="grid grid-cols-1 gap-3">
                {availableStatusOptions.map((option) => (
                  <button
                    key={option.value}
                    onClick={() => setSelectedStatus(option.value)}
                    className={`flex items-center gap-4 p-4 rounded-lg border-2 transition-all text-left ${
                      selectedStatus === option.value
                        ? `${option.color} border-current`
                        : "border-gray-200 hover:border-gray-300 bg-white"
                    }`}
                  >
                    <option.icon
                      className={`h-6 w-6 ${
                        selectedStatus === option.value ? "" : "text-gray-400"
                      }`}
                    />
                    <div className="flex-1">
                      <h4 className="font-semibold">{option.label}</h4>
                      <p className="text-sm opacity-80">{option.description}</p>
                    </div>
                    {selectedStatus === option.value && (
                      <CheckCircle className="h-5 w-5 text-current" />
                    )}
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* Update Message */}
          {selectedStatus && selectedStatus !== currentStatus && (
            <>
              <div className="mb-6">
                <label className="block text-sm font-medium text-gray-900 mb-2">
                  Update Message
                </label>
                <textarea
                  value={updateMessage}
                  onChange={(e) => setUpdateMessage(e.target.value)}
                  placeholder="Add details about this status update..."
                  rows={4}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none"
                />
              </div>

              {/* Attachments */}
              <div className="mb-6">
                <label className="block text-sm font-medium text-gray-900 mb-2">
                  Attachments (Optional)
                </label>
                <div className="border-2 border-dashed border-gray-300 rounded-lg p-4">
                  <input
                    type="file"
                    multiple
                    accept="image/*,video/*,.pdf,.doc,.docx"
                    onChange={handleFileUpload}
                    className="hidden"
                    id="file-upload"
                  />
                  <label
                    htmlFor="file-upload"
                    className="flex flex-col items-center justify-center cursor-pointer"
                  >
                    <Paperclip className="h-8 w-8 text-gray-400 mb-2" />
                    <span className="text-sm text-gray-600">
                      Click to upload photos, videos, or documents
                    </span>
                    <span className="text-xs text-gray-500 mt-1">
                      PNG, JPG, PDF, DOC up to 10MB each
                    </span>
                  </label>
                </div>

                {/* Attachment List */}
                {attachments.length > 0 && (
                  <div className="mt-3 space-y-2">
                    {attachments.map((file, index) => (
                      <div
                        key={index}
                        className="flex items-center justify-between p-2 bg-gray-50 rounded"
                      >
                        <div className="flex items-center gap-2">
                          <Paperclip className="h-4 w-4 text-gray-500" />
                          <span className="text-sm text-gray-700">
                            {file.name}
                          </span>
                          <span className="text-xs text-gray-500">
                            ({(file.size / 1024 / 1024).toFixed(1)} MB)
                          </span>
                        </div>
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => removeAttachment(index)}
                          className="h-6 w-6 p-0"
                        >
                          <XCircle className="h-4 w-4" />
                        </Button>
                      </div>
                    ))}
                  </div>
                )}
              </div>

              {/* Preview */}
              <div className="mb-6 p-4 bg-gray-50 rounded-lg">
                <h4 className="text-sm font-medium text-gray-900 mb-2">
                  Preview
                </h4>
                <div className="flex items-start gap-3">
                  <Avatar className="h-8 w-8">
                    <AvatarFallback className="bg-blue-500 text-white text-xs">
                      AD
                    </AvatarFallback>
                  </Avatar>
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <span className="text-sm font-medium">Admin</span>
                      <Badge variant="outline" className="text-xs">
                        Status Update
                      </Badge>
                      <span className="text-xs text-gray-500">now</span>
                    </div>
                    <p className="text-sm text-gray-700 mb-2">
                      Status changed from{" "}
                      <strong>{currentStatusOption?.label}</strong> to{" "}
                      <strong>{selectedStatusOption?.label}</strong>
                    </p>
                    {updateMessage && (
                      <p className="text-sm text-gray-600 bg-white p-2 rounded border">
                        {updateMessage}
                      </p>
                    )}
                    {attachments.length > 0 && (
                      <div className="flex items-center gap-1 mt-2 text-xs text-gray-500">
                        <Paperclip className="h-3 w-3" />
                        <span>
                          {attachments.length} attachment
                          {attachments.length > 1 ? "s" : ""}
                        </span>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            </>
          )}
        </CardContent>

        {/* Footer */}
        <div className="border-t border-gray-200 p-6">
          <div className="flex items-center justify-end gap-3">
            <Button variant="outline" onClick={onClose}>
              Cancel
            </Button>
            <Button
              onClick={handleSubmit}
              disabled={
                !selectedStatus ||
                selectedStatus === currentStatus ||
                isSubmitting
              }
              className={selectedStatusOption?.buttonColor}
            >
              {isSubmitting ? (
                <>
                  <Clock className="h-4 w-4 mr-2 animate-spin" />
                  Updating...
                </>
              ) : (
                <>
                  <Send className="h-4 w-4 mr-2" />
                  Update Status
                </>
              )}
            </Button>
          </div>
        </div>
      </Card>
    </div>
  );
};
