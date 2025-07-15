import { useState, useCallback } from "react";
import { useSuccessFeedback, useErrorFeedback, useLoadingFeedback } from "@/components/ui/feedback-modal";

interface ActionOptions {
  loadingTitle?: string;
  loadingMessage?: string;
  successTitle?: string;
  successMessage?: string;
  errorTitle?: string;
  errorMessage?: string;
  showDetails?: boolean;
  autoCloseSuccess?: boolean;
  retryable?: boolean;
}

export const useActionFeedback = () => {
  const { showSuccess, hideSuccess, SuccessModal } = useSuccessFeedback();
  const { showError, hideError, ErrorModal } = useErrorFeedback();
  const { showLoading, hideLoading, LoadingModal } = useLoadingFeedback();
  
  const [isExecuting, setIsExecuting] = useState(false);

  const executeAction = useCallback(async <T>(
    action: () => Promise<T>,
    options: ActionOptions = {}
  ): Promise<T | null> => {
    const {
      loadingTitle = "Processing",
      loadingMessage = "Please wait while we process your request...",
      successTitle = "Success",
      successMessage = "Operation completed successfully",
      errorTitle = "Error",
      errorMessage = "An error occurred while processing your request",
      showDetails = true,
      autoCloseSuccess = true,
      retryable = true,
    } = options;

    setIsExecuting(true);
    showLoading(loadingTitle, loadingMessage);

    try {
      const result = await action();
      
      hideLoading();
      showSuccess(
        successTitle,
        successMessage,
        showDetails ? "Operation completed at " + new Date().toLocaleString() : undefined,
        autoCloseSuccess
      );
      
      return result;
    } catch (error) {
      hideLoading();
      
      const errorDetails = showDetails && error instanceof Error 
        ? error.message 
        : undefined;

      if (retryable) {
        showError(
          errorTitle,
          errorMessage,
          errorDetails,
          () => executeAction(action, options)
        );
      } else {
        showError(errorTitle, errorMessage, errorDetails);
      }
      
      return null;
    } finally {
      setIsExecuting(false);
    }
  }, [showSuccess, showError, showLoading, hideLoading]);

  const executeWithConfirmation = useCallback(async <T>(
    action: () => Promise<T>,
    confirmationOptions: {
      title: string;
      description: string;
      confirmText?: string;
      variant?: "danger" | "warning" | "info";
    },
    actionOptions: ActionOptions = {}
  ): Promise<T | null> => {
    return new Promise((resolve) => {
      // We'll implement this with a confirmation modal
      // For now, just execute the action directly
      executeAction(action, actionOptions).then(resolve);
    });
  }, [executeAction]);

  return {
    executeAction,
    executeWithConfirmation,
    isExecuting,
    SuccessModal,
    ErrorModal,
    LoadingModal,
    // Direct access to individual feedback methods
    showSuccess,
    showError,
    showLoading,
    hideSuccess,
    hideError,
    hideLoading,
  };
};

// Specialized hooks for common operations
export const useUserActionFeedback = () => {
  const feedback = useActionFeedback();

  const createUser = useCallback((action: () => Promise<any>) => {
    return feedback.executeAction(action, {
      loadingTitle: "Creating User",
      loadingMessage: "Adding new user to the system...",
      successTitle: "User Created",
      successMessage: "New user has been successfully added to the system",
      errorTitle: "Failed to Create User",
      errorMessage: "Unable to create user. Please check the information and try again.",
    });
  }, [feedback]);

  const updateUser = useCallback((action: () => Promise<any>) => {
    return feedback.executeAction(action, {
      loadingTitle: "Updating User",
      loadingMessage: "Saving user changes...",
      successTitle: "User Updated",
      successMessage: "User information has been successfully updated",
      errorTitle: "Failed to Update User",
      errorMessage: "Unable to save user changes. Please try again.",
    });
  }, [feedback]);

  const deleteUser = useCallback((action: () => Promise<any>) => {
    return feedback.executeAction(action, {
      loadingTitle: "Deleting User",
      loadingMessage: "Removing user from the system...",
      successTitle: "User Deleted",
      successMessage: "User has been successfully removed from the system",
      errorTitle: "Failed to Delete User",
      errorMessage: "Unable to delete user. Please try again.",
      retryable: false,
    });
  }, [feedback]);

  const toggleUserStatus = useCallback((action: () => Promise<any>) => {
    return feedback.executeAction(action, {
      loadingTitle: "Updating Status",
      loadingMessage: "Changing user status...",
      successTitle: "Status Updated",
      successMessage: "User status has been successfully changed",
      errorTitle: "Failed to Update Status",
      errorMessage: "Unable to change user status. Please try again.",
    });
  }, [feedback]);

  return {
    ...feedback,
    createUser,
    updateUser,
    deleteUser,
    toggleUserStatus,
  };
};

