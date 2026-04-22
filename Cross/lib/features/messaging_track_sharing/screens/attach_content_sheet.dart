import 'package:cross_team5/features/messaging_track_sharing/services/messaging_api_service.dart';
import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';
import 'package:flutter/material.dart';

const _kBg = Color(0xFF111111);
const _kSurface = Color(0xFF1C1C1C);
const _kOrange = Color(0xFFFF5500);

class AttachContentSheet extends StatefulWidget {
  final String currentUserId;
  final void Function(String link) onSelected;

  const AttachContentSheet({
    super.key,
    required this.currentUserId,
    required this.onSelected,
  });

  @override
  State<AttachContentSheet> createState() => _AttachContentSheetState();
}

class _AttachContentSheetState extends State<AttachContentSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _api = MessagingApiService();

  List<PlaybackTrackModel> _likedTracks = [];
  bool _loadingLikes = true;
  String? _selectedTrackLink;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadLikedTracks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLikedTracks() async {
    try {
      final tracks =
          await _api.getLikedTracks(userId: widget.currentUserId);
      if (!mounted) return;
      setState(() {
        _likedTracks = tracks;
        _loadingLikes = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingLikes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildTabs(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLikesTab(scrollCtrl),
                  _buildEmptyTab('Playlists'),
                  _buildEmptyTab('Albums'),
                  _buildEmptyTab('Uploads'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white70, fontSize: 15)),
          ),
          const Spacer(),
          const Text(
            'Attach content',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _selectedTrackLink != null
                ? () => widget.onSelected(_selectedTrackLink!)
                : null,
            child: Text(
              'Done',
              style: TextStyle(
                color: _selectedTrackLink != null
                    ? _kOrange
                    : Colors.white38,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return TabBar(
      controller: _tabController,
      indicatorColor: Colors.white,
      indicatorWeight: 2,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white38,
      labelStyle:
          const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle:
          const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      tabs: const [
        Tab(text: 'Likes'),
        Tab(text: 'Playlists'),
        Tab(text: 'Albums'),
        Tab(text: 'Uploads'),
      ],
    );
  }

  Widget _buildLikesTab(ScrollController scrollCtrl) {
    if (_loadingLikes) {
      return const Center(
          child: CircularProgressIndicator(color: _kOrange, strokeWidth: 2));
    }

    if (_likedTracks.isEmpty) {
      return const Center(
        child: Text(
          'No liked tracks',
          style: TextStyle(color: Colors.white38, fontSize: 15),
        ),
      );
    }

    return ListView.builder(
      controller: scrollCtrl,
      itemCount: _likedTracks.length,
      itemBuilder: (ctx, i) {
        final track = _likedTracks[i];
        final permalink = track.permalink ?? '';
        final isSelected = _selectedTrackLink == permalink;
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: _TrackThumb(artworkUrl: track.artworkUrl),
          title: Text(
            track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            track.artistName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          trailing: GestureDetector(
            onTap: () => setState(() {
              _selectedTrackLink =
                  isSelected ? null : (permalink.isNotEmpty ? permalink : null);
            }),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? _kOrange : Colors.white38,
                  width: 2,
                ),
                color: isSelected ? _kOrange : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : null,
            ),
          ),
          onTap: () => setState(() {
            _selectedTrackLink =
                isSelected ? null : (permalink.isNotEmpty ? permalink : null);
          }),
        );
      },
    );
  }

  Widget _buildEmptyTab(String label) {
    return Center(
      child: Text(
        'No $label',
        style: const TextStyle(color: Colors.white38, fontSize: 15),
      ),
    );
  }
}

class _TrackThumb extends StatelessWidget {
  final String? artworkUrl;
  const _TrackThumb({this.artworkUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: artworkUrl != null && artworkUrl!.isNotEmpty
          ? Image.network(
              artworkUrl!,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 48,
      height: 48,
      color: _kSurface,
      child: const Icon(Icons.graphic_eq_rounded,
          color: Colors.white24, size: 24),
    );
  }
}
