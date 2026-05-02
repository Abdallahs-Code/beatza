import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cross_team5/core/theme/app_colors.dart';

import 'package:cross_team5/features/activity/screens/behind_the_track_screen.dart';
import 'package:cross_team5/features/activity/screens/track_options_sheet.dart';
import 'package:cross_team5/features/audio_upload_track_management/models/track.dart';
import 'package:cross_team5/features/audio_upload_track_management/services/audio_upload_service.dart';
import 'package:cross_team5/features/audio_upload_track_management/services/track_api_service.dart';
import 'package:cross_team5/features/audio_upload_track_management/screens/upload_track_screen.dart';
import 'package:cross_team5/features/premium_subscription/services/payment_service.dart';
import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';
import 'package:cross_team5/features/playback_streaming_engine/services/playback_streaming_engine_service.dart';
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
  String? _fetchingPlaybackId;

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

  List<Track> _filteredTracks() {
    var list = _serverTracks
        .where(
          (t) => t.title.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    if (_filter == _Filter.public) {
      list = list.where((t) => !t.isPrivate).toList();
    } else if (_filter == _Filter.private) {
      list = list.where((t) => t.isPrivate).toList();
    }

    if (_sort == _Sort.trackName) {
      list.sort((a, b) => a.title.compareTo(b.title));
    }

    return list;
  }

  void _showFilterMenu(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(Offset.zero, ancestor: overlay);

    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(pos.dx, pos.dy + 50, 16, 0),
      color: AppColors.containerMid,
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
                ? Icon(Icons.check, color: AppColors.whiteSmoke, size: 18)
                : null,
          ),
          Text(
            label,
            style: TextStyle(color: AppColors.whiteSmoke, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Future<void> _onTrackTap(Track track) async {
    if (_fetchingPlaybackId != null) return;

    setState(() => _fetchingPlaybackId = track.id);
    final result = await _apiService.getTrackById(trackId: track.id);
    if (!mounted) return;
    setState(() => _fetchingPlaybackId = null);

    if (result.$1 != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load "${track.title}".'),
          backgroundColor: AppColors.containerMid,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final fullTrack = result.$2 as Track;
    final audioUrl = fullTrack.audioLink;

    if (audioUrl == null || audioUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${track.title}" has no playable audio.'),
          backgroundColor: AppColors.containerMid,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final playbackTrack = PlaybackTrackModel(
      id: fullTrack.id,
      title: fullTrack.title,
      artistName: fullTrack.displayArtist,
      audioUrl: audioUrl,
      artworkUrl: fullTrack.imageUrl,
      accessState: PlaybackAccessState.playable,
      sourceType: PlaybackSourceType.network,
      isPrivate: fullTrack.isPrivate,
      numLikes: fullTrack.numLikes,
      numPlays: fullTrack.numPlays,
      numReposts: fullTrack.numReposts,
      numComments: fullTrack.numComments,
      genre: fullTrack.genre,
      tags: fullTrack.tags,
    );

    await PlaybackStreamingEngineService.shared.playTrack(
      playbackTrack,
      queue: [playbackTrack],
      startIndex: 0,
    );
  }

  Future<void> _pickAndUpload(BuildContext ctx) async {
    final isPro = PaymentService.subscriptionSuccessNotifier.isPro;
    if (!isPro && _serverTracks.length >= 3) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: const Text(
            'Free tier limited to 3 uploads. Please upgrade to Pro.',
          ),
          backgroundColor: AppColors.primaryOrange,
        ),
      );
      Navigator.push(
        ctx,
        MaterialPageRoute(builder: (_) => const PremiumSubscriptionScreen()),
      );
      return;
    }
    final file = await AudioUploadService().pickAudioFile();
    if (file != null) {
      if (!ctx.mounted) return;
      await Navigator.push(
        ctx,
        MaterialPageRoute(
          builder: (_) => const UploadTrackScreen(),
          settings: RouteSettings(arguments: file),
        ),
      );
      if (mounted) _loadServerTracks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tracks = _filteredTracks();

    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.homeBackground,
              expandedHeight: 120,
              pinned: true,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: AppColors.whiteSmoke,
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
                              AppColors.uploadGlowPurple.withValues(alpha: 0.4),
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
                            color: AppColors.white10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) => setState(() => _searchQuery = v),
                            style: TextStyle(color: AppColors.whiteSmoke),
                            decoration: InputDecoration(
                              hintText: 'Search tracks',
                              prefixIcon: Icon(
                                Icons.search,
                                color: AppColors.white54,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _showFilterMenu(context),
                        child: Icon(Icons.tune, color: AppColors.whiteSmoke),
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
                    Text(
                      'Your uploads',
                      style: TextStyle(
                        color: AppColors.whiteSmoke,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_serverTracks.isEmpty && !_isLoadingServer)
                          ElevatedButton.icon(
                            onPressed: () => _pickAndUpload(context),
                            icon: const Icon(Icons.cloud_upload_outlined),
                            label: const Text('Upload your first track'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryOrange,
                              foregroundColor: AppColors.whiteSmoke,
                            ),
                          ),
                        GestureDetector(
                          onTap: tracks.isNotEmpty
                              ? () => _onTrackTap(tracks.first)
                              : null,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.whiteSmoke,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.play_arrow,
                              color: AppColors.pureBlack,
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
                      color: AppColors.primaryOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primaryOrange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: AppColors.primaryOrange,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Could not load your tracks.',
                            style: TextStyle(
                              color: AppColors.primaryOrange,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _loadServerTracks,
                          child: Text(
                            'Retry',
                            style: TextStyle(
                              color: AppColors.primaryOrange,
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
                        color: AppColors.primaryOrange,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
              ),

            if (tracks.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate((ctx, i) {
                  final t = tracks[i];
                  final isFetching = _fetchingPlaybackId == t.id;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: _thumb(networkUrl: t.imageUrl),
                    title: Text(
                      t.title,
                      style: TextStyle(
                        color: isFetching
                            ? AppColors.primaryOrange
                            : AppColors.whiteSmoke,
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
                            color: AppColors.greyMuted,
                            fontSize: 12,
                          ),
                        ),
                        if (t.numPlays > 0) ...[
                          Text(
                            ' · ',
                            style: TextStyle(
                              color: AppColors.greyMedium,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${_fmt(t.numPlays)} plays',
                            style: TextStyle(
                              color: AppColors.greyMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: isFetching
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.primaryOrange,
                              strokeWidth: 2,
                            ),
                          )
                        : IconButton(
                            icon: Icon(
                              Icons.more_horiz,
                              color: AppColors.white54,
                            ),
                            onPressed: () => _trackOptions(ctx, t),
                          ),
                    onTap: () => _onTrackTap(t),
                  );
                }, childCount: tracks.length),
              ),

            if (!_isLoadingServer && tracks.isEmpty && _serverError == null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        color: AppColors.greyMedium,
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No uploads yet',
                        style: TextStyle(color: AppColors.greyMuted, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      IconButton(
                        icon: Icon(
                          Icons.cloud_upload_outlined,
                          color: AppColors.whiteSmoke,
                        ),
                        onPressed: () => _pickAndUpload(context),
                      ),
                    ],
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _thumb({String? networkUrl}) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: networkUrl != null
            ? Image.network(
                networkUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Icon(Icons.music_note, color: AppColors.white24),
              )
            : Icon(Icons.music_note, color: AppColors.white24),
      ),
    );
  }

  void _trackOptions(BuildContext ctx, Track track) {
    final playbackTrack = PlaybackTrackModel(
      id: track.id,
      title: track.title,
      artistName: track.displayArtist,
      audioUrl: '',
      artworkUrl: track.imageUrl,
    );
    showModalBottomSheet<void>(
      context: ctx,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TrackOptionsSheet(
        track: playbackTrack,
        variant: TrackOptionsVariant.ownTrack,
        onEditTrack: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const UploadTrackScreen(),
              settings: RouteSettings(arguments: track),
            ),
          );
          if (mounted) _loadServerTracks();
        },
        onBehindThisTrack: () => Navigator.of(ctx, rootNavigator: true).push(
          MaterialPageRoute<void>(
            builder: (_) => BehindTheTrackScreen(
              trackId: track.id,
              actorName: track.displayArtist,
              actorAvatarUrl: track.imageUrl ?? '',
              actorUserId: '',
              activityType: 'new_track',
              trackOwnerId: '',
            ),
          ),
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