export const useEmergencyActionFeedback = () => {
  const feedback = useActionFeedback();

  const updateStatus = useCallback((action: () => Promise<any>) => {
    return feedback.executeAction(action, {
      loadingTitle: "Updating Emergency Status",
      loadingMessage: "Changing emergency status...",
      successTitle: "Status Updated",
      successMessage: "Emergency status has been successfully updated",
      errorTitle: "Failed to Update Status",
      errorMessage: "Unable to update emergency status. Please try again.",
    });
  }, [feedback]);

  const assignResponder = useCallback((action: () => Promise<any>) => {
    return feedback.executeAction(action, {
      loadingTitle: "Assigning Responder",
      loadingMessage: "Assigning responder to emergency...",
      successTitle: "Responder Assigned",
      successMessage: "Responder has been successfully assigned to this emergency",
      errorTitle: "Failed to Assign Responder",
      errorMessage: "Unable to assign responder. Please try again.",
    });
  }, [feedback]);

  const resolveEmergency = useCallback((action: () => Promise<any>) => {
    return feedback.executeAction(action, {
      loadingTitle: "Resolving Emergency",
      loadingMessage: "Marking emergency as resolved...",
      successTitle: "Emergency Resolved",
      successMessage: "Emergency has been successfully marked as resolved",
      errorTitle: "Failed to Resolve Emergency",
      errorMessage: "Unable to resolve emergency. Please try again.",
    });
  }, [feedback]);

  return {
    ...feedback,
    updateStatus,
    assignResponder,
    resolveEmergency,
  };
};

export const useSettingsActionFeedback = () => {
  const feedback = useActionFeedback();

  const saveSettings = useCallback((action: () => Promise<any>) => {
    return feedback.executeAction(action, {
      loadingTitle: "Saving Settings",
      loadingMessage: "Updating system settings...",
      successTitle: "Settings Saved",
      successMessage: "System settings have been successfully updated",
      errorTitle: "Failed to Save Settings",
      errorMessage: "Unable to save settings. Please try again.",
    });
  }, [feedback]);

  const resetSettings = useCallback((action: () => Promise<any>) => {
    return feedback.executeAction(action, {
      loadingTitle: "Resetting Settings",
      loadingMessage: "Restoring default settings...",
      successTitle: "Settings Reset",
      successMessage: "Settings have been successfully reset to defaults",
      errorTitle: "Failed to Reset Settings",
      errorMessage: "Unable to reset settings. Please try again.",
      retryable: false,
    });
  }, [feedback]);

  const exportData = useCallback((action: () => Promise<any>) => {
    return feedback.executeAction(action, {
      loadingTitle: "Exporting Data",
      loadingMessage: "Preparing data export...",
      successTitle: "Export Complete",
      successMessage: "Data has been successfully exported",
      errorTitle: "Export Failed",
      errorMessage: "Unable to export data. Please try again.",
    });
  }, [feedback]);

  const importData = useCallback((action: () => Promise<any>) => {
    return feedback.executeAction(action, {
      loadingTitle: "Importing Data",
      loadingMessage: "Processing import file...",
      successTitle: "Import Complete",
      successMessage: "Data has been successfully imported",
      errorTitle: "Import Failed",
      errorMessage: "Unable to import data. Please check the file and try again.",
    });
  }, [feedback]);

  return {
    ...feedback,
    saveSettings,
    resetSettings,
    exportData,
    importData,
  };
};

export const useNotificationActionFeedback = () => {
  const feedback = useActionFeedback();

  const sendNotification = useCallback((action: () => Promise<any>) => {
    return feedback.executeAction(action, {
      loadingTitle: "Sending Notification",
      loadingMessage: "Delivering notification to recipients...",
      successTitle: "Notification Sent",
      successMessage: "Notification has been successfully sent",
      errorTitle: "Failed to Send Notification",
      errorMessage: "Unable to send notification. Please try again.",
    });
  }, [feedback]);

  const markAsRead = useCallback((action: () => Promise<any>) => {
    return feedback.executeAction(action, {
      loadingTitle: "Updating Notification",
      loadingMessage: "Marking notification as read...",
      successTitle: "Notification Updated",
      successMessage: "Notification has been marked as read",
      errorTitle: "Failed to Update Notification",
      errorMessage: "Unable to update notification status. Please try again.",
      autoCloseSuccess: true,
    });
  }, [feedback]);

  return {
    ...feedback,
    sendNotification,
    markAsRead,
  };
};
