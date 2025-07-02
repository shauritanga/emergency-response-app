import 'package:flutter/material.dart';

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final List<String> features;

  const OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.features,
  });
}

class OnboardingData {
  static List<OnboardingPage> get pages => [
    // Page 1: Emergency Reporting
    const OnboardingPage(
      title: 'Report Emergencies Instantly',
      description: 'Quickly report medical, fire, or police emergencies with just a few taps. Your location is automatically shared with responders.',
      icon: Icons.emergency,
      primaryColor: Colors.red,
      secondaryColor: Colors.redAccent,
      features: [
        'One-tap emergency reporting',
        'Automatic location sharing',
        'Photo evidence upload',
        'Real-time status updates',
      ],
    ),

    // Page 2: Real-time Communication
    const OnboardingPage(
      title: 'Stay Connected with Responders',
      description: 'Chat directly with emergency responders, share your location, and receive real-time updates about your emergency.',
      icon: Icons.chat_bubble,
      primaryColor: Colors.blue,
      secondaryColor: Colors.blueAccent,
      features: [
        'Direct chat with responders',
        'Share photos and location',
        'Receive emergency alerts',
        'Track response progress',
      ],
    ),

    // Page 3: Safety & Support
    const OnboardingPage(
      title: 'Your Safety is Our Priority',
      description: 'Get help when you need it most. Our network of verified responders is ready to assist you 24/7.',
      icon: Icons.security,
      primaryColor: Colors.green,
      secondaryColor: Colors.greenAccent,
      features: [
        '24/7 emergency response',
        'Verified responder network',
        'Secure communication',
        'Privacy protection',
      ],
    ),
  ];
}
