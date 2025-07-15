# Firebase Action Feedback System

This document explains how to use the new modal-based feedback system for all Firebase data submission actions in the admin portal.

## Overview

The feedback system replaces `window.alert()` and `window.confirm()` with well-designed modals that provide:
- Loading states during operations
- Success feedback with auto-close options
- Error feedback with retry functionality
- Consistent styling that adapts to light/dark themes
- Professional user experience

## Components

### 1. FeedbackModal
The base modal component that handles all feedback types:
- `success` - Green themed success messages
- `error` - Red themed error messages with optional retry
- `warning` - Yellow themed warning messages
- `info` - Blue themed informational messages
- `loading` - Blue themed loading states with spinner

### 2. Action Feedback Hooks
Specialized hooks for different types of operations:

#### useUserActionFeedback()
For user management operations:
- `createUser()` - Creating new users
- `updateUser()` - Updating user information
- `deleteUser()` - Deleting users
- `toggleUserStatus()` - Changing user status

#### useEmergencyActionFeedback()
For emergency management operations:
- `updateStatus()` - Updating emergency status
- `assignResponder()` - Assigning responders
- `resolveEmergency()` - Resolving emergencies

#### useSettingsActionFeedback()
For system settings operations:
- `saveSettings()` - Saving configuration
- `resetSettings()` - Resetting to defaults
- `exportData()` - Exporting data
- `importData()` - Importing data

#### useNotificationActionFeedback()
For notification operations:
- `sendNotification()` - Sending notifications
- `markAsRead()` - Marking as read

## Usage Examples

### Basic User Creation
```tsx
import { useUserActionFeedback } from "@/hooks/useActionFeedback";

const MyComponent = () => {
  const { createUser, SuccessModal, ErrorModal, LoadingModal } = useUserActionFeedback();

  const handleCreateUser = async (userData) => {
    const result = await createUser(async () => {
      return await userService.create(userData);
    });

    if (result) {
      // Success - modal will show automatically
      // Reset form, close dialog, etc.
    }
    // Error handling is automatic with retry option
  };

  return (
    <>
      {/* Your component JSX */}
      <button onClick={handleCreateUser}>Create User</button>
      
      {/* Required: Add feedback modals */}
      <SuccessModal />
      <ErrorModal />
      <LoadingModal />
    </>
  );
};
```

### Emergency Status Update
```tsx
import { useEmergencyActionFeedback } from "@/hooks/useActionFeedback";

const StatusUpdateModal = ({ emergency }) => {
  const { updateStatus, SuccessModal, ErrorModal, LoadingModal } = useEmergencyActionFeedback();

  const handleStatusUpdate = async (newStatus) => {
    const result = await updateStatus(async () => {
      await emergencyService.updateStatus(emergency.id, newStatus);
      return { status: newStatus };
    });

    if (result) {
      onClose(); // Close modal on success
    }
  };

  return (
    <>
      <Dialog>
        {/* Modal content */}
      </Dialog>
      
      <SuccessModal />
      <ErrorModal />
      <LoadingModal />
    </>
  );
};
```

### Settings with Custom Messages
```tsx
import { useActionFeedback } from "@/hooks/useActionFeedback";

const SettingsPage = () => {
  const { executeAction, SuccessModal, ErrorModal, LoadingModal } = useActionFeedback();

  const handleSaveSettings = async (settings) => {
    const result = await executeAction(
      async () => {
        return await settingsService.save(settings);
      },
      {
        loadingTitle: "Saving Configuration",
        loadingMessage: "Updating system settings...",
        successTitle: "Settings Saved",
        successMessage: "Your configuration has been saved successfully",
        errorTitle: "Save Failed",
        errorMessage: "Unable to save settings. Please check your connection and try again.",
        showDetails: true,
        autoCloseSuccess: true,
        retryable: true,
      }
    );

    if (result) {
      setUnsavedChanges(false);
    }
  };

  return (
    <>
      {/* Settings form */}
      
      <SuccessModal />
      <ErrorModal />
      <LoadingModal />
    </>
  );
};
```

## Features

### Auto-close Success Messages
Success modals can automatically close after a delay:
```tsx
const { showSuccess } = useSuccessFeedback();
showSuccess("Operation Complete", "Data saved successfully", undefined, true); // auto-close enabled
```

### Retry Functionality
Error modals can include retry buttons:
```tsx
const { showError } = useErrorFeedback();
showError(
  "Operation Failed", 
  "Unable to save data", 
  "Network timeout error",
  () => retryOperation() // retry function
);
```

### Loading States
Loading modals prevent user interaction during operations:
```tsx
const { showLoading, hideLoading } = useLoadingFeedback();
showLoading("Processing", "Please wait while we save your changes...");
// Operation happens
hideLoading();
```

### Theme Support
All modals automatically adapt to light/dark themes using CSS variables and Tailwind classes.

## Migration Guide

### Before (using window alerts)
```tsx
const handleSubmit = async () => {
  try {
    await apiCall();
    window.alert("Success!");
  } catch (error) {
    window.alert("Error: " + error.message);
  }
};
```

### After (using feedback modals)
```tsx
const { executeAction, SuccessModal, ErrorModal, LoadingModal } = useActionFeedback();

const handleSubmit = async () => {
  const result = await executeAction(async () => {
    return await apiCall();
  });
  
  if (result) {
    // Handle success
  }
};

// In JSX:
<>
  {/* Component content */}
  <SuccessModal />
  <ErrorModal />
  <LoadingModal />
</>
```

## Best Practices

1. **Always include all three modals** (`SuccessModal`, `ErrorModal`, `LoadingModal`) in your component
2. **Use specialized hooks** for common operations (user, emergency, settings, notifications)
3. **Provide meaningful messages** that help users understand what happened
4. **Enable retry for recoverable errors** but disable for destructive operations
5. **Use auto-close for success messages** that don't require user acknowledgment
6. **Include error details** in development/debug modes for troubleshooting

## Implementation Status

✅ **Completed Components:**
- UserCreateModal
- UserEditModal  
- StatusUpdateModal
- ResponderAssignmentModal
- Settings page

🔄 **Next Steps:**
- Update remaining modals and forms
- Add confirmation dialogs for destructive actions
- Implement bulk operation feedback
- Add progress indicators for long operations
