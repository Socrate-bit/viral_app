import 'package:flutter/material.dart';
import '../widgets/legal_document_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54, size: 32),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Section
          _buildSectionHeader('Account'),
          _buildSettingsTile(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            onTap: () => _showLogoutDialog(),
          ),
          _buildSettingsTile(
            icon: Icons.delete_outline,
            title: 'Delete Account',
            subtitle: 'Permanently delete your account',
            textColor: Colors.red,
            onTap: () => _showDeleteAccountDialog(),
          ),

          const SizedBox(height: 24),

          // Support Section
          _buildSectionHeader('Support'),
          _buildSettingsTile(
            icon: Icons.email_outlined,
            title: 'Contact Support',
            subtitle: 'support@viralcraft.com',
            onTap: () => _contactSupport(),
          ),
          _buildSettingsTile(
            icon: Icons.bug_report_outlined,
            title: 'Report a Bug',
            subtitle: 'Help us improve the app',
            onTap: () => _reportBug(),
          ),

          const SizedBox(height: 24),

          // Legal Section
          _buildSectionHeader('Legal'),
          _buildSettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms and Conditions',
            subtitle: 'Read our terms of service',
            onTap: () => _showTermsAndConditions(),
          ),
          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'Learn how we protect your data',
            onTap: () => _showPrivacyPolicy(),
          ),

          const SizedBox(height: 24),

          // App Info Section
          _buildSectionHeader('App Info'),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: '1.0.0',
            showArrow: false,
            onTap: null,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? textColor,
    bool showArrow = true,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: textColor ?? Colors.black54, size: 24),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor ?? Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        trailing: showArrow
            ? Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              )
            : null,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out successfully')),
                );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Delete Account',
            style: TextStyle(color: Colors.red),
          ),
          content: const Text(
            'This action cannot be undone. All your data will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account deletion requested'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening email app...'),
        duration: Duration(seconds: 2),
      ),
    );
    // TODO: Implement email functionality
    // Example: launch('mailto:support@viralcraft.com');
  }

  void _reportBug() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening bug report form...'),
        duration: Duration(seconds: 2),
      ),
    );
    // TODO: Implement bug report functionality
  }

  void _showTermsAndConditions() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LegalDocumentPage(
          title: 'Terms and Conditions',
          content: '''
Terms and Conditions

Last updated: [Date]

1. Acceptance of Terms
By using ViralCraft, you agree to these terms and conditions.

2. Use of Service
You may use our service to edit and enhance your photos using AI technology.

3. User Content
You retain ownership of your photos. We may use them to improve our AI models.

4. Prohibited Uses
- Don't use the service for illegal activities
- Don't upload inappropriate content
- Don't attempt to reverse engineer our technology

5. Privacy
Your privacy is important to us. See our Privacy Policy for details.

6. Limitation of Liability
We provide the service "as is" without warranties.

7. Changes to Terms
We may update these terms from time to time.

8. Contact
For questions, contact us at support@viralcraft.com
          ''',
        ),
      ),
    );
  }

  void _showPrivacyPolicy() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LegalDocumentPage(
          title: 'Privacy Policy',
          content: '''
Privacy Policy

Last updated: [Date]

1. Information We Collect
- Photos you upload for editing
- Account information (email, name)
- Usage data and analytics

2. How We Use Your Information
- To provide photo editing services
- To improve our AI models
- To communicate with you about the service

3. Information Sharing
We don't sell your personal information. We may share data with:
- Service providers who help us operate the app
- Law enforcement when required by law

4. Data Security
We use industry-standard security measures to protect your data.

5. Your Rights
You can:
- Access your personal data
- Delete your account and data
- Opt out of marketing communications

6. Data Retention
We keep your data as long as your account is active or as needed to provide services.

7. Children's Privacy
Our service is not intended for children under 13.

8. Changes to Policy
We may update this policy and will notify you of significant changes.

9. Contact Us
For privacy questions, email us at privacy@viralcraft.com
          ''',
        ),
      ),
    );
  }
}
