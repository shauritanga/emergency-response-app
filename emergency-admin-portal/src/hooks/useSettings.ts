import { useState, useEffect, useCallback } from "react";
import {
  settingsService,
  type SystemSettings,
  type UserPreferences,
} from "@/services/settingsService";

// Hook for system settings
export function useSystemSettings() {
  const [settings, setSettings] = useState<SystemSettings | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  const fetchSettings = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await settingsService.getSystemSettings();
      setSettings(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to fetch settings");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchSettings();
  }, [fetchSettings]);

  const updateSettings = useCallback(
    async (updates: Partial<SystemSettings>, updatedBy: string) => {
      try {
        setSaving(true);
        setError(null);

        // Validate settings
        const validation = await settingsService.validateSettings(updates);
        if (!validation.valid) {
          throw new Error(validation.errors.join(", "));
        }

        await settingsService.updateSystemSettings(updates, updatedBy);

        // Refresh settings
        await fetchSettings();
      } catch (err) {
        setError(
          err instanceof Error ? err.message : "Failed to update settings"
        );
        throw err;
      } finally {
        setSaving(false);
      }
    },
    [fetchSettings]
  );

  const initializeSettings = useCallback(
    async (updatedBy: string) => {
      try {
        setLoading(true);
        setError(null);
        await settingsService.initializeSystemSettings(updatedBy);
        await fetchSettings();
      } catch (err) {
        setError(
          err instanceof Error ? err.message : "Failed to initialize settings"
        );
      } finally {
        setLoading(false);
      }
    },
    [fetchSettings]
  );

  return {
    settings,
    loading,
    error,
    saving,
    updateSettings,
    initializeSettings,
    refresh: fetchSettings,
  };
}

// Hook for user preferences
export function useUserPreferences(userId: string) {
  const [preferences, setPreferences] = useState<UserPreferences | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  const fetchPreferences = useCallback(async () => {
    if (!userId) return;

    try {
      setLoading(true);
      setError(null);
      const data = await settingsService.getUserPreferences(userId);
      setPreferences(data);
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Failed to fetch preferences"
      );
    } finally {
      setLoading(false);
    }
  }, [userId]);

  useEffect(() => {
    fetchPreferences();
  }, [fetchPreferences]);

  const updatePreferences = useCallback(
    async (updates: Partial<UserPreferences>) => {
      try {
        setSaving(true);
        setError(null);

        const updatedPreferences = { ...preferences, ...updates, userId };
        await settingsService.updateUserPreferences(updatedPreferences);

        // Update local state
        setPreferences(updatedPreferences as UserPreferences);
      } catch (err) {
        setError(
          err instanceof Error ? err.message : "Failed to update preferences"
        );
        throw err;
      } finally {
        setSaving(false);
      }
    },
    [preferences, userId]
  );

  const initializePreferences = useCallback(async () => {
    if (!userId) return;

    try {
      setLoading(true);
      setError(null);
      await settingsService.initializeUserPreferences(userId);
      await fetchPreferences();
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Failed to initialize preferences"
      );
    } finally {
      setLoading(false);
    }
  }, [userId, fetchPreferences]);

  return {
    preferences,
    loading,
    error,
    saving,
    updatePreferences,
    initializePreferences,
    refresh: fetchPreferences,
  };
}

// Hook for system health
export function useSystemHealth() {
  const [health, setHealth] = useState<{
    status: "healthy" | "warning" | "critical";
    checks: Array<{
      name: string;
      status: "pass" | "fail" | "warning";
      message: string;
    }>;
  } | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const checkHealth = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const healthData = await settingsService.performHealthCheck();
      setHealth(healthData);
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Failed to check system health"
      );
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    checkHealth();

    // Set up periodic health checks
    const interval = setInterval(checkHealth, 60000); // Check every minute

    return () => clearInterval(interval);
  }, [checkHealth]);

  return {
    health,
    loading,
    error,
    refresh: checkHealth,
  };
}

// Hook for settings validation
export function useSettingsValidation() {
  const [validating, setValidating] = useState(false);
  const [validationErrors, setValidationErrors] = useState<string[]>([]);

  const validateSettings = useCallback(
    async (settings: Partial<SystemSettings>) => {
      try {
        setValidating(true);
        setValidationErrors([]);

        const validation = await settingsService.validateSettings(settings);

        if (!validation.valid) {
          setValidationErrors(validation.errors);
        }

        return validation;
      } catch (err) {
        const error = err instanceof Error ? err.message : "Validation failed";
        setValidationErrors([error]);
        return { valid: false, errors: [error] };
      } finally {
        setValidating(false);
      }
    },
    []
  );

  return {
    validating,
    validationErrors,
    validateSettings,
    clearErrors: () => setValidationErrors([]),
  };
}

// Hook for configuration backup/restore
export function useConfigurationBackup() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const exportConfiguration = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);

      const settings = await settingsService.getSystemSettings();

      const configData = {
        systemSettings: settings,
        exportedAt: new Date().toISOString(),
        version: "1.0",
      };

      // Create and download file
      const blob = new Blob([JSON.stringify(configData, null, 2)], {
        type: "application/json",
      });

      const url = URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      link.download = `emergency-system-config-${
        new Date().toISOString().split("T")[0]
      }.json`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      URL.revokeObjectURL(url);

      return configData;
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Failed to export configuration"
      );
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  const importConfiguration = useCallback(
    async (file: File, updatedBy: string) => {
      try {
        setLoading(true);
        setError(null);

        const text = await file.text();
        const configData = JSON.parse(text);

        if (!configData.systemSettings) {
          throw new Error("Invalid configuration file format");
        }

        // Validate the configuration
        const validation = await settingsService.validateSettings(
          configData.systemSettings
        );
        if (!validation.valid) {
          throw new Error(
            `Invalid configuration: ${validation.errors.join(", ")}`
          );
        }

        // Import the settings
        await settingsService.updateSystemSettings(
          configData.systemSettings,
          updatedBy
        );

        return configData;
      } catch (err) {
        setError(
          err instanceof Error ? err.message : "Failed to import configuration"
        );
        throw err;
      } finally {
        setLoading(false);
      }
    },
    []
  );

  return {
    loading,
    error,
    exportConfiguration,
    importConfiguration,
  };
}
