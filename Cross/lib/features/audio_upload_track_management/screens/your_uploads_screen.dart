import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:cross_team5/features/audio_upload_track_management/models/track_model.dart';
import 'package:cross_team5/features/audio_upload_track_management/models/track.dart';
import 'package:cross_team5/features/audio_upload_track_management/services/audio_upload_service.dart';
import 'package:cross_team5/features/audio_upload_track_management/services/track_api_service.dart';
import 'package:cross_team5/features/audio_upload_track_management/widgets/smart_player_widget.dart';
import 'package:cross_team5/features/audio_upload_track_management/screens/upload_track_screen.dart';
import 'package:cross_team5/features/premium_subscription/services/payment_service.dart';
import '../../premium_subscription/screens/premium_subscription.dart';

enum _Sort { recentlyAdded, trackName }

enum _Filter { all, public, private }

class YourUploadsScreen extends StatefulWidget {
  const YourUploadsScreen({super.key});

  @override
  State<YourUploadsScreen> createState() => _YourUploadsScreenState();
}

class _YourUploadsScreenState extends State<YourUploadsScreen> {
  final TrackApiService _apiService = TrackApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final TextEditingController _searchController = TextEditingController();

  List<Track> _serverTracks = [];
  bool _isLoadingServer = true;
  String? _serverError;

  TrackModel? _playingLocalTrack;

  String _searchQuery = '';
  _Sort _sort = _Sort.recentlyAdded;
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    _loadServerTracks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadServerTracks() async {
    setState(() {
      _isLoadingServer = true;
      _serverError = null;
    });

    final userId = await _storage.read(key: 'user_id');

    if (userId == null || userId.trim().isEmpty) {
      setState(() {
        _isLoadingServer = false;
        _serverError = 'User not identified. Please log in again.';
      });
      return;
    }

    final result = await _apiService.getUserPostedTracks(userId: userId);

    setState(() {
      _isLoadingServer = false;
      if (result.$1 == 200) {
        _serverTracks = result.$2 as List<Track>;
      } else {
        _serverError = result.$2.toString();
      }
    });
  }

  List<TrackModel> _filterLocal(List<TrackModel> all) {
    var list = all
        .where(
          (t) => t.title.toLowerCase().contains(_searchQuery.toLowerCase()),
    )
        .toList();

    if (_filter == _Filter.public) {
      list = list.where((t) => t.visibility == TrackVisibility.public).toList();
    } else if (_filter == _Filter.private) {
      list = list.where((t) => t.visibility != TrackVisibility.public).toList();
    }

    if (_sort == _Sort.recentlyAdded) {
      list.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
    } else {
      list.sort((a, b) => a.title.compareTo(b.title));
    }
    return list;
  }

  List<Track> _filterServer() {
    if (_searchQuery.isEmpty) return _serverTracks;
    return _serverTracks
        .where(
          (t) => t.title.toLowerCase().contains(_searchQuery.toLowerCase()),
    )
        .toList();
  }

