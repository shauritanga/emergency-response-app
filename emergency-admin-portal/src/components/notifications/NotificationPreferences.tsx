import React from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Input } from "@/components/ui/input";

import {
  Bell,
  Mail,
  MessageSquare,
  AlertTriangle,
  Settings,
  Moon,
  RefreshCw,
  Check,
} from "lucide-react";
import { useNotificationPreferences } from "@/hooks/useNotifications";
import { useActionFeedback } from "@/hooks/useActionFeedback";
import { type NotificationPreferences } from "@/services/notificationService";

interface NotificationPreferencesProps {
  userId: string;
}

export const NotificationPreferencesComponent: React.FC<
  NotificationPreferencesProps
> = ({ userId }) => {
  const { preferences, loading, error, saving, updatePreferences, refresh } =
    useNotificationPreferences(userId);

  const { executeAction, SuccessModal, ErrorModal, LoadingModal } =
    useActionFeedback();

  if (loading) {
    return (
      <Card className="bg-card border-border">
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-card-foreground">
            <Bell className="h-5 w-5" />
            Notification Preferences
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {[1, 2, 3, 4].map((i) => (
              <div key={i} className="animate-pulse">
                <div className="h-4 bg-muted rounded w-1/3 mb-2"></div>
                <div className="h-10 bg-muted rounded"></div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    );
  }

  if (error || !preferences) {
    return (
      <Card className="bg-card border-border">
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-card-foreground">
            <Bell className="h-5 w-5 text-red-500" />
            Notification Preferences
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center gap-2 text-red-600 dark:text-red-400">
            <AlertTriangle className="h-4 w-4" />
            <span className="text-sm">Failed to load preferences</span>
            <Button
              variant="outline"
              size="sm"
              onClick={refresh}
              className="ml-auto cursor-pointer"
            >
              <RefreshCw className="h-4 w-4 mr-2" />
              Retry
            </Button>
          </div>
        </CardContent>
      </Card>
    );
  }

  const handleToggle = async (
    key: keyof NotificationPreferences,
    value: boolean
  ) => {
    const result = await executeAction(
      async () => {
        await updatePreferences({ [key]: value });
        return { setting: key, enabled: value };
      },
      {
        loadingTitle: "Updating Notification Setting",
        loadingMessage: `${value ? "Enabling" : "Disabling"} ${key
          .replace(/([A-Z])/g, " $1")
          .toLowerCase()}...`,
        successTitle: "Setting Updated",
        successMessage: `${key.replace(/([A-Z])/g, " $1")} has been ${
          value ? "enabled" : "disabled"
        }`,
        errorTitle: "Update Failed",
        errorMessage:
          "Unable to update notification setting. Please try again.",
        showDetails: false,
        autoCloseSuccess: true,
        retryable: true,
      }
    );

    if (!result) {
      // If the update failed, we might want to revert the UI state
      // The hook should handle this, but we can add additional logic here if needed
      console.warn(`Failed to update ${key} setting`);
    }
  };

  const handleQuietHoursToggle = (enabled: boolean) => {
    updatePreferences({
      quietHours: {
        ...preferences.quietHours,
        enabled,
      },
    });
  };

  const handleQuietHoursTimeChange = (type: "start" | "end", value: string) => {
    updatePreferences({
      quietHours: {
        ...preferences.quietHours,
        [type]: value,
      },
    });
  };

  // Helper function to render enhanced switch components
  const renderEnhancedSwitch = (
    key: keyof NotificationPreferences,
    icon: React.ReactNode,
    title: string,
    description: string
  ) => {
    const isEnabled = preferences[key] as boolean;

    return (
      <div
        className={`group relative overflow-hidden rounded-xl border-2 transition-all duration-300 ${
          isEnabled
            ? "border-green-300 bg-gradient-to-r from-green-50 via-emerald-50 to-green-50 dark:border-green-600 dark:from-green-950/40 dark:via-emerald-950/40 dark:to-green-950/40 shadow-lg shadow-green-100 dark:shadow-green-900/20"
            : "border-gray-200 bg-white dark:border-gray-600 dark:bg-gray-800/60 hover:border-gray-300 dark:hover:border-gray-500"
        } hover:shadow-xl hover:scale-[1.01] cursor-pointer`}
      >
        {/* Animated background gradient for enabled state */}
        {isEnabled && (
          <div className="absolute inset-0 bg-gradient-to-r from-green-400/10 via-emerald-400/10 to-green-400/10 animate-pulse" />
        )}

        <div className="relative flex items-center justify-between p-6">
          <div className="flex items-center gap-5">
            {/* Enhanced icon container */}
            <div
              className={`relative p-4 rounded-2xl transition-all duration-300 ${
                isEnabled
                  ? "bg-gradient-to-br from-green-100 via-emerald-100 to-green-200 dark:from-green-800/60 dark:via-emerald-800/60 dark:to-green-800/60 shadow-lg shadow-green-200/50 dark:shadow-green-800/30 scale-110"
                  : "bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600"
              }`}
            >
              <div
                className={`h-6 w-6 transition-all duration-300 ${
                  isEnabled
                    ? "text-green-600 dark:text-green-300 drop-shadow-sm"
                    : "text-gray-500 dark:text-gray-400"
                }`}
              >
                {icon}
              </div>

              {/* Status indicator badge */}
              {isEnabled && (
                <div className="absolute -top-1 -right-1 h-4 w-4 bg-green-500 rounded-full flex items-center justify-center shadow-lg animate-bounce">
                  <Check className="h-2.5 w-2.5 text-white font-bold" />
                </div>
              )}
            </div>

            {/* Content section */}
            <div className="flex-1">
              <div className="flex items-center gap-3 mb-2">
                <Label className="text-lg font-bold text-gray-900 dark:text-gray-100 cursor-pointer tracking-tight">
                  {title}
                </Label>
                <div
                  className={`px-2 py-1 rounded-full text-xs font-semibold transition-all duration-300 ${
                    isEnabled
                      ? "bg-green-100 text-green-800 dark:bg-green-800/40 dark:text-green-200 shadow-sm"
                      : "bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-400"
                  }`}
                >
                  {isEnabled ? "ACTIVE" : "INACTIVE"}
                </div>
              </div>
              <p className="text-sm text-gray-600 dark:text-gray-300 leading-relaxed font-medium">
                {description}
              </p>
            </div>
          </div>

          {/* Switch section with enhanced styling */}
          <div className="flex items-center gap-6">
            <div className="text-right">
              <div
                className={`text-lg font-bold transition-all duration-300 ${
                  isEnabled
                    ? "text-green-700 dark:text-green-300 drop-shadow-sm"
                    : "text-gray-500 dark:text-gray-400"
                }`}
              >
                {isEnabled ? "ON" : "OFF"}
              </div>
              <div
                className={`text-xs font-medium transition-all duration-300 ${
                  isEnabled
                    ? "text-green-600 dark:text-green-400"
                    : "text-gray-400 dark:text-gray-500"
                }`}
              >
                {isEnabled ? "Notifications enabled" : "Notifications disabled"}
              </div>
            </div>

            {/* Enhanced switch with loading state */}
            <div className="relative">
              <Switch
                checked={isEnabled}
                onCheckedChange={(checked) => handleToggle(key, checked)}
                disabled={saving}
                className="transform hover:scale-110 transition-transform duration-200"
              />
              {saving && (
                <div className="absolute inset-0 flex items-center justify-center bg-white/80 dark:bg-gray-800/80 rounded-full">
                  <div className="h-4 w-4 animate-spin rounded-full border-2 border-gray-300 border-t-blue-600"></div>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Bottom accent line for enabled state */}
        {isEnabled && (
          <div className="absolute bottom-0 left-0 right-0 h-1 bg-gradient-to-r from-green-400 via-emerald-400 to-green-400 rounded-b-xl" />
        )}
      </div>
    );
  };

  return (
    <div className="space-y-6">
      <Card className="bg-card border-border">
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-card-foreground">
            <Bell className="h-5 w-5" />
            Notification Preferences
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-6">
          {/* Delivery Methods */}
          <div className="space-y-6">
            <div className="flex items-center gap-3 pb-4 border-b border-gray-200 dark:border-gray-700">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <Bell className="h-5 w-5 text-blue-600 dark:text-blue-400" />
              </div>
              <h3 className="text-xl font-bold text-gray-900 dark:text-gray-100">
                Delivery Methods
              </h3>
            </div>

            <div className="space-y-6">
              {renderEnhancedSwitch(
                "pushNotifications",
                <Bell />,
                "Push Notifications",
                "Receive notifications in your browser"
              )}

              {renderEnhancedSwitch(
                "emailNotifications",
                <Mail />,
                "Email Notifications",
                "Receive notifications via email"
              )}

              {renderEnhancedSwitch(
                "smsNotifications",
                <MessageSquare />,
                "SMS Notifications",
                "Receive critical alerts via SMS"
              )}
            </div>
          </div>

          {/* Notification Types */}
          <div className="space-y-6">
            <div className="flex items-center gap-3 pb-4 border-b border-gray-200 dark:border-gray-700">
              <div className="p-2 bg-red-100 dark:bg-red-900/30 rounded-lg">
                <AlertTriangle className="h-5 w-5 text-red-600 dark:text-red-400" />
              </div>
              <h3 className="text-xl font-bold text-gray-900 dark:text-gray-100">
                Notification Types
              </h3>
            </div>

            <div className="space-y-6">
              {renderEnhancedSwitch(
                "emergencyAlerts",
                <AlertTriangle />,
                "Emergency Alerts",
                "Critical emergency notifications"
              )}

              {renderEnhancedSwitch(
                "systemUpdates",
                <Settings />,
                "System Updates",
                "System maintenance and updates"
              )}

              {renderEnhancedSwitch(
                "reportReminders",
                <Bell />,
                "Report Reminders",
                "Scheduled report notifications"
              )}

              {renderEnhancedSwitch(
                "maintenanceAlerts",
                <AlertTriangle />,
                "Maintenance Alerts",
                "Scheduled maintenance notifications"
              )}
            </div>
          </div>

          {/* Quiet Hours */}
          <div className="space-y-6">
            <div className="flex items-center gap-3 pb-4 border-b border-gray-200 dark:border-gray-700">
              <div className="p-2 bg-purple-100 dark:bg-purple-900/30 rounded-lg">
                <Moon className="h-5 w-5 text-purple-600 dark:text-purple-400" />
              </div>
              <h3 className="text-xl font-bold text-gray-900 dark:text-gray-100">
                Quiet Hours
              </h3>
            </div>

            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <Moon className="h-4 w-4 text-indigo-500" />
                  <div>
                    <Label className="text-card-foreground">
                      Enable Quiet Hours
                    </Label>
                    <p className="text-xs text-muted-foreground">
                      Reduce notifications during specified hours (critical
                      alerts only)
                    </p>
                  </div>
                </div>
                <Switch
                  checked={preferences.quietHours.enabled}
                  onCheckedChange={handleQuietHoursToggle}
                />
              </div>

              {preferences.quietHours.enabled && (
                <div className="grid grid-cols-2 gap-4 ml-7">
                  <div className="space-y-2">
                    <Label className="text-card-foreground">Start Time</Label>
                    <Input
                      type="time"
                      value={preferences.quietHours.start}
                      onChange={(e) =>
                        handleQuietHoursTimeChange("start", e.target.value)
                      }
                      className="bg-background border-input"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label className="text-card-foreground">End Time</Label>
                    <Input
                      type="time"
                      value={preferences.quietHours.end}
                      onChange={(e) =>
                        handleQuietHoursTimeChange("end", e.target.value)
                      }
                      className="bg-background border-input"
                    />
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Save Button */}
          <div className="flex items-center justify-between pt-4 border-t border-border">
            <p className="text-xs text-muted-foreground">
              Changes are saved automatically
            </p>
            <div className="flex items-center gap-2">
              {saving && (
                <div className="flex items-center gap-2 text-sm text-muted-foreground">
                  <RefreshCw className="h-3 w-3 animate-spin" />
                  Saving...
                </div>
              )}
              <Button
                variant="outline"
                size="sm"
                onClick={refresh}
                className="cursor-pointer"
              >
                <RefreshCw className="h-4 w-4 mr-2" />
                Refresh
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Feedback Modals */}
      <SuccessModal />
      <ErrorModal />
      <LoadingModal />
    </div>
  );
};
