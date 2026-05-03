import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import '../../premium_subscription/screens/premium_subscription.dart';
import '../../premium_subscription/services/payment_service.dart';
import '../services/audio_upload_service.dart';
import '../models/track_model.dart';
import 'package:provider/provider.dart';
import 'package:cross_team5/core/services/theme_service.dart';
import 'upload_track_screen.dart';

enum InsightTab { beatza, allPlatforms, fans }

class YourInsightsScreen extends StatefulWidget {
  const YourInsightsScreen({super.key});

  @override
  State<YourInsightsScreen> createState() => _YourInsightsScreenState();
}

class _YourInsightsScreenState extends State<YourInsightsScreen> {
  InsightTab _activeTab = InsightTab.beatza;
  String _selectedFilter = 'Last 30 days';
  String _selectedStat = 'plays';
  final List<String> _filterOptions = [
    'Today',
    'Last 7 days',
    'Last 30 days',
    'Last 12 months',
    'All time',
    'Custom range',
  ];

  TrackModel? _activeTrack;

  int _onSoundCloudTabIndex = 0;
  final List<String> _onSoundCloudTabs = [
    'Albums & Playlists',
    'Algorithms',
    'Beatza Apps',
  ];

  @override
  void initState() {
    super.initState();
    PaymentService.subscriptionSuccessNotifier.checkStatusFromApi();
  }

  String _getDateRangeText() {
    switch (_selectedFilter) {
      case 'Today':
        return 'Apr 10';
      case 'Last 7 days':
        return 'Apr 3 - Apr 9';
      case 'Last 30 days':
        return 'Mar 11 - Apr 9';
      case 'Last 12 months':
        return 'Apr 2025 - Mar 2026';
      case 'All time':
        return '2016 - Present';
      default:
        return 'Custom';
    }
  }

  String _getHeadlineText(int count) {
    if (_selectedFilter == 'All time') {
      return '$count $_selectedStat since 2016';
    } else {
      return '$count $_selectedStat in the ${_selectedFilter.toLowerCase()}';
    }
  }

  String _getEmptyStateButtonText() {
    switch (_selectedFilter) {
      case 'Today':
        return 'Switch to last 7 days';
      case 'Last 7 days':
        return 'Switch to last 30 days';
      case 'Last 30 days':
        return 'Switch to last 12 months';
      case 'Last 12 months':
        return 'Switch to all time';
      case 'All time':
        return 'Distribute a track';
      default:
        return 'Switch timeframe';
    }
  }

