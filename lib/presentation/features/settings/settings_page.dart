import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../usage/token_cubit.dart';
import '../usage/token_state.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/dimensions.dart';
import '../../core/theme/app_font.dart';
import '../authentication/auth_cubit.dart';
import '../authentication/onboarding_page.dart';
import 'legal_document_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.primaryText,
            size: AppDimensions.iconSizeLarge,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: AppFont.textTheme.titleMedium?.copyWith(
            color: AppColors.primaryText,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        children: [
          // Subscription Section
          _buildSectionHeader('Subscription & Tokens'),
          _buildTokenInfoCard(),
          const SizedBox(height: AppDimensions.marginMedium),

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

          const SizedBox(height: AppDimensions.marginLarge),

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

          const SizedBox(height: AppDimensions.marginLarge),

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

          const SizedBox(height: AppDimensions.marginLarge),

          // App Info Section
          _buildSectionHeader('App Info'),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: '1.0.0',
            showArrow: false,
            onTap: null,
          ),

          const SizedBox(
            height: AppDimensions.marginXLarge + AppDimensions.marginSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppDimensions.paddingSmall + AppDimensions.paddingXSmall,
        top: AppDimensions.paddingSmall,
      ),
      child: Text(
        title,
        style: AppFont.textTheme.titleSmall?.copyWith(
          color: AppColors.secondaryText,
          fontWeight: AppFont.weightSemiBold,
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
      margin: const EdgeInsets.only(bottom: AppDimensions.marginSmall),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius + 4),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: textColor ?? AppColors.activeIcon,
          size: AppDimensions.iconSizeMedium,
        ),
        title: Text(
          title,
          style: AppFont.textTheme.bodyLarge?.copyWith(
            fontWeight: AppFont.weightMedium,
            color: textColor ?? AppColors.primaryText,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppFont.textTheme.bodyMedium?.copyWith(
            color: AppColors.secondaryText,
          ),
        ),
        trailing: showArrow
            ? Icon(
                Icons.arrow_forward_ios_rounded,
                size: AppDimensions.iconSizeSmall,
                color: AppColors.inactiveIcon,
              )
            : null,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: AppDimensions.paddingSmall,
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius + 4),
          ),
          title: Text(
            'Logout',
            style: AppFont.textTheme.titleMedium?.copyWith(
              color: AppColors.primaryText,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: AppFont.textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.secondaryText,
              ),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog first
                await _performLogout();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.gradientRed,
              ),
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
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius + 4),
          ),
          title: Text(
            'Delete Account',
            style: AppFont.textTheme.titleMedium?.copyWith(
              color: AppColors.gradientRed,
            ),
          ),
          content: Text(
            'This action cannot be undone. All your data will be permanently deleted.',
            style: AppFont.textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.secondaryText,
              ),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog first
                await _performDeleteAccount();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.gradientRed,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Opening email app...'),
        backgroundColor: AppColors.cardBackground,
        duration: const Duration(seconds: 2),
      ),
    );
    // TODO: Implement email functionality
    // Example: launch('mailto:support@viralcraft.com');
  }

  void _reportBug() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Opening bug report form...'),
        backgroundColor: AppColors.cardBackground,
        duration: const Duration(seconds: 2),
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

  Widget _buildTokenInfoCard() {
    return BlocBuilder<TokenCubit, TokenState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: () {
            if (state is TokenLoaded) {
              context.read<TokenCubit>().showConditionalPaywall();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(
                AppDimensions.borderRadius + 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getSubscriptionIcon(state),
                        color: _getSubscriptionColor(state),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getSubscriptionTitle(state),
                        style: AppFont.textTheme.titleMedium?.copyWith(
                          fontWeight: AppFont.weightSemiBold,
                          color: _getSubscriptionColor(state),
                        ),
                      ),
                      const Spacer(),
                      if (state is TokenLoaded &&
                          state.subscriptionStatus == 'active')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.paddingSmall,
                            vertical: AppDimensions.paddingXSmall,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.gradientOrange.withOpacity(0.2),
                                AppColors.gradientRed.withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.paddingSmall,
                            ),
                            border: Border.all(
                              color: AppColors.gradientOrange.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                color: AppColors.gradientOrange,
                                size: AppDimensions.iconSizeSmall,
                              ),
                              const SizedBox(
                                width: AppDimensions.paddingXSmall,
                              ),
                              Text(
                                'PREMIUM',
                                style: AppFont.textTheme.bodySmall?.copyWith(
                                  color: AppColors.gradientOrange,
                                  fontWeight: AppFont.weightSemiBold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(
                    height:
                        AppDimensions.paddingSmall +
                        AppDimensions.paddingXSmall,
                  ),
                  if (state is TokenLoaded) ...[
                    _buildTokenRow('Token Balance', '${state.balance} tokens'),
                    const SizedBox(height: AppDimensions.paddingSmall),
                    _buildTokenRow(
                      'Subscription Status',
                      context.read<TokenCubit>().getSubscriptionStatusText(),
                    ),
                    if (state.subscriptionProductId != null) ...[
                      const SizedBox(height: AppDimensions.paddingSmall),
                      _buildTokenRow(
                        'Product ID',
                        state.subscriptionProductId!,
                      ),
                    ],
                    const SizedBox(height: AppDimensions.paddingMedium),
                    // Show only one button based on subscription status
                    if (state.subscriptionStatus != 'active') ...[
                      // Show Subscribe button when no active subscription
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.gradientOrange,
                                AppColors.gradientRed,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.borderRadius,
                            ),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => context
                                .read<TokenCubit>()
                                .showSubscriptionPaywall(),
                            icon: Icon(
                              Icons.star_rounded,
                              size: AppDimensions.iconSizeSmall + 2,
                            ),
                            label: const Text('Subscribe'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: AppColors.pureWhite,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.borderRadius,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Show Buy Tokens button when has active subscription (highlighted)
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.gradientOrange,
                                AppColors.gradientRed,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.borderRadius,
                            ),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                context.read<TokenCubit>().showTokenPaywall(),
                            icon: Icon(
                              Icons.add_shopping_cart_rounded,
                              size: AppDimensions.iconSizeSmall + 2,
                            ),
                            label: const Text('Buy Tokens'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: AppColors.pureWhite,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.borderRadius,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ] else if (state is TokenError) ...[
                    Text(
                      'Error loading token info: ${state.message}',
                      style: AppFont.textTheme.bodyMedium?.copyWith(
                        color: AppColors.gradientRed,
                      ),
                    ),
                  ] else if (state is TokenUnauthenticated) ...[
                    Text(
                      'Please sign in to view your subscription and token information.',
                      style: AppFont.textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ] else ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(
                          AppDimensions.paddingMedium,
                        ),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.gradientOrange,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTokenRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppFont.textTheme.bodyMedium?.copyWith(
            color: AppColors.secondaryText,
          ),
        ),
        Text(
          value,
          style: AppFont.textTheme.bodyMedium?.copyWith(
            fontWeight: AppFont.weightMedium,
            color: AppColors.primaryText,
          ),
        ),
      ],
    );
  }

  IconData _getSubscriptionIcon(TokenState state) {
    if (state is TokenLoaded) {
      if (state.subscriptionStatus == 'active') return Icons.auto_awesome;
      if (state.balance <= 0) return Icons.warning_amber_rounded;
    }
    return Icons.account_balance_wallet;
  }

  Color _getSubscriptionColor(TokenState state) {
    if (state is TokenLoaded) {
      if (state.subscriptionStatus == 'active') return AppColors.gradientOrange;
      if (state.balance <= 5) return AppColors.gradientOrange;
      if (state.balance <= 0) return AppColors.gradientRed;
    }
    return AppColors.primaryText;
  }

  String _getSubscriptionTitle(TokenState state) {
    if (state is TokenLoaded) {
      if (state.subscriptionStatus == 'active') return 'Premium Subscription';
      if (state.balance <= 0) return 'No Tokens Available';
    }
    return 'Subscription & Tokens';
  }

  Future<void> _performLogout() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.gradientOrange),
                ),
                const SizedBox(height: 16),
                Text(
                  'Signing out...',
                  style: AppFont.textTheme.bodyMedium?.copyWith(
                    color: AppColors.primaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Perform logout
      await context.read<AuthCubit>().signOut();

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Navigate back and let AuthWrapper handle the redirect
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const OnboardingPage()),
          (route) => false,
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to logout: ${e.toString()}'),
            backgroundColor: AppColors.gradientRed,
          ),
        );
      }
    }
  }

  Future<void> _performDeleteAccount() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.gradientRed),
                ),
                const SizedBox(height: 16),
                Text(
                  'Deleting account...',
                  style: AppFont.textTheme.bodyMedium?.copyWith(
                    color: AppColors.primaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Perform account deletion
      await context.read<AuthCubit>().deleteAccount();

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Navigate back and let AuthWrapper handle the redirect
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const OnboardingPage()),
          (route) => false,
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: ${e.toString()}'),
            backgroundColor: AppColors.gradientRed,
          ),
        );
      }
    }
  }
}
