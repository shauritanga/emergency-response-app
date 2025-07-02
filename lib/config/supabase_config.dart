// File: lib/config/supabase_config.dart
class SupabaseConfig {
  // Replace these with your actual Supabase project credentials
  static const String supabaseUrl = 'https://xtnagjrbhcquptoztzlu.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh0bmFnanJiaGNxdXB0b3p0emx1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA1ODQ5NDcsImV4cCI6MjA2NjE2MDk0N30.ntaKvTm1AgltXNJwfUp_BA9ecL9lSHCzPbwQsG58jPY';

  // Storage bucket names
  static const String imagesBucket = 'images';
  static const String videosBucket = 'videos';
  static const String documentsBucket = 'documents';

  // File size limits (in bytes)
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  static const int maxVideoSize =
      50 * 1024 * 1024; // 50MB (reduced for better compatibility)

  // Allowed file extensions
  static const List<String> allowedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];

  static const List<String> allowedVideoExtensions = [
    'mp4',
    'mov',
    'avi',
    'mkv',
    'webm',
  ];
}
