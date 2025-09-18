import 'package:flutter/material.dart';
import '../editor/editing_page.dart';
import '../widgets/legal_document_page.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  int _selectedPlanIndex = 1; // Default to yearly plan

  final List<SubscriptionPlan> _plans = [
    SubscriptionPlan(
      title: 'Monthly',
      price: '\$39.99',
      period: '/month',
      description: 'Perfect for trying out',
      features: ['20 gems per day', 'All AI features', 'HD exports'],
      isPopular: false,
    ),
    SubscriptionPlan(
      title: 'Yearly',
      price: '\$239.99',
      period: '/year',
      description: 'Save 50% - Most Popular',
      features: [
        '20 gems per day',
        'All AI features',
        'HD exports',
        'Priority support',
      ],
      isPopular: true,
    ),
    SubscriptionPlan(
      title: 'Buy 20 gems',
      price: '\$9.99',
      period: 'one-time',
      description: 'No subscription',
      features: ['20 gems (no expiry)', 'All AI features', 'HD exports'],
      isPopular: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Close button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.grey, size: 28),
                  ),
                  TextButton(
                    onPressed: () => _startFreeTrial(),
                    child: const Text(
                      'Free Trial',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // App icon/logo placeholder
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.auto_fix_high,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title
                    const Text(
                      'Unlock Premium Features',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      'Create unlimited viral content with AI-powered editing',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Features list
                    _buildFeaturesList(),

                    const SizedBox(height: 32),

                    // Subscription plans
                    _buildSubscriptionPlans(),

                    const SizedBox(height: 32),

                    // Subscribe button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _subscribe(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Start ${_plans[_selectedPlanIndex].title} Plan',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Terms and restore
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => _showTerms(),
                          child: Text(
                            'Terms',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showPrivacy(),
                          child: Text(
                            'Privacy',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _restorePurchases(),
                          child: Text(
                            'Restore',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      '20 gems per day for AI edits',
      'All premium filters & effects',
      'HD quality exports',
      'No watermarks',
      'Priority customer support',
    ];

    return Column(
      children: features
          .map(
            (feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    feature,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSubscriptionPlans() {
    return Column(
      children: [
        for (int i = 0; i < _plans.length; i++)
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedPlanIndex = i;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedPlanIndex == i
                    ? Colors.black.withOpacity(0.05)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedPlanIndex == i
                      ? Colors.black
                      : Colors.grey.shade300,
                  width: _selectedPlanIndex == i ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Radio button
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedPlanIndex == i
                            ? Colors.black
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                      color: _selectedPlanIndex == i
                          ? Colors.black
                          : Colors.transparent,
                    ),
                    child: _selectedPlanIndex == i
                        ? const Icon(Icons.check, color: Colors.white, size: 12)
                        : null,
                  ),

                  const SizedBox(width: 16),

                  // Plan details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _plans[i].title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            if (_plans[i].isPopular) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'POPULAR',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _plans[i].description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _plans[i].price,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        _plans[i].period,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _subscribe() {
    // TODO: Implement subscription logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Starting ${_plans[_selectedPlanIndex].title} subscription...',
        ),
        backgroundColor: Colors.green,
      ),
    );

    // Navigate to main app after subscription
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const EditingPage()),
      );
    });
  }

  void _startFreeTrial() {
    // TODO: Implement free trial logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Starting free trial...'),
        backgroundColor: Colors.blue,
      ),
    );

    // Navigate to main app after free trial
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const EditingPage()),
      );
    });
  }

  void _showTerms() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LegalDocumentPage(
          title: 'Terms and Conditions',
          content: '''
Terms and Conditions

Last updated: [Date]

1. Acceptance of Terms
By using ViralCraft, you agree to these terms and conditions.

2. Subscription Terms
- Gem Pack: \$9.99 one-time (20 gems)
- Monthly subscription: \$39.99/month
- Yearly subscription: \$239.99/year
- Free trial: 7 days (if applicable)
- Auto-renewal unless cancelled (subscriptions only)

3. Use of Service
You may use our service to edit and enhance your photos using AI technology.

4. User Content
You retain ownership of your photos. We may use them to improve our AI models.

5. Prohibited Uses
- Don't use the service for illegal activities
- Don't upload inappropriate content
- Don't attempt to reverse engineer our technology

6. Cancellation
You can cancel your subscription at any time through your device settings.

7. Refunds
Refunds are handled according to App Store/Google Play policies.

8. Contact
For questions, contact us at support@viralcraft.com
          ''',
        ),
      ),
    );
  }

  void _showPrivacy() {
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
- Payment information (processed securely)

2. How We Use Your Information
- To provide photo editing services
- To process payments and subscriptions
- To improve our AI models
- To communicate with you about the service

3. Information Sharing
We don't sell your personal information. We may share data with:
- Payment processors (Stripe, Apple, Google)
- Service providers who help us operate the app
- Law enforcement when required by law

4. Data Security
We use industry-standard security measures to protect your data.

5. Your Rights
You can:
- Access your personal data
- Delete your account and data
- Opt out of marketing communications
- Cancel your subscription

6. Contact Us
For privacy questions, email us at privacy@viralcraft.com
          ''',
        ),
      ),
    );
  }

  void _restorePurchases() {
    // TODO: Implement restore purchases
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Restoring purchases...')));
  }
}

class SubscriptionPlan {
  final String title;
  final String price;
  final String period;
  final String description;
  final List<String> features;
  final bool isPopular;

  SubscriptionPlan({
    required this.title,
    required this.price,
    required this.period,
    required this.description,
    required this.features,
    required this.isPopular,
  });
}
