import React, { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { NotificationPreferencesComponent } from "@/components/notifications/NotificationPreferences";
import {
  useSystemSettings,
  useUserPreferences,
  useSystemHealth,
  useConfigurationBackup,
} from "@/hooks/useSettings";
import { useSettingsActionFeedback } from "@/hooks/useActionFeedback";
import {
  Settings as SettingsIcon,
  User,
  Shield,
  Bell,
  Database,
  Download,
  Upload,
  Save,
  RefreshCw,
  AlertTriangle,
  CheckCircle,
  XCircle,
  Activity,
} from "lucide-react";

export const Settings: React.FC = () => {
  const [activeTab, setActiveTab] = useState<
    "general" | "security" | "notifications" | "system" | "preferences"
  >("general");
  const [unsavedChanges, setUnsavedChanges] = useState(false);

  const {
    settings,
    loading: settingsLoading,
    saving: settingsSaving,
    updateSettings,
    refresh: refreshSettings,
  } = useSystemSettings();

  const {
    preferences,
    loading: preferencesLoading,
    saving: preferencesSaving,
    updatePreferences,
  } = useUserPreferences("admin-user-id");

  const {
    health,
    loading: healthLoading,
    refresh: refreshHealth,
  } = useSystemHealth();
  const {
    exportConfiguration,
    importConfiguration,
    loading: backupLoading,
  } = useConfigurationBackup();

  const {
    saveSettings,
    exportData,
    importData,
    SuccessModal,
    ErrorModal,
    LoadingModal,
  } = useSettingsActionFeedback();

  const tabs = [
    { id: "general", label: "General", icon: SettingsIcon },
    { id: "security", label: "Security", icon: Shield },
    { id: "notifications", label: "Notifications", icon: Bell },
    { id: "system", label: "System", icon: Database },
    { id: "preferences", label: "User Preferences", icon: User },
  ];

  const handleSettingsUpdate = async (updates: any) => {
    const result = await saveSettings(async () => {
      return await updateSettings(updates, "admin-user-id");
    });

    if (result) {
      setUnsavedChanges(false);
    }
  };

  const handleExportConfig = async () => {
    await exportData(async () => {
      return await exportConfiguration();
    });
  };

  const handleImportConfig = async (
    event: React.ChangeEvent<HTMLInputElement>
  ) => {
    const file = event.target.files?.[0];
    if (file) {
      try {
        await importConfiguration(file, "admin-user-id");
        await refreshSettings();
      } catch (error) {
        console.error("Failed to import configuration:", error);
      }
    }
  };

  const getHealthStatusIcon = (status: string) => {
    switch (status) {
      case "pass":
        return <CheckCircle className="h-4 w-4 text-green-500" />;
      case "warning":
        return <AlertTriangle className="h-4 w-4 text-yellow-500" />;
      case "fail":
        return <XCircle className="h-4 w-4 text-red-500" />;
      default:
        return <Activity className="h-4 w-4 text-gray-500" />;
    }
  };

  const renderGeneralSettings = () => {
    if (settingsLoading || !settings) {
      return (
        <div className="space-y-6">
          {[1, 2, 3].map((i) => (
            <Card key={i} className="bg-card border-border">
              <CardContent className="p-6">
                <div className="animate-pulse space-y-4">
                  <div className="h-4 bg-muted rounded w-1/3"></div>
                  <div className="h-10 bg-muted rounded"></div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      );
    }

    return (
      <div className="space-y-6">
        <Card className="bg-card border-border">
          <CardHeader>
            <CardTitle className="text-card-foreground">
              System Information
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label className="text-card-foreground">System Name</Label>
                <Input
                  value={settings.systemName}
                  onChange={(e) => {
                    handleSettingsUpdate({ systemName: e.target.value });
                    setUnsavedChanges(true);
                  }}
                  className="bg-background border-input"
                />
              </div>
              <div className="space-y-2">
                <Label className="text-card-foreground">Timezone</Label>
                <Select
                  value={settings.timezone}
                  onValueChange={(value) => {
                    handleSettingsUpdate({ timezone: value });
                    setUnsavedChanges(true);
                  }}
                >
                  <SelectTrigger className="bg-background border-input">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="UTC">UTC</SelectItem>
                    <SelectItem value="America/New_York">
                      Eastern Time
                    </SelectItem>
                    <SelectItem value="America/Chicago">
                      Central Time
                    </SelectItem>
                    <SelectItem value="America/Denver">
                      Mountain Time
                    </SelectItem>
                    <SelectItem value="America/Los_Angeles">
                      Pacific Time
                    </SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="space-y-2">
              <Label className="text-card-foreground">System Description</Label>
              <Textarea
                value={settings.systemDescription}
                onChange={(e) => {
                  handleSettingsUpdate({ systemDescription: e.target.value });
                  setUnsavedChanges(true);
                }}
                className="bg-background border-input"
                rows={3}
              />
            </div>
          </CardContent>
        </Card>

        <Card className="bg-card border-border">
          <CardHeader>
            <CardTitle className="text-card-foreground">
              Emergency Configuration
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label className="text-card-foreground">
                  Max Response Time (minutes)
                </Label>
                <Input
                  type="number"
                  value={settings.maxResponseTime}
                  onChange={(e) => {
                    handleSettingsUpdate({
                      maxResponseTime: parseInt(e.target.value),
                    });
                    setUnsavedChanges(true);
                  }}
                  className="bg-background border-input"
                />
              </div>
              <div className="space-y-2">
                <Label className="text-card-foreground">
                  Escalation Time (minutes)
                </Label>
                <Input
                  type="number"
                  value={settings.escalationTime}
                  onChange={(e) => {
                    handleSettingsUpdate({
                      escalationTime: parseInt(e.target.value),
                    });
                    setUnsavedChanges(true);
                  }}
                  className="bg-background border-input"
                />
              </div>
            </div>

            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <Label className="text-card-foreground">
                    Auto Assignment
                  </Label>
                  <p className="text-xs text-muted-foreground">
                    Automatically assign responders to new emergencies
                  </p>
                </div>
                <Switch
                  checked={settings.autoAssignmentEnabled}
                  onCheckedChange={(checked) => {
                    handleSettingsUpdate({ autoAssignmentEnabled: checked });
                    setUnsavedChanges(true);
                  }}
                />
              </div>

              <div className="flex items-center justify-between">
                <div>
                  <Label className="text-card-foreground">
                    Escalation Enabled
                  </Label>
                  <p className="text-xs text-muted-foreground">
                    Escalate emergencies if not responded to in time
                  </p>
                </div>
                <Switch
                  checked={settings.escalationEnabled}
                  onCheckedChange={(checked) => {
                    handleSettingsUpdate({ escalationEnabled: checked });
                    setUnsavedChanges(true);
                  }}
                />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    );
  };

  const renderSecuritySettings = () => {
    if (settingsLoading || !settings) {
      return <div className="animate-pulse">Loading security settings...</div>;
    }

    return (
      <div className="space-y-6">
        <Card className="bg-card border-border">
          <CardHeader>
            <CardTitle className="text-card-foreground">
              Authentication
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label className="text-card-foreground">
                  Session Timeout (minutes)
                </Label>
                <Input
                  type="number"
                  value={settings.sessionTimeout}
                  onChange={(e) => {
                    handleSettingsUpdate({
                      sessionTimeout: parseInt(e.target.value),
                    });
                    setUnsavedChanges(true);
                  }}
                  className="bg-background border-input"
                />
              </div>
              <div className="space-y-2">
                <Label className="text-card-foreground">
                  Max Login Attempts
                </Label>
                <Input
                  type="number"
                  value={settings.maxLoginAttempts}
                  onChange={(e) => {
                    handleSettingsUpdate({
                      maxLoginAttempts: parseInt(e.target.value),
                    });
                    setUnsavedChanges(true);
                  }}
                  className="bg-background border-input"
                />
              </div>
            </div>

            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <Label className="text-card-foreground">
                    Two-Factor Authentication
                  </Label>
                  <p className="text-xs text-muted-foreground">
                    Require 2FA for all user accounts
                  </p>
                </div>
                <Switch
                  checked={settings.twoFactorAuthRequired}
                  onCheckedChange={(checked) => {
                    handleSettingsUpdate({ twoFactorAuthRequired: checked });
                    setUnsavedChanges(true);
                  }}
                />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="bg-card border-border">
          <CardHeader>
            <CardTitle className="text-card-foreground">
              Password Policy
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label className="text-card-foreground">Minimum Length</Label>
              <Input
                type="number"
                value={settings.passwordMinLength}
                onChange={(e) => {
                  handleSettingsUpdate({
                    passwordMinLength: parseInt(e.target.value),
                  });
                  setUnsavedChanges(true);
                }}
                className="bg-background border-input"
              />
            </div>

            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <Label className="text-card-foreground">
                  Require Special Characters
                </Label>
                <Switch
                  checked={settings.passwordRequireSpecialChars}
                  onCheckedChange={(checked) => {
                    handleSettingsUpdate({
                      passwordRequireSpecialChars: checked,
                    });
                    setUnsavedChanges(true);
                  }}
                />
              </div>

              <div className="flex items-center justify-between">
                <Label className="text-card-foreground">Require Numbers</Label>
                <Switch
                  checked={settings.passwordRequireNumbers}
                  onCheckedChange={(checked) => {
                    handleSettingsUpdate({ passwordRequireNumbers: checked });
                    setUnsavedChanges(true);
                  }}
                />
              </div>

              <div className="flex items-center justify-between">
                <Label className="text-card-foreground">
                  Require Uppercase
                </Label>
                <Switch
                  checked={settings.passwordRequireUppercase}
                  onCheckedChange={(checked) => {
                    handleSettingsUpdate({ passwordRequireUppercase: checked });
                    setUnsavedChanges(true);
                  }}
                />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    );
  };

  const renderSystemSettings = () => {
    return (
      <div className="space-y-6">
        {/* System Health */}
        <Card className="bg-card border-border">
          <CardHeader>
            <CardTitle className="flex items-center justify-between text-card-foreground">
              <div className="flex items-center gap-2">
                <Activity className="h-5 w-5" />
                System Health
              </div>
              <Button
                variant="outline"
                size="sm"
                onClick={refreshHealth}
                disabled={healthLoading}
                className="cursor-pointer"
              >
                <RefreshCw
                  className={`h-4 w-4 mr-2 ${
                    healthLoading ? "animate-spin" : ""
                  }`}
                />
                Refresh
              </Button>
            </CardTitle>
          </CardHeader>
          <CardContent>
            {healthLoading ? (
              <div className="animate-pulse">Loading health status...</div>
            ) : health ? (
              <div className="space-y-4">
                <div className="flex items-center gap-2">
                  <Badge
                    className={`${
                      health.status === "healthy"
                        ? "bg-green-100 text-green-800 border-green-200 dark:bg-green-900/20 dark:text-green-400"
                        : health.status === "warning"
                        ? "bg-yellow-100 text-yellow-800 border-yellow-200 dark:bg-yellow-900/20 dark:text-yellow-400"
                        : "bg-red-100 text-red-800 border-red-200 dark:bg-red-900/20 dark:text-red-400"
                    }`}
                  >
                    System {health.status}
                  </Badge>
                </div>

                <div className="space-y-2">
                  {health.checks.map((check, index) => (
                    <div
                      key={index}
                      className="flex items-center justify-between p-3 rounded-lg bg-muted/30"
                    >
                      <div className="flex items-center gap-2">
                        {getHealthStatusIcon(check.status)}
                        <span className="text-sm font-medium text-card-foreground">
                          {check.name}
                        </span>
                      </div>
                      <span className="text-xs text-muted-foreground">
                        {check.message}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            ) : (
              <div className="text-muted-foreground">
                Unable to load health status
              </div>
            )}
          </CardContent>
        </Card>

        {/* Configuration Backup */}
        <Card className="bg-card border-border">
          <CardHeader>
            <CardTitle className="text-card-foreground">
              Configuration Management
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center gap-4">
              <Button
                onClick={handleExportConfig}
                disabled={backupLoading}
                className="cursor-pointer"
              >
                <Download className="h-4 w-4 mr-2" />
                Export Configuration
              </Button>

              <div className="relative">
                <input
                  type="file"
                  accept=".json"
                  onChange={handleImportConfig}
                  className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
                  disabled={backupLoading}
                />
                <Button
                  variant="outline"
                  disabled={backupLoading}
                  className="cursor-pointer"
                >
                  <Upload className="h-4 w-4 mr-2" />
                  Import Configuration
                </Button>
              </div>
            </div>

            <p className="text-xs text-muted-foreground">
              Export your current system configuration or import a previously
              saved configuration.
            </p>
          </CardContent>
        </Card>
      </div>
    );
  };

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-card-foreground">Settings</h1>
          <p className="text-muted-foreground">
            Configure system settings and preferences
          </p>
        </div>
        <div className="flex items-center gap-3">
          {unsavedChanges && (
            <Badge
              variant="outline"
              className="text-yellow-600 border-yellow-200"
            >
              Unsaved changes
            </Badge>
          )}
          <Button
            onClick={() => refreshSettings()}
            variant="outline"
            className="cursor-pointer"
          >
            <RefreshCw className="h-4 w-4 mr-2" />
            Refresh
          </Button>
        </div>
      </div>

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
      {activeTab === "general" && renderGeneralSettings()}
      {activeTab === "security" && renderSecuritySettings()}
      {activeTab === "notifications" && (
        <NotificationPreferencesComponent userId="admin-user-id" />
      )}
      {activeTab === "system" && renderSystemSettings()}
      {activeTab === "preferences" && (
        <Card className="bg-card border-border">
          <CardHeader>
            <CardTitle className="text-card-foreground">
              User Preferences
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-muted-foreground">
              User preference settings will be implemented here.
            </p>
          </CardContent>
        </Card>
      )}

      {/* Feedback Modals */}
      <SuccessModal />
      <ErrorModal />
      <LoadingModal />
    </div>
  );
};
