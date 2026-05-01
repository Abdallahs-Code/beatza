import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import '../services/payment_service.dart';
import '../widgets/payment_checkout_sheet.dart';
import 'pro_restrictions_screen.dart';

class PremiumSubscriptionScreen extends StatefulWidget {
  const PremiumSubscriptionScreen({super.key});

  @override
  State<PremiumSubscriptionScreen> createState() =>
      _PremiumSubscriptionScreenState();
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
      'badgeColor': AppColors.proBadgePurple,
      'isPro': true,
      'amount': '0.00',
      'priceId': '',
      'features': [
        'Unlimited track uploads',
        'Get paid directly and more fairly',
        'Discover and connect with your biggest fans',
        'Unlimited distribution to all major streaming and social platforms',
      ],
      'gradient': const [AppColors.premiumPurple, Colors.black],
    },
    {
      'id': 'pro_yearly',
      'name': 'Artist Pro',
      'badge': 'Yearly',
      'badgeColor': AppColors.proBadgeOrange,
      'isPro': true,
      'amount': '0.00',
      'priceId': '',
      'features': [
        'Unlimited track uploads',
        'Get paid directly and more fairly',
        'Discover and connect with your biggest fans',
        'Unlimited distribution to all major streaming and social platforms',
      ],
      'gradient': const [AppColors.premiumDarkPink, Colors.black],
    },
    {
      'id': 'artist_monthly',
      'name': 'Artist',
      'badge': 'Monthly',
      'badgeColor': AppColors.proBadgePurple,
      'isPro': false,
      'amount': '0.00',
      'priceId': '',
      'features': [
        '3 hours of uploads',
        '2 distributed and monetized tracks per month',
        'Discover and connect with your biggest fans',
        '3 replaceable tracks without losing stats per month',
      ],
      'gradient': const [AppColors.premiumDarkPurple, Colors.black],
    },
    {
      'id': 'artist_yearly',
      'name': 'Artist',
      'badge': 'Yearly',
      'badgeColor': AppColors.proBadgeOrange,
      'isPro': false,
      'amount': '0.00',
      'priceId': '',
      'features': [
        '3 hours of uploads',
        '2 distributed and monetized tracks per month',
        'Discover and connect with your biggest fans',
        '3 replaceable tracks without losing stats per month',
      ],
      'gradient': const [AppColors.premiumDarkBlue, Colors.black],
    },
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
          tempPlans.add({
            ...template,
            'priceId': apiData['priceId'],
            'amount': apiData['amount'].toString(),
            'name': apiData['name'] ?? template['name'],
          });
        }
      }

      setState(() {
        _mergedPlans = tempPlans;
        _isLoadingPlans = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPlans = false;
        _mergedPlans = [];
      });
    }
  }

  void _showRestrictionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.chineseBlack,
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
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Restrictions apply',
                style: TextStyle(
                  color: AppColors.whiteSmoke,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Subscription may be managed and cancelled at any time in the App Store Account Settings after purchase. All prices include applicable local sales taxes. Beatza Artist Pro Terms of Use & Privacy Policy',
                style: TextStyle(
                  color: AppColors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Artist Pro',
                style: TextStyle(color: AppColors.whiteSmoke, fontSize: 16),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ArtistTermsScreen()),
                ),
                child: const Text(
                  'Terms of Use',
                  style: TextStyle(color: AppColors.iOSBlue, fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyScreen(),
                  ),
                ),
                child: const Text(
                  'Privacy Policy',
                  style: TextStyle(color: AppColors.iOSBlue, fontSize: 16),
                ),
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
    if (_isLoadingPlans) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.whiteSmoke),
        ),
      );
    }

    if (_mergedPlans.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: AppColors.whiteSmoke),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            'No plans available right now.\nPlease try again later.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.white70, fontSize: 16),
          ),
        ),
      );
    }

    final currentGradient = _mergedPlans.isNotEmpty
        ? _mergedPlans[_currentPage]['gradient']
        : const [Colors.black, Colors.black];

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            pinned: false,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: AppColors.whiteSmoke),
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
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 0,
                    ),
                    child: Text(
                      "What's next in music is\nfirst on Beatza",
                      style: TextStyle(
                        color: AppColors.whiteSmoke,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 460,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) =>
                          setState(() => _currentPage = index),
                      itemCount: _mergedPlans.length,
                      itemBuilder: (context, index) =>
                          _buildPlanCard(_mergedPlans[index]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _mergedPlans.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? AppColors.whiteSmoke
                              : AppColors.whiteSmoke.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.white70,
                      size: 32,
                    ),
                  ),
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
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.badgeBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'FOR ARTISTS',
                  style: TextStyle(
                    color: AppColors.whiteSmoke,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: plan['badgeColor'],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  plan['badge'],
                  style: TextStyle(
                    color: AppColors.whiteSmoke,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                plan['name'],
                style: TextStyle(
                  color: AppColors.whiteSmoke,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (plan['isPro'])
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(
                    Icons.stars,
                    color: AppColors.primaryOrangeAccent,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'EGP ${plan['amount']}/${plan['badge'].toString().toLowerCase().replaceAll('ly', '')}',
            style: TextStyle(
              color: AppColors.whiteSmoke,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
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
                      Icon(Icons.check, color: AppColors.whiteSmoke, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          plan['features'][index],
                          style: TextStyle(
                            color: AppColors.whiteSmoke,
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          ValueListenableBuilder<SubscriptionState>(
            valueListenable: PaymentService.subscriptionSuccessNotifier,
            builder: (context, state, _) {
              final currentPriceId = state.currentPriceId;

              int getUserPlanWeight(String? idStr) {
                if (idStr == null || idStr.isEmpty) return 0;
                final p = _mergedPlans.firstWhere(
                  (element) => element['priceId'] == idStr,
                  orElse: () => <String, dynamic>{},
                );
                if (p.isEmpty) return 0;
                final planIdStr = p['id'].toString().toLowerCase();
                if (planIdStr == 'pro_yearly') return 40;
                if (planIdStr == 'pro_monthly') return 30;
                if (planIdStr == 'artist_yearly') return 20;
                if (planIdStr == 'artist_monthly') return 10;
                return 0;
              }

              final int userWeight = getUserPlanWeight(currentPriceId);
              final planIdString = plan['id'].toString().toLowerCase();
              int cardWeight = 0;
              if (planIdString == 'pro_yearly') {
                cardWeight = 40;
              } else if (planIdString == 'pro_monthly') {
                cardWeight = 30;
              } else if (planIdString == 'artist_yearly') {
                cardWeight = 20;
              } else if (planIdString == 'artist_monthly') {
                cardWeight = 10;
              }

              final bool isCurrentPlan =
                  currentPriceId != null && currentPriceId == plan['priceId'];

              String buttonText;
              bool isDisabled = false;

              if (isCurrentPlan) {
                buttonText = 'Current Plan';
                isDisabled = true;
              } else if (userWeight > 0) {
                if (cardWeight > userWeight) {
                  buttonText = 'Upgrade';
                  isDisabled = false;
                } else {
                  buttonText = 'Already Subscribed';
                  isDisabled = true;
                }
              } else {
                buttonText = 'Subscribe now';
                isDisabled = false;
              }

              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.whiteSmoke,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: const Color(0xFF424242),
                    disabledForegroundColor: AppColors.white54,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: isDisabled
                      ? null
                      : () {
                          if (plan['priceId'] == null ||
                              plan['priceId'].toString().isEmpty) {
                                return;
                              }
                            
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) =>
                                PaymentCheckoutSheet(plan: plan),
                          );
                        },
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Cancel anytime.',
            style: TextStyle(color: AppColors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _showRestrictionsSheet(context),
            child: const Text(
              'Restrictions apply',
              style: TextStyle(color: AppColors.lightBlue, fontSize: 12),
            ),
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
          Text(
            'Beatza supports\nindependent artists',
            style: TextStyle(
              color: AppColors.whiteSmoke,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'From fan-powered royalties to our audience-building artist plans, your subscription helps support the Beatza global community.',
            style: TextStyle(
              color: AppColors.white70,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            '"It\'s such a simple idea. Your monthly fees get split up between the songs"',
            style: TextStyle(
              color: AppColors.whiteSmoke,
              fontSize: 16,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '- RAC, musician and producer',
            style: TextStyle(color: AppColors.white70, fontSize: 15),
          ),
          const SizedBox(height: 40),
          Center(
            child: ClipOval(
              child: Container(
                width: 220,
                height: 220,
                color: AppColors.containerMid,
                child: Image.network(
                  'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&q=80',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.person, size: 80, color: AppColors.white54),
                ),
              ),
            ),
          ),
          const SizedBox(height: 50),
          Text(
            'Frequently asked questions',
            style: TextStyle(
              color: AppColors.whiteSmoke,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildFaqTile(
            'What\'s the difference between fan and artist plans?',
            'Our Fan-oriented plans are designed for those who primarily visit the site to listen to Beatza\'s 250+ million tracks. Artist plans offer unique features designed to help artists create and distribute their music and content.',
          ),
          _buildFaqTile(
            'Can I purchase an annual plan and/or family plan?',
            'Unfortunately we do not currently offer an annual or family plan option for purchase in the app.',
          ),
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
        iconColor: AppColors.whiteSmoke,
        collapsedIconColor: AppColors.whiteSmoke,
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.whiteSmoke,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              content,
              style: TextStyle(
                color: AppColors.white70,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