  void _onEmptyStateButtonPressed() {
    if (_selectedFilter == 'All time') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const UploadTrackScreen()),
      );
    } else {
      setState(() {
        if (_selectedFilter == 'Today') {
          _selectedFilter = 'Last 7 days';
        } else if (_selectedFilter == 'Last 7 days') {
          _selectedFilter = 'Last 30 days';
        } else if (_selectedFilter == 'Last 30 days') {
          _selectedFilter = 'Last 12 months';
        } else if (_selectedFilter == 'Last 12 months') {
          _selectedFilter = 'All time';
        }
      });
    }
  }

  void _showProUpgradeModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 24.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 350,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.pureBlack,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      child: Container(
                        height: 250,
                        width: 220,
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange,
                          border: Border.all(
                            color: AppColors.primaryOrangeAccent,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryOrange.withValues(alpha: 0.5),
                              blurRadius: 40,
                            ),
                          ],
                          image: const DecorationImage(
                            image: NetworkImage(
                              'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?q=80&w=400&auto=format&fit=crop',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: AppColors.whiteSmoke,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryOrange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  color: AppColors.whiteSmoke,
                                  size: 12,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'ARTIST PRO',
                                  style: TextStyle(
                                    color: AppColors.whiteSmoke,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'FOR ARTISTS',
                              style: TextStyle(
                                color: AppColors.whiteSmoke,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Unlock artist tools\n& unlimited\nuploads.',
                        style: TextStyle(
                          color: AppColors.whiteSmoke,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Not available on mobile. Cancel anytime.',
                        style: TextStyle(
                          color: AppColors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Restrictions apply.',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.whiteSmoke,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const PremiumSubscriptionScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'View Plans',
                            style: TextStyle(
                              color: AppColors.pureBlack,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const PremiumSubscriptionScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'See all plans',
                            style: TextStyle(
                              color: AppColors.whiteSmoke,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showInsightsInfoModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.chineseBlack,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Stack(
              children: [
                SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 20),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.white54,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                height: 200,
                                width: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: CustomPaint(
                                  painter: WaveformGraphicPainter(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'All Platform Insights',
                              style: TextStyle(
                                color: AppColors.whiteSmoke,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  color: AppColors.whiteSmoke,
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                                children: [
                                  TextSpan(
                                    text:
                                        'Your All Platforms Insights only shows Spotify and Apple Music data for tracks you\'ve released using ',
                                  ),
                                  TextSpan(
                                    text: 'Beatza Distribution.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'If you\'ve distributed songs through other services, those streams won\'t appear here—so your totals may differ from what you see on other platforms. If you want to migrate previously released tracks to Beatza, simply follow these instructions.',
                              style: TextStyle(
                                color: AppColors.whiteSmoke,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Once a track is released through Beatza, its data will appear in your All Platforms Insights within 24–48 hours.',
                              style: TextStyle(
                                color: AppColors.whiteSmoke,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.whiteSmoke,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: AppColors.chineseBlack,
                      ),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          color: AppColors.whiteSmoke,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFilterDropdown(BuildContext context) async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final result = await showMenu<String>(
      context: context,
      position: position,
      color: AppColors.containerMid,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: _filterOptions.map((String choice) {
        return PopupMenuItem<String>(
          value: choice,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                choice,
                style: TextStyle(
                  color: AppColors.whiteSmoke,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_selectedFilter == choice)
                Icon(Icons.check, color: AppColors.whiteSmoke, size: 20),
            ],
          ),
        );
      }).toList(),
    );

    if (result != null) {
      setState(() {
        _selectedFilter = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeService>();
    return Scaffold(
      backgroundColor: AppColors.backgroundDark3,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark3,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.whiteSmoke,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Your insights',
          style: TextStyle(
            color: AppColors.whiteSmoke,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ValueListenableBuilder<List<TrackModel>>(
            valueListenable: AudioUploadService.globalMockTracksNotifier,
            builder: (context, tracks, child) {
              if (tracks.isEmpty && _activeTab == InsightTab.beatza) {
                return _buildEmptySoundCloudView();
              }
              int plays = 0;
              int likes = 0;
              int comments = 0;
              int reposts = 0;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: _activeTrack != null ? 100 : 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderTabs(),
                    const SizedBox(height: 20),
                    if (_activeTab == InsightTab.beatza)
                      _buildSoundCloudView(
                        tracks,
                        plays,
                        likes,
                        comments,
                        reposts,
                      )
                    else if (_activeTab == InsightTab.allPlatforms)
                      _buildAllPlatformsPromo()
                    else if (_activeTab == InsightTab.fans)
                      _buildFansTabWrapper(),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildTabItem('Beatza', InsightTab.beatza),
            const SizedBox(width: 24),
            _buildTabItem('All Platforms', InsightTab.allPlatforms),
            const SizedBox(width: 24),
            _buildTabItem('Fans', InsightTab.fans, isNew: true),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String title, InsightTab tab, {bool isNew = false}) {
    bool isActive = _activeTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tab),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isActive ? AppColors.whiteSmoke : AppColors.white54,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (isNew) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'NEW',
                    style: TextStyle(
                      color: AppColors.whiteSmoke,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            width: isNew ? title.length * 8.5 + 30 : title.length * 8.5,
            color: isActive ? AppColors.whiteSmoke : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildFansTabWrapper() {
    return ValueListenableBuilder<SubscriptionState>(
      valueListenable: PaymentService.subscriptionSuccessNotifier,
      builder: (context, state, _) {
        if (state.isPro) {
          return _buildFansContent();
        } else {
          return _buildFansLockedContent();
        }
      },
    );
  }

  Widget _buildFansContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterDropdown(),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 260,
              width: double.infinity,
              color: AppColors.container,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?q=80&w=600&auto=format&fit=crop',
                    fit: BoxFit.cover,
                    color: Colors.redAccent.withValues(alpha: 0.4),
                    colorBlendMode: BlendMode.srcOver,
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.pureBlack.withValues(alpha: 0.8),
                            Colors.transparent,
                            AppColors.pureBlack.withValues(alpha: 0.9),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          color: AppColors.whiteSmoke,
                          size: 50,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Waiting for data...',
                          style: TextStyle(
                            color: AppColors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Keep building engagement\nto see your top fans',
            style: TextStyle(
              color: AppColors.whiteSmoke,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Share your tracks and encourage listeners to play, like, comment, repost, or download. Once you build enough activity over 30 days, you\'ll see your most engaged fans here.',
            style: TextStyle(
              color: AppColors.whiteSmoke,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UploadTrackScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.whiteSmoke,
                foregroundColor: AppColors.pureBlack,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                'Upload',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.whiteSmoke, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                backgroundColor: Colors.transparent,
              ),
              child: Text(
                'Monetize eligible tracks',
                style: TextStyle(
                  color: AppColors.whiteSmoke,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 48),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Reasons why you might not be\nseeing fans.',
            style: TextStyle(
              color: AppColors.whiteSmoke,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildReasonItem(
          Icons.bar_chart,
          'You did not receive a significant amount of plays on your tracks for this reporting period.',
          'You may have just recently started monetizing your music directly on Beatza or with an eligible rightsholder. In order for us to tell you which of your fans are engaged with your music we take some time to collect and analyze the data. Fan data refreshes on the 2nd of every month.',
        ),
        _buildReasonItem(
          Icons.money_off,
          'Your tracks are not being monetized.',
          'Only your tracks that are being monetized on Beatza or through a participating rightsholder will be eligible to collect Fan Powered Royalties. You must have correctly monetized tracks to see fans on this page.',
        ),
        _buildReasonItem(
          Icons.block,
          'Your label might not be monetizing...',
          'Make sure your label or distributor is participating in Fan Powered Royalties to see your fan engagement.',
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildFilterDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Builder(
            builder: (context) {
              return GestureDetector(
                onTap: () => _showFilterDropdown(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.containerMid,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedFilter,
                        style: TextStyle(
                          color: AppColors.whiteSmoke,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.whiteSmoke,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFansLockedContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterDropdown(),
          const SizedBox(height: 40),
          Center(
            child: Container(
              height: 180,
              width: 180,
              decoration: BoxDecoration(
                color: AppColors.surfaceMid,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_alt_outlined,
                color: AppColors.white24,
                size: 80,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'Unlock Top Fans with\nArtist Pro',
            style: TextStyle(
              color: AppColors.whiteSmoke,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Discover who your biggest fans are, what tracks they listen to the most, and connect with them directly.',
            style: TextStyle(
              color: AppColors.whiteSmoke,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PremiumSubscriptionScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.whiteSmoke,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                'Upgrade to Artist Pro',
                style: TextStyle(
                  color: AppColors.pureBlack,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.whiteSmoke, width: 2),
            ),
            child: Icon(icon, color: AppColors.whiteSmoke, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.whiteSmoke,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.whiteSmoke,
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySoundCloudView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderTabs(),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: CustomPaint(painter: OrangeMixerPainter()),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'Get unmatched insights\ninto your listeners that\nyou won\'t find anywhere\nelse.',
                  style: TextStyle(
                    color: AppColors.whiteSmoke,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Beatza is the only platform that lets you easily identify and connect with your top fans based on their listening and engagement habits.',
                  style: TextStyle(
                    color: AppColors.whiteSmoke,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'To get started, all it takes is an upload.',
                  style: TextStyle(
                    color: AppColors.whiteSmoke,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UploadTrackScreen(),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.whiteSmoke, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      backgroundColor: Colors.transparent,
                    ),
                    child: Text(
                      'Upload',
                      style: TextStyle(
                        color: AppColors.whiteSmoke,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundCloudView(
    List<TrackModel> tracks,
    int plays,
    int likes,
    int comments,
    int reposts,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterDropdown(),
        const SizedBox(height: 16),
        _buildMainStat(plays),
        const SizedBox(height: 16),
        _buildStatsChipsRow(plays, likes, comments, reposts),
        const SizedBox(height: 24),
        _buildDateRow(),
        const SizedBox(height: 40),
        _buildEmptyChartArea(),
        const SizedBox(height: 40),
        _buildTopTracksSection(tracks),
        const SizedBox(height: 40),
        _buildTopListenersSection(),
        const SizedBox(height: 40),
        _buildTopLocationsSection(),
        const SizedBox(height: 40),
        _buildOnSoundCloudSection(),
      ],
    );
  }

  Widget _buildMainStat(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${_getHeadlineText(count)}\n',
              style: TextStyle(
                color: AppColors.whiteSmoke,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                height: 1.1,
                letterSpacing: -0.5,
              ),
            ),
            TextSpan(
              text: '(0%)',
              style: TextStyle(
                color: AppColors.white54,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                height: 1.1,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsChipsRow(int plays, int likes, int comments, int reposts) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildStatChip(Icons.play_arrow_outlined, '$plays plays', 'plays'),
          _buildStatChip(Icons.favorite, '$likes likes', 'likes'),
          _buildStatChip(
            Icons.chat_bubble_outline,
            '$comments comments',
            'comments',
          ),
          _buildStatChip(Icons.sync_alt, '$reposts reposts', 'reposts'),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, String statType) {
    bool isActive = _selectedStat == statType;
    return GestureDetector(
      onTap: () => setState(() => _selectedStat = statType),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.whiteSmoke : AppColors.containerMid,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.pureBlack : AppColors.whiteSmoke,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.pureBlack : AppColors.whiteSmoke,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _getDateRangeText(),
            style: TextStyle(
              color: AppColors.whiteSmoke,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Data updates every 24 hours',
            style: TextStyle(color: AppColors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChartArea() {
    return Column(
      children: [
        Text(
          'Looks like there is no activity for the selected\ntimeframe',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.whiteSmoke,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 16),
        if (_selectedFilter == 'All time')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Distribute more of your Beatza tracks to reach\nnew listeners. Your data will appear here once your\nrelease is live.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.white54,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          )
        else
          Text(
            'Try selecting another timeframe.',
            style: TextStyle(color: AppColors.white54, fontSize: 14),
          ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _onEmptyStateButtonPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: _selectedFilter == 'All time'
                  ? AppColors.containerMid
                  : AppColors.whiteSmoke,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _getEmptyStateButtonText(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _selectedFilter == 'All time'
                    ? AppColors.whiteSmoke
                    : AppColors.pureBlack,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopTracksSection(List<TrackModel> tracks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top tracks',
                style: TextStyle(
                  color: AppColors.whiteSmoke,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TopTracksScreen(),
                  ),
                ),
                child: Text(
                  'See all',
                  style: TextStyle(color: AppColors.white54, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _selectedFilter,
            style: TextStyle(color: AppColors.white54, fontSize: 13),
          ),
        ),
        const SizedBox(height: 16),
        if (tracks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'No tracks available',
              style: TextStyle(color: AppColors.white54),
            ),
          )
        else
          ...tracks.take(3).map((t) {
            return ListTile(
              onTap: () => setState(() => _activeTrack = t),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMid,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: t.coverImagePath != null && t.coverImagePath!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.file(
                          File(t.coverImagePath!),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(Icons.music_note, color: AppColors.white24),
              ),
              title: Text(
                t.title,
                style: TextStyle(
                  color: AppColors.whiteSmoke,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Row(
                children: [
                  Icon(
                    _selectedStat == 'plays'
                        ? Icons.play_arrow_outlined
                        : (_selectedStat == 'likes'
                              ? Icons.favorite
                              : Icons.chat_bubble_outline),
                    color: AppColors.white54,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '0',
                    style: TextStyle(color: AppColors.white54, fontSize: 13),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildTopListenersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top listeners',
                style: TextStyle(
                  color: AppColors.whiteSmoke,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.lock_outline, color: AppColors.white54, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'See all',
                    style: TextStyle(color: AppColors.white54, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _selectedFilter,
            style: TextStyle(color: AppColors.white54, fontSize: 13),
          ),
        ),
        const SizedBox(height: 16),
        _buildPlaceholderItem(circular: true),
        const SizedBox(height: 16),
        _buildPlaceholderItem(circular: true),
        const SizedBox(height: 16),
        _buildPlaceholderItem(circular: true),
        const SizedBox(height: 24),
        _buildInlineProCard(
          'Know who your fans are\n—see your top listeners\nwith Artist Pro.',
        ),
      ],
    );
  }

  Widget _buildTopLocationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top locations',
                style: TextStyle(
                  color: AppColors.whiteSmoke,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.lock_outline, color: AppColors.white54, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'See all',
                    style: TextStyle(color: AppColors.white54, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _selectedFilter,
            style: TextStyle(color: AppColors.white54, fontSize: 13),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Icon(Icons.public, color: AppColors.white10, size: 180),
        ),
        const SizedBox(height: 16),
        _buildPlaceholderItem(circular: false),
        const SizedBox(height: 24),
        _buildInlineProCard(
          'See the rest of your top\ncountries and cities\nwith Artist Pro',
        ),
      ],
    );
  }

  Widget _buildOnSoundCloudSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'On Beatza',
                style: TextStyle(
                  color: AppColors.whiteSmoke,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.lock_outline, color: AppColors.white54, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'See all',
                    style: TextStyle(color: AppColors.white54, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: List.generate(_onSoundCloudTabs.length, (index) {
              final isActive = _onSoundCloudTabIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _onSoundCloudTabIndex = index),
                child: Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Text(
                    _onSoundCloudTabs[index],
                    style: TextStyle(
                      color: isActive
                          ? AppColors.whiteSmoke
                          : AppColors.white54,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _selectedFilter,
            style: TextStyle(color: AppColors.white54, fontSize: 13),
          ),
        ),
        const SizedBox(height: 16),
        if (_onSoundCloudTabIndex == 0) ...[
          _buildPlaceholderItem(circular: false),
          const SizedBox(height: 16),
          _buildPlaceholderItem(circular: false),
        ] else if (_onSoundCloudTabIndex == 1) ...[
          _buildPlaceholderItem(circular: false),
        ] else ...[
          _buildPlaceholderItem(circular: false),
          const SizedBox(height: 16),
          _buildPlaceholderItem(circular: false),
          const SizedBox(height: 16),
          _buildPlaceholderItem(circular: false),
        ],
      ],
    );
  }

  Widget _buildPlaceholderItem({required bool circular}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.white10,
              shape: circular ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: circular ? null : BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 120, height: 10, color: AppColors.white10),
              const SizedBox(height: 10),
              Container(width: 180, height: 10, color: AppColors.white10),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInlineProCard(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.whiteSmoke,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.whiteSmoke,
              foregroundColor: AppColors.pureBlack,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: _showProUpgradeModal,
            child: Text(
              'Upgrade to Artist Pro',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllPlatformsPromo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFilterDropdown(),
              GestureDetector(
                onTap: _showInsightsInfoModal,
                child: Icon(
                  Icons.help_outline,
                  color: AppColors.whiteSmoke,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              height: 200,
              width: 300,
              child: CustomPaint(painter: WaveformGraphicPainter()),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'Unlock key performance\nand audience insights\nacross multiple platforms\nfor your music',
            style: TextStyle(
              color: AppColors.whiteSmoke,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Access audience and performance insights for your distributed tracks from Spotify, Apple Music, and Beatza all from one dashboard.',
            style: TextStyle(
              color: AppColors.whiteSmoke,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Upgrade your account, upload and distribute your track to get started.',
            style: TextStyle(
              color: AppColors.whiteSmoke,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: _showProUpgradeModal,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.whiteSmoke, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                backgroundColor: Colors.transparent,
              ),
              child: Text(
                'Upgrade to Artist Pro',
                style: TextStyle(
                  color: AppColors.whiteSmoke,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TopTracksScreen extends StatelessWidget {
  const TopTracksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeService>();
    return Scaffold(
      backgroundColor: AppColors.backgroundDark3,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark3,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.whiteSmoke,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Your insights',
          style: TextStyle(
            color: AppColors.whiteSmoke,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Top tracks on Beatza',
              style: TextStyle(
                color: AppColors.whiteSmoke,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildSmallDropdown('Plays'),
                const SizedBox(width: 8),
                _buildSmallDropdown('All time'),
                const Spacer(),
                Text(
                  '2016 - Present',
                  style: TextStyle(
                    color: AppColors.whiteSmoke,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '1 track',
              style: TextStyle(color: AppColors.white54, fontSize: 12),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<TrackModel>>(
              valueListenable: AudioUploadService.globalMockTracksNotifier,
              builder: (context, tracks, child) {
                if (tracks.isEmpty) {
                  return Center(
                    child: Text(
                      'No tracks found',
                      style: TextStyle(color: AppColors.white54),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMid,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child:
                            track.coverImagePath != null &&
                                track.coverImagePath!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.file(
                                  File(track.coverImagePath!),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(Icons.music_note, color: AppColors.white24),
                      ),
                      title: Text(
                        track.title,
                        style: TextStyle(
                          color: AppColors.whiteSmoke,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          Icon(
                            Icons.play_arrow_outlined,
                            color: AppColors.white54,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '0',
                            style: TextStyle(
                              color: AppColors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallDropdown(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.containerMid,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              color: AppColors.whiteSmoke,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.whiteSmoke,
            size: 16,
          ),
        ],
      ),
    );
  }
}

class WaveformGraphicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = AppColors.flashPurple.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final fillPaint = Paint()
      ..color = AppColors.insightsChartFill
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = AppColors.whiteSmoke
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(size.width * 0.4, size.height * 0.5);
    canvas.rotate(-0.3);
    canvas.translate(-size.width * 0.4, -size.height * 0.5);

    final rect = Rect.fromCenter(
      center: Offset(size.width * 0.4, size.height * 0.5),
      width: 140,
      height: 160,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));

    canvas.drawRRect(rrect, fillPaint);
    canvas.drawRRect(rrect, borderPaint);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.4), 3, dotPaint);
    canvas.drawCircle(
      Offset(size.width * 0.35, size.height * 0.35),
      3,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.4, size.height * 0.45),
      3,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.45, size.height * 0.38),
      3,
      dotPaint,
    );
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 3, dotPaint);

    canvas.drawCircle(
      Offset(size.width * 0.4, size.height * 0.65),
      16,
      dotPaint,
    );
    canvas.restore();
    final wirePaint = Paint()
      ..shader = LinearGradient(
        colors: [AppColors.flashPurple, AppColors.studioActionBlue],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.55, size.height * 0.1);
    path.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.2,
      size.width * 0.6,
      size.height * 0.4,
    );
    path.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.6,
      size.width * 0.8,
      size.height * 0.7,
    );
    path.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.8,
      size.width * 0.6,
      size.height * 0.9,
    );
    canvas.drawPath(path, wirePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class OrangeMixerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final orangePaint = Paint()
      ..color = AppColors.primaryOrange
      ..style = PaintingStyle.fill;
    final whitePaint = Paint()
      ..color = AppColors.whiteSmoke
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = AppColors.primaryOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-0.2);
    canvas.translate(-size.width / 2, -size.height / 2);
    final mainRect = Rect.fromLTWH(20, 20, 220, 90);
    canvas.drawRRect(
      RRect.fromRectAndRadius(mainRect, const Radius.circular(8)),
      borderPaint,
    );
    for (int i = 0; i < 10; i++) {
      canvas.drawLine(
        Offset(40.0 + (i * 15), 50.0 + (i % 2 == 0 ? 10 : -10)),
        Offset(40.0 + (i * 15), 70.0),
        whitePaint..strokeWidth = 3,
      );
    }
    canvas.drawCircle(const Offset(100, 140), 16, orangePaint);
    canvas.drawCircle(const Offset(145, 140), 16, orangePaint);
    canvas.drawCircle(const Offset(190, 140), 16, orangePaint);
    canvas.drawCircle(const Offset(95, 135), 3, whitePaint);
    canvas.drawCircle(const Offset(140, 135), 3, whitePaint);
    canvas.drawCircle(const Offset(185, 135), 3, whitePaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(30, 130, 40, 30),
        const Radius.circular(4),
      ),
      whitePaint,
    );
    canvas.drawCircle(
      const Offset(42, 145),
      6,
      Paint()
        ..color = AppColors.pureBlack
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      const Offset(54, 145),
      6,
      Paint()
        ..color = AppColors.pureBlack
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
