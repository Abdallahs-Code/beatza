import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';
import '../services/audio_upload_service.dart';
import '../models/track_model.dart';
import 'your_uploads_screen.dart';
import 'artist_pro_screens.dart';

class YourInsights extends StatefulWidget {
  final TrackModel track;
  final VoidCallback? onClose;

  const YourInsights({super.key, required this.track, this.onClose});

  @override
  State<YourInsights> createState() => _SmartWaveformPlayerState();
}

class _SmartWaveformPlayerState extends State<YourInsights> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  List<double> _waveformHeights = [];
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _generateWaveform();
    _initPlayer();
  }

  @override
  void didUpdateWidget(covariant YourInsights oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track.id != widget.track.id) {
      _generateWaveform();
      _playTrack();
    }
  }

  void _generateWaveform() {
    final random = Random(widget.track.id.hashCode);
    _waveformHeights = List.generate(60, (_) => random.nextDouble() * 40 + 10);
  }

  void _initPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() { _isPlaying = false; _position = Duration.zero; });
    });
    _playTrack();
  }

  void _playTrack() async {
    if (widget.track.audioUrl.isNotEmpty) {
      await _audioPlayer.play(DeviceFileSource(widget.track.audioUrl));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio file not found!'), backgroundColor: Colors.red));
      }
    }
  }

  void _togglePlay() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.resume();
    }
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
    });
  }

  void _showDevicesModal() {
    showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1E1E1E),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Current Device', style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.speaker_phone, color: Color(0xFFFF5500)),
                    title: const Text('Speaker', style: TextStyle(color: Colors.white, fontSize: 16)),
                    onTap: () => Navigator.pop(context),
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Other Devices', style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.airplay, color: Colors.white),
                    title: const Text('AirPlay or Bluetooth', style: TextStyle(color: Colors.white, fontSize: 16)),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.cast, color: Colors.white),
                    title: const Text('Google Cast', style: TextStyle(color: Colors.white, fontSize: 16)),
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          );
        }
    );
  }

  void _showFullPlayer() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.black,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) {
          return StatefulBuilder(
              builder: (context, setModalState) {
                return Container(
                  height: MediaQuery.of(context).size.height * 0.9,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    image: widget.track.coverImagePath != null
                        ? DecorationImage(
                      image: FileImage(File(widget.track.coverImagePath!)),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.darken),
                    )
                        : null,
                    color: const Color(0xFF121212),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white54, borderRadius: BorderRadius.circular(2)))),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32), onPressed: () => Navigator.pop(context)),
                            const Icon(Icons.more_horiz, color: Colors.white, size: 28),
                          ],
                        ),
                      ),
                      const Spacer(),
                      StreamBuilder<Duration>(
                          stream: _audioPlayer.onPositionChanged,
                          builder: (context, snapshot) {
                            double progress = _duration.inMilliseconds > 0 ? _position.inMilliseconds / _duration.inMilliseconds : 0.0;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: SizedBox(
                                height: 60,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: List.generate(_waveformHeights.length, (index) {
                                    bool isPlayed = (index / _waveformHeights.length) <= progress;
                                    return Expanded(
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 1),
                                        height: _waveformHeights[index],
                                        decoration: BoxDecoration(
                                          color: isPlayed ? const Color(0xFFFF5500) : Colors.white54,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            );
                          }
                      ),
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.transparent, Colors.black87], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            GestureDetector(
                              onTap: () {
                                _toggleLike();
                                setModalState((){});
                              },
                              child: Row(
                                children: [
                                  Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? const Color(0xFFFF5500) : Colors.white, size: 28),
                                  const SizedBox(width: 8),
                                  Text(_isLiked ? '2991' : '2990', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const Row(
                              children: [
                                Icon(Icons.chat_bubble_outline, color: Colors.white, size: 24),
                                SizedBox(width: 8),
                                Text('13', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                Share.share(
                                  'Check out ${widget.track.title} on SoundCloud! https://soundcloud.com',
                                  subject: 'Listen to ${widget.track.title}',
                                );
                              },
                              child: const Icon(Icons.ios_share, color: Colors.white, size: 24),
                            ),
                            const Icon(Icons.playlist_add, color: Colors.white, size: 26),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              }
          );
        }
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double progress = _duration.inMilliseconds > 0 ? _position.inMilliseconds / _duration.inMilliseconds : 0.0;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: _showFullPlayer,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: _togglePlay,
                child: SizedBox(
                  width: 40, height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        color: const Color(0xFFFF5500),
                        backgroundColor: Colors.transparent,
                        strokeWidth: 3,
                      ),
                      Container(
                        width: 32, height: 32,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.black, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.track.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    const Text('Belal Elseddik', style: TextStyle(color: Colors.white54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _showDevicesModal,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(Icons.devices, color: Color(0xFFFF5500), size: 22),
                ),
              ),
              GestureDetector(
                onTap: _toggleLike,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 4.0),
                  child: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? const Color(0xFFFF5500) : Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum InsightTab { soundcloud, allPlatforms }

class YourInsightsScreen extends StatefulWidget {
  const YourInsightsScreen({super.key});

  @override
  State<YourInsightsScreen> createState() => _YourInsightsScreenState();
}

class _YourInsightsScreenState extends State<YourInsightsScreen> {
  InsightTab _activeTab = InsightTab.soundcloud;
  String _selectedFilter = 'Last 30 days';
  String _selectedStat = 'plays';
  final List<String> _filterOptions = ['Last 7 days', 'Last 30 days', 'Last 12 months', 'All time'];

  TrackModel? _activeTrack;

  void _showProUpgradeModal() {
    showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF141414),
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0, bottom: MediaQuery.of(context).padding.bottom + 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Icon(Icons.flash_on, color: Color(0xFFD47AFA), size: 20),
                    SizedBox(width: 8),
                    Text('AMPLIFY', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Reach more listeners.', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, height: 1.1)),
                const SizedBox(height: 16),
                const Text('With Artist Pro, you can get your tracks analyzed and recommended to the right listeners without limits.', style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.4)),
                const SizedBox(height: 32),
                RichText(
                  text: TextSpan(
                      style: const TextStyle(color: Colors.white54, fontSize: 14),
                      children: [
                        const TextSpan(text: 'EGP 164.99/month. Cancel anytime. '),
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProRestrictionsScreen()));
                            },
                            child: const Text('Restrictions apply.', style: TextStyle(color: Colors.blueAccent, fontSize: 14)),
                          ),
                        ),
                      ]
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                    onPressed: () {},
                    child: const Text('Subscribe now', style: TextStyle(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                Center(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Maybe later', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)))),
              ],
            ),
          );
        }
    );
  }

  void _showCastModal() {
    showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1E1E1E),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Connect to a device', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.speaker_phone, color: Color(0xFFFF5500)),
                    title: const Text('This Phone', style: TextStyle(color: Colors.white, fontSize: 16)),
                    onTap: () => Navigator.pop(context),
                  ),
                  const Divider(color: Colors.white10, height: 16),
                  ListTile(
                    leading: const Icon(Icons.airplay, color: Colors.white),
                    title: const Text('AirPlay or Bluetooth', style: TextStyle(color: Colors.white, fontSize: 16)),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.cast, color: Colors.white),
                    title: const Text('Google Cast', style: TextStyle(color: Colors.white, fontSize: 16)),
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          );
        }
    );
  }

  void _showInsightsInfoModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
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
                            color: Colors.white38,
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
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF2A0055), Color(0xFFFF5500)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFD47AFA).withOpacity(0.1),
                                      blurRadius: 40,
                                      spreadRadius: 10,
                                    )
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(Icons.graphic_eq, color: Colors.white, size: 80),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            const Text(
                              'All Platform Insights',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                                children: [
                                  TextSpan(text: 'Your All Platforms Insights only shows Spotify and Apple Music data for tracks you\'ve released using '),
                                  TextSpan(text: 'SoundCloud Distribution.', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'If you\'ve distributed songs through other services, those streams won\'t appear here—so your totals may differ from what you see on other platforms. If you want to migrate previously released tracks to SoundCloud, simply follow these instructions.',
                              style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Once a track is released through SoundCloud, its data will appear in your All Platforms Insights within 24–48 hours.',
                              style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                            ),
                            const SizedBox(height: 100), // Space for button
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
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        backgroundColor: const Color(0xFF121212),
                      ),
                      child: const Text('Close', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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

  double _getStatsMultiplier() {
    if (_selectedFilter == 'Last 7 days') return 0.25;
    if (_selectedFilter == 'Last 30 days') return 1.0;
    if (_selectedFilter == 'Last 12 months') return 12.0;
    return 25.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Your insights',
          style: TextStyle(
            color: Colors.white,
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
              int trackCount = tracks.isNotEmpty ? tracks.length : 0;
              double multiplier = _getStatsMultiplier();

              // Mock logic for numbers
              int plays = 0; // matching screenshot logic
              int likes = 0;
              int comments = 0;
              int reposts = 0;
              int downloads = 0;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(bottom: _activeTrack != null ? 100 : 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderTabs(),
                    const SizedBox(height: 20),
                    if (_activeTab == InsightTab.soundcloud)
                      _buildSoundCloudView(tracks, plays, likes, comments, reposts, downloads, multiplier)
                    else if (_activeTab == InsightTab.allPlatforms)
                      _buildAllPlatformsPromo(),
                  ],
                ),
              );
            },
          ),
          if (_activeTrack != null)
            Positioned(
              left: 0, right: 0, bottom: 8,
              child: YourInsights(
                track: _activeTrack!,
                onClose: () => setState(() => _activeTrack = null),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTabItem('SoundCloud', InsightTab.soundcloud),
          const SizedBox(width: 24),
          _buildTabItem('All Platforms', InsightTab.allPlatforms),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, InsightTab tab) {
    bool isActive = _activeTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tab),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: isActive ? Colors.white : Colors.white54, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Container(height: 2, width: title.length * 8.5, color: isActive ? Colors.white : Colors.transparent),
        ],
      ),
    );
  }

  Widget _buildSoundCloudView(List<TrackModel> tracks, int plays, int likes, int comments, int reposts, int downloads, double multiplier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterDropdown(),
        const SizedBox(height: 16),
        _buildMainStat(plays),
        const SizedBox(height: 16),
        _buildStatsChipsRow(plays, likes, comments, reposts, downloads),
        const SizedBox(height: 24),
        _buildDateRow(),
        const SizedBox(height: 60),
        _buildEmptyChartArea(),
        const SizedBox(height: 60),
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

  Widget _buildFilterDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          PopupMenuButton<String>(
            color: const Color(0xFF2A2A2A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            onSelected: (v) => setState(() => _selectedFilter = v),
            itemBuilder: (ctx) => _filterOptions.map((e) => PopupMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedFilter, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
          SizedBox(width: 150,),
          if (_activeTab == InsightTab.allPlatforms)
            GestureDetector(
              onTap: _showInsightsInfoModal,
              child: const Icon(Icons.help_outline, color: Colors.white),
            )
        ],
      ),
    );
  }

  Widget _buildMainStat(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        '$count $_selectedStat in the ${_selectedFilter.toLowerCase()}\n(0%)',
        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -0.5),
      ),
    );
  }

  Widget _buildStatsChipsRow(int plays, int likes, int comments, int reposts, int downloads) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildStatChip(Icons.play_arrow_outlined, '$plays plays', 'plays'),
          _buildStatChip(Icons.favorite, '$likes likes', 'likes'),
          _buildStatChip(Icons.chat_bubble_outline, '$comments comments', 'comments'),
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
          color: isActive ? Colors.white : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? Colors.black : Colors.white54, size: 16),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: isActive ? Colors.black : Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Mar 11 - Apr 9', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          Text('Data updates every 24 hours', style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmptyChartArea() {
    return Column(
      children: [
        const Text(
          'Looks like there is no activity for the selected\ntimeframe',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.3),
        ),
        const SizedBox(height: 16),
        const Text('Try selecting another timeframe.', style: TextStyle(color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () {
            setState(() { _selectedFilter = 'Last 12 months'; _selectedStat = 'plays'; });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
            child: const Text('Switch to last 12 months', textAlign: TextAlign.center, style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
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
              const Text('Top tracks', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const YourUploadsScreen())),
                child: Text('See all', style: TextStyle(color: Colors.white54, fontSize: 13)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (tracks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('No tracks available', style: TextStyle(color: Colors.white54)),
          )
        else
          ...tracks.take(3).map((t) {
            return ListTile(
              onTap: () => setState(() => _activeTrack = t),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 50, height: 50,
                decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(4)),
                child: t.coverImagePath != null && t.coverImagePath!.isNotEmpty
                    ? ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.file(File(t.coverImagePath!), fit: BoxFit.cover))
                    : const Icon(Icons.music_note, color: Colors.white24),
              ),
              title: Text(t.title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Row(
                children: [
                  Icon(_selectedStat == 'plays' ? Icons.play_arrow_outlined : (_selectedStat == 'likes' ? Icons.favorite : Icons.bar_chart), color: Colors.white54, size: 16),
                  const SizedBox(width: 4),
                  const Text('0', style: TextStyle(color: Colors.white54, fontSize: 13)),
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
              const Text('Top listeners', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  const Icon(Icons.lock_outline, color: Colors.white54, size: 14),
                  const SizedBox(width: 4),
                  Text('See all', style: TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Last 30 days', style: TextStyle(color: Colors.white54, fontSize: 13)),
        ),
        const SizedBox(height: 16),
        _buildPlaceholderItem(circular: true),
        const SizedBox(height: 16),
        _buildPlaceholderItem(circular: true),
        const SizedBox(height: 16),
        _buildPlaceholderItem(circular: true),
        const SizedBox(height: 24),
        _buildInlineProCard('Know who your fans are\n—see your top listeners\nwith Artist Pro.'),
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
              const Text('Top locations', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  const Icon(Icons.lock_outline, color: Colors.white54, size: 14),
                  const SizedBox(width: 4),
                  Text('See all', style: TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Last 30 days', style: TextStyle(color: Colors.white54, fontSize: 13)),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: const Icon(Icons.public, color: Colors.white10, size: 180),
        ),
        const SizedBox(height: 16),
        _buildPlaceholderItem(circular: false),
        const SizedBox(height: 24),
        _buildInlineProCard('See the rest of your top\ncountries and cities\nwith Artist Pro'),
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
              const Text('On SoundCloud', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  const Icon(Icons.lock_outline, color: Colors.white54, size: 14),
                  const SizedBox(width: 4),
                  Text('See all', style: TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('Albums & Playlists', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(width: 20),
              Text('Algorithms', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(width: 20),
              Text('SoundCloud Apps', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Last 30 days', style: TextStyle(color: Colors.white54, fontSize: 13)),
        ),
        const SizedBox(height: 16),
        _buildPlaceholderItem(circular: false),
        const SizedBox(height: 16),
        _buildPlaceholderItem(circular: false),
      ],
    );
  }

  Widget _buildPlaceholderItem({required bool circular}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.white10,
              shape: circular ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: circular ? null : BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 120, height: 10, color: Colors.white10),
              const SizedBox(height: 10),
              Container(width: 180, height: 10, color: Colors.white10),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInlineProCard(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: _showProUpgradeModal,
            child: const Text('Upgrade to Artist Pro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          )
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
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              height: 240, width: 240,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF2A0055), Color(0xFFFF5500)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: const Color(0xFFD47AFA).withOpacity(0.1), blurRadius: 40, spreadRadius: 10)],
              ),
              child: const Center(child: Icon(Icons.graphic_eq, color: Colors.white, size: 80)),
            ),
          ),
          const SizedBox(height: 40),
          const Text('Unlock key performance\nand audience insights\nacross multiple platforms\nfor your music',
              style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -0.5)),
          const SizedBox(height: 24),
          const Text('Access audience and performance insights for your distributed tracks from Spotify, Apple Music, and SoundCloud all from one dashboard.',
              style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5)),
          const SizedBox(height: 24),
          const Text('Upgrade your account, upload and distribute your track to get started.',
              style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity, height: 56,
            child: OutlinedButton(
              onPressed: _showProUpgradeModal,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white, width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                backgroundColor: Colors.transparent,
              ),
              child: const Text('Upgrade to Artist Pro', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}