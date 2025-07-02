import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: Text(
          'Help & Support',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emergency Contact Card
            _buildEmergencyContactCard(),

            const SizedBox(height: 24),

            // FAQ Section
            _buildFAQSection(),

            const SizedBox(height: 24),

            // Contact Support Section
            _buildContactSupportSection(context),

            const SizedBox(height: 24),

            // App Information
            _buildAppInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade600, Colors.red.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  HugeIcons.strokeRoundedAlert02,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Contacts',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'For immediate emergencies',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildEmergencyButton(
                  'Police',
                  '911',
                  HugeIcons.strokeRoundedPoliceCar,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEmergencyButton(
                  'Fire',
                  '911',
                  HugeIcons.strokeRoundedAlert01,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEmergencyButton(
                  'Medical',
                  '911',
                  HugeIcons.strokeRoundedHospital01,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton(String label, String number, IconData icon) {
    return GestureDetector(
      onTap: () => _makePhoneCall(number),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              number,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequently Asked Questions',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildFAQItem(
          'How do I report an emergency?',
          'Tap the red emergency button on your dashboard, select the emergency type, provide details, and submit. Your location will be automatically shared with responders.',
        ),
        _buildFAQItem(
          'Can I track the status of my emergency report?',
          'Yes! Go to your dashboard and tap on "Emergency Status" to see real-time updates on your reported emergencies.',
        ),
        _buildFAQItem(
          'How do I chat with responders?',
          'Once you report an emergency, a chat will be automatically created. You can also access it from the "Messages" tab to communicate directly with responders.',
        ),
        _buildFAQItem(
          'What if I accidentally report an emergency?',
          'Contact emergency services immediately at 911 to cancel the false alarm. You can also update the status in the app.',
        ),
        _buildFAQItem(
          'How do I update my profile information?',
          'Go to your profile screen and tap the "Edit" button to update your name, phone number, or profile picture.',
        ),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          question,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              answer,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSupportSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Support',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildContactOption(
          icon: HugeIcons.strokeRoundedMail01,
          title: 'Email Support',
          subtitle: 'support@emergencyresponse.com',
          onTap: () => _sendEmail('support@emergencyresponse.com'),
        ),
        _buildContactOption(
          icon: HugeIcons.strokeRoundedCall,
          title: 'Phone Support',
          subtitle: '+1 (555) 123-4567',
          onTap: () => _makePhoneCall('+15551234567'),
        ),
        _buildContactOption(
          icon: HugeIcons.strokeRoundedMessage01,
          title: 'Live Chat',
          subtitle: 'Available 24/7',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Live chat feature coming soon!')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.deepPurple),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildAppInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'App Information',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildInfoRow('Version', '1.0.0'),
                const Divider(),
                _buildInfoRow('Last Updated', 'December 2024'),
                const Divider(),
                _buildInfoRow('Developer', 'Emergency Response Team'),
                const Divider(),
                _buildInfoRow('Privacy Policy', 'View Policy', isLink: true),
                const Divider(),
                _buildInfoRow('Terms of Service', 'View Terms', isLink: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isLink = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: isLink ? Colors.deepPurple : Colors.grey.shade700,
            decoration: isLink ? TextDecoration.underline : null,
          ),
        ),
      ],
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Emergency Response App Support',
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }
}
