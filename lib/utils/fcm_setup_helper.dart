import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../services/modern_fcm_service.dart';

class FCMSetupHelper {
  /// Check if service account file exists
  static Future<bool> checkServiceAccountFile() async {
    try {
      await rootBundle.loadString(
        'assets/emergency-response-app-dit-firebase-adminsdk-fbsvc-f1e8212865.json',
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Show FCM setup instructions
  static void showSetupInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('FCM Setup Instructions'),
            content: const SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('To set up FCM with modern approach:'),
                  SizedBox(height: 8),
                  Text('1. Go to Firebase Console'),
                  Text('2. Select project: emergency-response-app-dit'),
                  Text('3. Go to Project Settings (gear icon)'),
                  Text('4. Go to Service accounts tab'),
                  Text('5. Click "Generate new private key"'),
                  Text('6. Download the JSON file'),
                  Text(
                    '7. Rename it to: emergency-response-app-dit-firebase-adminsdk-fbsvc-f1e8212865.json',
                  ),
                  Text('8. Place it in: assets/ directory'),
                  SizedBox(height: 8),
                  Text('The file should contain:'),
                  Text('• type: "service_account"'),
                  Text('• project_id: "emergency-response-app-dit"'),
                  Text('• private_key: "-----BEGIN PRIVATE KEY-----..."'),
                  Text('• client_email: "firebase-adminsdk-..."'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  /// Test FCM setup
  static Future<void> testFCMSetup(BuildContext context) async {
    try {
      // Check if service account file exists
      final fileExists = await checkServiceAccountFile();
      if (!fileExists) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Service Account File Missing'),
                content: const Text(
                  'The service account JSON file is missing. Please follow the setup instructions.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      showSetupInstructions(context);
                    },
                    child: const Text('Show Instructions'),
                  ),
                ],
              ),
        );
        return;
      }

      // Test FCM connection
      final success = await ModernFCMService.testConnection();

      if (success) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('FCM Setup Successful'),
                content: const Text(
                  'FCM is properly configured and ready to send notifications!',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      } else {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('FCM Setup Failed'),
                content: const Text(
                  'Failed to initialize FCM. Please check your service account configuration.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('FCM Setup Error'),
              content: Text('Error: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  /// Get service account file content (for debugging)
  static Future<String?> getServiceAccountContent() async {
    try {
      return await rootBundle.loadString(
        'assets/emergency-response-app-dit-firebase-adminsdk-fbsvc-f1e8212865.json',
      );
    } catch (e) {
      return null;
    }
  }
}
