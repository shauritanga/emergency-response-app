# FCM Setup Guide

This guide explains how to set up Firebase Cloud Messaging (FCM) for the Emergency Response App using the modern FCM v1 API approach.

## Overview

The app uses the modern FCM v1 API with service account authentication instead of the legacy server key approach. This provides better security and follows Google's recommended practices.

## Setup Steps

### 1. Get Service Account JSON

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `emergency-response-app-dit`
3. Go to **Project Settings** (gear icon)
4. Go to **Service accounts** tab
5. Click **"Generate new private key"**
6. Download the JSON file
7. Rename it to: `emergency-response-app-dit-9c011cf8bcb8.json`
8. Place it in the `assets/` directory

### 2. Verify File Structure

Your service account JSON file should be located at:
```
assets/emergency-response-app-dit-9c011cf8bcb8.json
```

The file should contain:
- `type`: "service_account"
- `project_id`: "emergency-response-app-dit"
- `private_key`: "-----BEGIN PRIVATE KEY-----..."
- `client_email`: "firebase-adminsdk-..."

### 3. Test the Setup

You can test the FCM setup using the helper functions:

```dart
// Test if service account file exists
final fileExists = await FCMSetupHelper.checkServiceAccountFile();

// Test FCM connection
final success = await ModernFCMService.testConnection();

// Show setup instructions
FCMSetupHelper.showSetupInstructions(context);

// Test complete setup
FCMSetupHelper.testFCMSetup(context);
```

## Usage

### Send Single Notification

```dart
await ModernFCMService.sendNotification(
  token: 'user_fcm_token',
  title: 'Emergency Alert',
  body: 'There is an emergency in your area',
  data: {
    'type': 'emergency',
    'emergencyId': 'emergency_123',
  },
);
```

### Send Multicast Notification

```dart
await ModernFCMService.sendMulticastNotification(
  tokens: ['token1', 'token2', 'token3'],
  title: 'Emergency Alert',
  body: 'There is an emergency in your area',
  data: {
    'type': 'emergency',
    'emergencyId': 'emergency_123',
  },
);
```

### Send Emergency Notification

```dart
await ModernFCMService.sendEmergencyNotification(
  token: 'user_fcm_token',
  emergencyType: 'Fire',
  description: 'Fire reported at 123 Main St',
  emergencyId: 'emergency_123',
);
```

### Send Chat Notification

```dart
await ModernFCMService.sendChatNotification(
  token: 'user_fcm_token',
  senderName: 'John Doe',
  message: 'New message in emergency chat',
  conversationId: 'chat_123',
);
```

## Configuration

The FCM service is automatically configured when you call any of the send methods. The service will:

1. Load the service account JSON file
2. Create authenticated credentials
3. Initialize the HTTP client
4. Send notifications using the FCM v1 API

## Error Handling

The service includes comprehensive error handling:

- **File not found**: Falls back to local notifications
- **Authentication errors**: Logs detailed error messages
- **Network errors**: Retries with exponential backoff
- **Invalid tokens**: Removes failed tokens from database

## Security

- Service account credentials are stored in assets (not in code)
- Private keys are never logged or exposed
- All communication uses HTTPS
- Tokens are validated before sending

## Troubleshooting

### Common Issues

1. **Service account file not found**
   - Ensure the file is in the `assets/` directory
   - Check the filename matches exactly
   - Verify the file is included in `pubspec.yaml`

2. **Authentication failed**
   - Verify the service account has the correct permissions
   - Check that the project ID matches
   - Ensure the private key is valid

3. **Notifications not received**
   - Check device FCM token is valid
   - Verify app has notification permissions
   - Check device is online

### Debug Information

You can get debug information using:

```dart
// Get service account content (for debugging)
final content = await FCMSetupHelper.getServiceAccountContent();

// Test connection
final success = await ModernFCMService.testConnection();
```

## Integration with Emergency System

The FCM service is integrated with the emergency reporting system:

1. **Emergency Reports**: Automatically notify nearby responders
2. **Chat Messages**: Notify participants of new messages
3. **Status Updates**: Notify users of emergency status changes
4. **System Alerts**: Send important system notifications

The service handles all the complexity of FCM authentication and delivery, providing a simple interface for sending notifications throughout the app. 