import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

/// Handles authentication errors and provides user-friendly error messages
class AuthErrorHandler {
  /// Converts Firebase Auth exceptions to user-friendly error messages
  static String getErrorMessage(dynamic error) {
    // Handle network connectivity issues
    if (error is SocketException) {
      return 'No internet connection. Please check your network and try again.';
    }

    // Handle Firestore errors
    if (error is FirebaseException) {
      switch (error.code) {
        case 'unavailable':
          return 'Service temporarily unavailable. Please try again later.';
        case 'permission-denied':
          return 'Access denied. Please contact support if this persists.';
        case 'deadline-exceeded':
          return 'Request timed out. Please check your connection and try again.';
        default:
          return 'A service error occurred. Please try again.';
      }
    }

    // Handle Firebase Auth specific errors
    if (error is FirebaseAuthException) {
      switch (error.code) {
        // Sign in errors
        case 'user-not-found':
          return 'No account found with this email address. Please check your email or create a new account.';
        case 'wrong-password':
          return 'Incorrect password. Please try again or reset your password.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'too-many-requests':
          return 'Too many failed login attempts. Please try again later or reset your password.';
        case 'operation-not-allowed':
          return 'Email/password sign-in is not enabled. Please contact support.';

        // Registration errors
        case 'email-already-in-use':
          return 'An account already exists with this email address. Please sign in instead.';
        case 'weak-password':
          return 'Password is too weak. Please choose a stronger password with at least 8 characters.';
        case 'invalid-credential':
          return 'The provided credentials are invalid. Please try again.';

        // Network and connectivity errors
        case 'network-request-failed':
          return 'Network error. Please check your internet connection and try again.';
        case 'timeout':
          return 'Request timed out. Please try again.';

        // General errors
        case 'internal-error':
          return 'An internal error occurred. Please try again later.';
        case 'invalid-api-key':
          return 'Configuration error. Please contact support.';
        case 'app-not-authorized':
          return 'App not authorized. Please contact support.';

        default:
          return 'Authentication failed. Please try again or contact support if the problem persists.';
      }
    }

    // Handle generic exceptions
    if (error is Exception) {
      final errorString = error.toString().toLowerCase();
      
      if (errorString.contains('network') || errorString.contains('connection')) {
        return 'Network error. Please check your internet connection and try again.';
      }
      
      if (errorString.contains('timeout')) {
        return 'Request timed out. Please try again.';
      }
      
      if (errorString.contains('permission')) {
        return 'Permission denied. Please contact support.';
      }
    }

    // Fallback for unknown errors
    return 'An unexpected error occurred. Please try again or contact support if the problem persists.';
  }

  /// Gets a user-friendly success message for authentication actions
  static String getSuccessMessage(AuthAction action, {String? userRole}) {
    switch (action) {
      case AuthAction.signIn:
        return 'Welcome back! You have been signed in successfully.';
      case AuthAction.register:
        final roleText = userRole != null ? ' as a ${userRole.toLowerCase()}' : '';
        return 'Account created successfully$roleText! Welcome to Emergency Response.';
      case AuthAction.signOut:
        return 'You have been signed out successfully.';
      case AuthAction.passwordReset:
        return 'Password reset email sent. Please check your inbox.';
    }
  }

  /// Checks if an error is network-related
  static bool isNetworkError(dynamic error) {
    if (error is SocketException) return true;
    
    if (error is FirebaseAuthException) {
      return error.code == 'network-request-failed' || 
             error.code == 'timeout';
    }
    
    if (error is FirebaseException) {
      return error.code == 'unavailable' || 
             error.code == 'deadline-exceeded';
    }
    
    if (error is Exception) {
      final errorString = error.toString().toLowerCase();
      return errorString.contains('network') || 
             errorString.contains('connection') ||
             errorString.contains('timeout');
    }
    
    return false;
  }

  /// Checks if an error is retryable
  static bool isRetryableError(dynamic error) {
    if (isNetworkError(error)) return true;
    
    if (error is FirebaseAuthException) {
      return error.code == 'too-many-requests' ||
             error.code == 'internal-error' ||
             error.code == 'timeout';
    }
    
    if (error is FirebaseException) {
      return error.code == 'unavailable' ||
             error.code == 'deadline-exceeded';
    }
    
    return false;
  }
}

/// Enum for different authentication actions
enum AuthAction {
  signIn,
  register,
  signOut,
  passwordReset,
}
