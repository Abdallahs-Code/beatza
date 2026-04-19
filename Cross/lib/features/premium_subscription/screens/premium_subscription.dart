import 'package:flutter/material.dart';
import '../services/payment_service.dart';
import '../widgets/PaymentCheckoutSheet.dart';
import 'pro_restrictions_screen.dart';

class PremiumSubscriptionScreen extends StatefulWidget {
  const PremiumSubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<PremiumSubscriptionScreen> createState() => _PremiumSubscriptionScreenState();
}

class _PremiumSubscriptionScreenState extends State<PremiumSubscriptionScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _currentPage = 0;
  bool _isLoadingPlans = true;
  List<Map<String, dynamic>> _mergedPlans = [];

  final List<Map<String, dynamic>> _uiPlanTemplates = [
    {
      'id': 'pro_monthly',
      'name': 'Artist Pro',
      'badge': 'Monthly',
      'badgeColor': const Color(0xFF8E24AA),
      'isPro': true,
      'amount': '164.99',
      'priceId': 'dummy_pro_monthly',
      'features': [
        'Unlimited track uploads',
        'Get paid directly and more fairly',
        'Discover and connect with your biggest fans',
        'Unlimited distribution to all major streaming and social platforms'
      ],
      'gradient': const [Color(0xFF6B1B9A), Colors.black],
    },
    {
      'id': 'pro_yearly',
      'name': 'Artist Pro',
      'badge': 'Yearly',
      'badgeColor': const Color(0xFFE65100),
      'isPro': true,
      'amount': '1,149.99',
      'priceId': 'dummy_pro_yearly',
      'features': [
        'Unlimited track uploads',
        'Get paid directly and more fairly',
        'Discover and connect with your biggest fans',
        'Unlimited distribution to all major streaming and social platforms'
      ],
      'gradient': const [Color(0xFF880E4F), Colors.black],
    },
    {
      'id': 'artist_monthly',
      'name': 'Artist',
      'badge': 'Monthly',
      'badgeColor': const Color(0xFF8E24AA),
      'isPro': false,
      'amount': '65.00',
      'priceId': 'dummy_artist_monthly',
      'features': [
        '3 hours of uploads',
        '2 distributed and monetized tracks per month',
        'Discover and connect with your biggest fans',
        '3 replaceable tracks without losing stats per month'
      ],
      'gradient': const [Color(0xFF4A148C), Colors.black],
    },
    {
      'id': 'artist_yearly',
      'name': 'Artist',
      'badge': 'Yearly',
      'badgeColor': const Color(0xFFE65100),
      'isPro': false,
      'amount': '479.99',
      'priceId': 'dummy_artist_yearly',
      'features': [
        '3 hours of uploads',
        '2 distributed and monetized tracks per month',
        'Discover and connect with your biggest fans',
        '3 replaceable tracks without losing stats per month'
      ],
      'gradient': const [Color(0xFF311B92), Colors.black],
    }
  ];

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    try {
      final apiPlans = await PaymentService.getPlans();
      List<Map<String, dynamic>> tempPlans = [];
      for (var template in _uiPlanTemplates) {
        if (apiPlans.containsKey(template['id'])) {
          final apiData = apiPlans[template['id']];
          template['priceId'] = apiData['priceId'];
          template['amount'] = apiData['amount'].toString();
        }
        tempPlans.add(template);
      }
      setState(() {
        _mergedPlans = tempPlans;
        _isLoadingPlans = false;
      });
    } catch (e) {
      setState(() => _isLoadingPlans = false);
      setState(() => _mergedPlans = _uiPlanTemplates);
    }
  }

  void _showRestrictionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Restrictions apply', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text(
                'Subscription may be managed and cancelled at any time in the App Store Account Settings after purchase. All prices include applicable local sales taxes. SoundCloud Artist Pro Terms of Use & Privacy Policy',
                style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              const Text('Artist Pro', style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ArtistTermsScreen())),
                child: const Text('Terms of Use', style: TextStyle(color: Color(0xFF0A84FF), fontSize: 16)),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                child: const Text('Privacy Policy', style: TextStyle(color: Color(0xFF0A84FF), fontSize: 16)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentGradient = _mergedPlans.isNotEmpty
        ? _mergedPlans[_currentPage]['gradient']
        : const [Colors.black, Colors.black];

    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoadingPlans
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            pinned: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: currentGradient,
                  stops: const [0.0, 0.9],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 0),
                    child: Text(
                      "What's next in music is\nfirst on SoundCloud",
                      style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, height: 1.2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 460,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) => setState(() => _currentPage = index),
                      itemCount: _mergedPlans.length,
                      itemBuilder: (context, index) => _buildPlanCard(_mergedPlans[index]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _mergedPlans.length,
                          (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index ? Colors.white : Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Center(child: Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 32)),
                  const SizedBox(height: 30),
                  _buildPromoAndFaqSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF1976D2), borderRadius: BorderRadius.circular(4)),
                child: const Text('FOR ARTISTS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(color: plan['badgeColor'], borderRadius: BorderRadius.circular(4)),
                child: Text(plan['badge'], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(plan['name'], style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              if (plan['isPro'])
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.stars, color: Color(0xFFFF3D00), size: 20),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text('EGP ${plan['amount']}/${plan['badge'].toString().toLowerCase().replaceAll('ly', '')}',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: plan['features'].length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check, color: Colors.white, size: 18),
                      const SizedBox(width: 12),
                      Expanded(child: Text(plan['features'][index], style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3))),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => PaymentCheckoutSheet(plan: plan),
                );
              },
              child: const Text('Subscribe now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Cancel anytime.', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _showRestrictionsSheet(context),
            child: const Text('Restrictions apply', style: TextStyle(color: Color(0xFF64B5F6), fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoAndFaqSection() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SoundCloud supports\nindependent artists', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.2)),
          const SizedBox(height: 16),
          const Text('From fan-powered royalties to our audience-building artist plans, your subscription helps support the SoundCloud global community.', style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5)),
          const SizedBox(height: 30),
          const Text('"It\'s such a simple idea. Your monthly fees get split up between the songs"', style: TextStyle(color: Colors.white, fontSize: 16, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          const Text('- RAC, musician and producer', style: TextStyle(color: Colors.white70, fontSize: 15)),
          const SizedBox(height: 40),
          Center(
            child: ClipOval(
              child: Container(
                width: 220, height: 220, color: const Color(0xFF2A2A2A),
                child: Image.network('https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&q=80', fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 80, color: Colors.white54)),
              ),
            ),
          ),
          const SizedBox(height: 50),
          const Text('Frequently asked questions', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildFaqTile('What\'s the difference between fan and artist plans?', 'Our Fan-oriented plans are designed for those who primarily visit the site to listen to SoundCloud\'s 250+ million tracks. Artist plans offer unique features designed to help artists create and distribute their music and content.'),
          _buildFaqTile('Can I purchase an annual plan and/or family plan?', 'Unfortunately we do not currently offer an annual or family plan option for purchase in the app.'),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildFaqTile(String title, String content) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(content, style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.4)),
          ),
        ],
      ),
    );
  }
}