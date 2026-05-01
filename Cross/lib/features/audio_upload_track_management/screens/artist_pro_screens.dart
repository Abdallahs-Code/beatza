import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';

class ProRestrictionsScreen extends StatelessWidget {
  const ProRestrictionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark3,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark3,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.whiteSmoke),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restrictions apply',
              style: TextStyle(
                color: AppColors.whiteSmoke,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Subscription may be managed and cancelled at any time in the App Store Account Settings after purchase. All prices include applicable local sales taxes. Beatza Artist Pro Terms of Use & Privacy Policy',
              style: TextStyle(
                color: AppColors.white70,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Artist Pro',
              style: TextStyle(
                color: AppColors.whiteSmoke,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            _buildLink(context, 'Terms of Use', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ArtistTermsScreen(),
                ),
              );
            }),
            const SizedBox(height: 24),

            _buildLink(context, 'Privacy Policy', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLink(BuildContext context, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.white24,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

class ArtistTermsScreen extends StatelessWidget {
  const ArtistTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteSmoke,
      appBar: AppBar(
        backgroundColor: AppColors.whiteSmoke,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          'Terms of Use',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms of Use for Artist Subscriptions',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionBody(
              'These Beatza Artist Subscriptions Terms of Use (the “Beatza Artist Terms”) and if applicable the Beatza Monetization Terms of Service, are in addition to and are governed by Beatza’s Terms of Use (the “Terms of Use”) together with our Community Guidelines, Privacy Policy and Cookie Policy and any other terms specifically referred to in any of those documents (collectively “the Documents”). In the event of a conflict between the Beatza Artist Terms and any other Documents, the Beatza Artist Terms shall prevail solely in respect to your use of Beatza Artist Subscriptions.',
            ),

            _buildSectionTitle('Artist Subscriptions'),
            _buildSectionBody(
              'Certain features of the Platform are only available to registered users who subscribe to an “Artist Pro,” “Artist,” or “Basic” plan or the legacy plans “Next,” “Next Pro,” or “Next Plus” (each an “Artist Subscription”). Below, you’ll find a few additional terms that apply to those Artist Subscriptions, including amongst other things, terms relating to payment, the conclusion and renewal of your Artist Subscription, your right of withdrawal during the first fourteen (14) days of your subscription, and certain technical usage limitations.',
            ),

            _buildSectionTitle('Conclusion of the contract'),
            _buildSectionBody(
              'Once your payment has been received, your Artist Subscription will be activated, and we will send confirmation of your activated subscription by email to the address associated with your account. The contract for your Artist Subscription is concluded when you receive our confirmation email.',
            ),

            _buildSectionTitle('Automatic Renewal'),
            _buildSectionBody(
              'AUTOMATIC RENEWAL: AS STATED ABOVE, IF YOU DO NOT CANCEL YOUR SUBSCRIPTION PRIOR TO THE COMMENCEMENT OF AN APPLICABLE BILLING MONTH OR BILLING YEAR, WE WILL AUTOMATICALLY CHARGE YOUR PAYMENT ACCOUNT AT THE BEGINNING OF EACH SUCCESSIVE BILLING MONTH OR BILLING YEAR, AS APPLICABLE.',
            ),

            _buildSectionTitle('Technical usage limitations'),
            _buildSectionBody(
              'Please note that Artist Subscriptions are subject to monthly upload limits and a maximum individual file size. Individual uploads must not exceed four (4) GB and the upload time per month must not exceed twenty (20) hours in total.',
            ),

            const SizedBox(height: 40),
            const Divider(),
            const Text(
              'Last Amended: January 19, 2026',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionBody(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.black87, fontSize: 15, height: 1.6),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteSmoke,
      appBar: AppBar(
        backgroundColor: AppColors.whiteSmoke,
        elevation: 1,
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: TextStyle(
                color: Colors.black,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Your privacy is important to us. This Privacy Policy explains how we collect, use, and protect your personal information when you use our Artist Subscriptions. We ensure that all data processing is compliant with global privacy standards.',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