  void _showFilterMenu(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(Offset.zero, ancestor: overlay);

    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(pos.dx, pos.dy + 50, 16, 0),
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        _menuItem('recent', 'Recently added', _sort == _Sort.recentlyAdded),
        _menuItem('name', 'Track name', _sort == _Sort.trackName),
        const PopupMenuDivider(height: 1),
        _menuItem('all', 'All', _filter == _Filter.all),
        _menuItem('pub', 'Public', _filter == _Filter.public),
        _menuItem('priv', 'Private', _filter == _Filter.private),
      ],
    );

    if (result != null) {
      setState(() {
        if (result == 'recent') _sort = _Sort.recentlyAdded;
        if (result == 'name') _sort = _Sort.trackName;
        if (result == 'all') _filter = _Filter.all;
        if (result == 'pub') _filter = _Filter.public;
        if (result == 'priv') _filter = _Filter.private;
      });
    }
  }

  PopupMenuItem<String> _menuItem(String value, String label, bool selected) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: selected
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ],
      ),
    );
  }

  void _playLocal(TrackModel track) {
    setState(() => _playingLocalTrack = track);
  }

  void _onServerTrackTap(Track track) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '"${track.title}" — playback available after Module 5 integration',
        ),
        backgroundColor: const Color(0xFF2A2A2A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            ValueListenableBuilder<List<TrackModel>>(
              valueListenable: AudioUploadService.globalMockTracksNotifier,
              builder: (context, allLocal, _) {
                final localTracks = _filterLocal(allLocal);
                final serverTracks = _filterServer();

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      backgroundColor: const Color(0xFF0A0A0A),
                      expandedHeight: 120,
                      pinned: true,
                      leading: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          children: [
                            Positioned(
                              top: -80,
                              right: -50,
                              child: Container(
                                width: 300,
                                height: 300,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(
                                        0xFF8A2BE2,
                                      ).withValues(alpha: 0.4),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(60),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (v) =>
                                        setState(() => _searchQuery = v),
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      hintText: 'Search tracks',
                                      prefixIcon: Icon(
                                        Icons.search,
                                        color: Colors.white54,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => _showFilterMenu(context),
                                child: const Icon(
                                  Icons.tune,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your uploads',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ValueListenableBuilder<bool>(
                                  valueListenable: PaymentService.subscriptionSuccessNotifier,
                                  builder: (context, isPro, _) {
                                    return IconButton(
                                      icon: const Icon(
                                        Icons.cloud_upload_outlined,
                                        color: Colors.white,
                                      ),
                                      onPressed: () async {
                                        final int currentUploads = _serverTracks.length + AudioUploadService.globalMockTracksNotifier.value.length;
                                        if (!isPro && currentUploads >= 3) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Free tier limited to 3 uploads. Please upgrade to Pro.'),
                                              backgroundColor: Colors.orange,
                                            ),
                                          );
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => const PremiumSubscriptionScreen()),
                                          );
                                          return;
                                        }

                                        final AudioUploadService audioService = AudioUploadService();
                                        final file = await audioService.pickAudioFile();
                                        if (file != null) {
                                          if (!context.mounted) return;
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const UploadTrackScreen(),
                                              settings: RouteSettings(arguments: file),
                                            ),
                                          );
                                        }
                                      },
                                    );
                                  },
                                ),
                                GestureDetector(
                                  onTap: () {
                                    if (localTracks.isNotEmpty) {
                                      _playLocal(localTracks.first);
                                    } else if (serverTracks.isNotEmpty) {
                                      _onServerTrackTap(serverTracks.first);
                                    }
                                  },
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_serverError != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber,
                                  color: Colors.orange,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Could not load server tracks.',
                                    style: TextStyle(
                                      color: Colors.orange[300],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _loadServerTracks,
                                  child: const Text(
                                    'Retry',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    if (_isLoadingServer)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.orange,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        ),
                      ),

                    if (localTracks.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            top: 12,
                            bottom: 4,
                          ),
                          child: Text(
                            'Just uploaded',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate((ctx, i) {
                          final t = localTracks[i];
                          final isPlaying = _playingLocalTrack?.id == t.id;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: _thumb(localPath: t.coverImagePath),
                            title: Text(
                              t.title,
                              style: TextStyle(
                                color: isPlaying ? Colors.orange : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              t.processingState ==
                                  TrackProcessingState.processing
                                  ? 'Processing...'
                                  : t.visibility.name,
                              style: TextStyle(
                                color:
                                t.processingState ==
                                    TrackProcessingState.processing
                                    ? Colors.orange
                                    : Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.more_horiz,
                                color: Colors.white54,
                              ),
                              onPressed: () => _localOptions(ctx, t),
                            ),
                            onTap: () => _playLocal(t),
                          );
                        }, childCount: localTracks.length),
                      ),
                    ],

                    if (serverTracks.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            top: 12,
                            bottom: 4,
                          ),
                          child: Text(
                            'On SoundCloud',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate((ctx, i) {
                          final t = serverTracks[i];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: _thumb(networkUrl: t.imageUrl),
                            title: Text(
                              t.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Row(
                              children: [
                                Text(
                                  t.isPrivate ? 'Private' : 'Public',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                                if (t.numPlays > 0) ...[
                                  Text(
                                    ' · ',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${_fmt(t.numPlays)} plays',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.more_horiz,
                                color: Colors.white54,
                              ),
                              onPressed: () => _serverOptions(ctx, t),
                            ),
                            onTap: () => _onServerTrackTap(t),
                          );
                        }, childCount: serverTracks.length),
                      ),
                    ],

                    if (!_isLoadingServer &&
                        localTracks.isEmpty &&
                        serverTracks.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                color: Colors.grey[700],
                                size: 60,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No uploads yet',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ValueListenableBuilder<bool>(
                                valueListenable: PaymentService.subscriptionSuccessNotifier,
                                builder: (context, isPro, _) {
                                  return ElevatedButton.icon(
                                    onPressed: () async {
                                      final int currentUploads = _serverTracks.length + AudioUploadService.globalMockTracksNotifier.value.length;
                                      if (!isPro && currentUploads >= 3) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Free tier limited to 3 uploads. Please upgrade to Pro.'),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const PremiumSubscriptionScreen()),
                                        );
                                        return;
                                      }

                                      final AudioUploadService audioService = AudioUploadService();
                                      final file = await audioService.pickAudioFile();
                                      if (file != null) {
                                        if (!context.mounted) return;
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const UploadTrackScreen(),
                                            settings: RouteSettings(arguments: file),
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.cloud_upload_outlined),
                                    label: const Text('Upload your first track'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                );
              },
            ),

            if (_playingLocalTrack != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: SafeArea(
                  child: SmartWaveformPlayer(
                    track: _playingLocalTrack!,
                    onClose: () => setState(() => _playingLocalTrack = null),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _thumb({String? localPath, String? networkUrl}) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: localPath != null
            ? Image.file(File(localPath), fit: BoxFit.cover)
            : networkUrl != null
            ? Image.network(
          networkUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
          const Icon(Icons.music_note, color: Colors.white24),
        )
            : const Icon(Icons.music_note, color: Colors.white24),
      ),
    );
  }

  void _localOptions(BuildContext ctx, TrackModel track) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.play_arrow, color: Colors.white),
              title: const Text('Play', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _playLocal(track);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.white),
              title: const Text(
                'Edit track',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.pop(context);

                final AudioUploadService audioService = AudioUploadService();
                final file = await audioService.pickAudioFile();

                if (file != null && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UploadTrackScreen(),
                      settings: RouteSettings(arguments: file),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _serverOptions(BuildContext ctx, Track track) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white),
              title: Text(
                track.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${_fmt(track.numPlays)} plays · ${track.isPrivate ? "Private" : "Public"}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}