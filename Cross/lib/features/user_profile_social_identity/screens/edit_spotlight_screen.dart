
import 'dart:io';

import 'package:cross_team5/features/user_profile_social_identity/screens/your_uploads_spotlight_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../premium_subscription/services/payment_service.dart';
import '../models/spotlight_models.dart';

class EditSpotlightScreen extends StatefulWidget {
  final List<SpotlightItemModel> initialItems;
  final String artistName;

  const EditSpotlightScreen({
    super.key,
    required this.initialItems,
    required this.artistName,
  });

  @override
  State<EditSpotlightScreen> createState() => _EditSpotlightScreenState();
}

class _EditSpotlightScreenState extends State<EditSpotlightScreen> {
  late List<SpotlightItemModel> currentItems;

  @override
  void initState() {
    super.initState();
    currentItems = List.from(widget.initialItems);
  }

  void _addMoreItems() async {
    final selectedItems = await Navigator.push<List<SpotlightItemModel>>(
      context,
      MaterialPageRoute(
        builder: (context) => YourUploadsSpotlightScreen(
          selectedItems: currentItems,
          artistName: widget.artistName,
        ),
      ),
    );

    if (selectedItems != null) {
      setState(() {
        currentItems = selectedItems;
      });
    }
  }

  void _showAmplifyProModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 16.0,
            bottom: MediaQuery.of(context).padding.bottom + 24.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Icon(Icons.flash_on, color: Color(0xFFD47AFA), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'AMPLIFY',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Reach more\nlisteners.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'With Artist Pro, you can get your tracks analyzed and recommended to the right listeners without limits.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                  children: [
                    const TextSpan(text: 'EGP 164.99/month. Cancel anytime.\n'),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const ProRestrictionsScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Restrictions apply.',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text(
                    'Subscribe now',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Maybe later',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        leadingWidth: 80,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        title: const Text(
          'Edit Spotlight',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, currentItems);
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tracks added here will not be saved.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Upgrade and pin up to 5 tracks on your profile.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<SubscriptionState>(
                  valueListenable: PaymentService.subscriptionSuccessNotifier,
                  builder: (context, state, child) {
                    if (state.isPro) return const SizedBox.shrink();
                    return GestureDetector(
                      onTap: _showAmplifyProModal,
                      child: const Text(
                        'GET ARTIST PRO',
                        style: TextStyle(
                          color: Color(0xFFFF5500),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    );
                  },
                ),              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pinned items',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentItems.isEmpty
                      ? 'Pinned items will show up here'
                      : '${currentItems.length}/5 pinned items',
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          ),

          Expanded(
            child: currentItems.isEmpty
                ? const SizedBox.shrink()
                : ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              itemCount: currentItems.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = currentItems.removeAt(oldIndex);
                  currentItems.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final item = currentItems[index];
                return Container(
                  key: ValueKey(item.id),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child:
                      item.imageUrl != null &&
                          item.imageUrl!.isNotEmpty
                          ? (item.imageUrl!.startsWith('http')
                          ? Image.network(
                        item.imageUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      )
                          : Image.file(
                        File(item.imageUrl!),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ))
                          : Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      item.subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed: () {
                            setState(() {
                              currentItems.removeAt(index);
                            });
                          },
                        ),
                        const Icon(
                          Icons.drag_handle,
                          color: Colors.white38,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _addMoreItems,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Add more items',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProRestrictionsScreen extends StatelessWidget {
  const ProRestrictionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Restrictions apply',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Subscription may be managed and cancelled at any time in the App Store Account Settings after purchase. All prices include applicable local sales taxes. SoundCloud Artist Pro Terms of Use & Privacy Policy',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Artist Pro',
              style: TextStyle(
                color: Colors.white,
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
        style: const TextStyle(
          color: Colors.white24,
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
                color: Color(0xFF1B64D1),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionBody(
              'These SoundCloud Artist Subscriptions Terms of Use (the “SoundCloud Artist Terms”) and if applicable the SoundCloud Monetization Terms of Service, are in addition to and are governed by SoundCloud’s Terms of Use (the “Terms of Use”) together with our Community Guidelines, Privacy Policy and Cookie Policy and any other terms specifically referred to in any of those documents (collectively “the Documents”). In the event of a conflict between the SoundCloud Artist Terms and any other Documents, the SoundCloud Artist Terms shall prevail solely in respect to your use of SoundCloud Artist Subscriptions.',
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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