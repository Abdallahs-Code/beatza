import 'package:cross_team5/features/messaging_track_sharing/services/messaging_api_service.dart';
import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cross_team5/core/theme/app_colors.dart';

class AttachContentSheet extends StatefulWidget {
  final void Function(String link) onSelected;

  const AttachContentSheet({super.key, required this.onSelected});

  @override
  State<AttachContentSheet> createState() => _AttachContentSheetState();
}

class _AttachContentSheetState extends State<AttachContentSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _api = MessagingApiService();
  final _storage = const FlutterSecureStorage();

  List<PlaybackTrackModel> _likedTracks = [];
  bool _loadingLikes = true;

  List<PlaybackTrackModel> _uploadedTracks = [];
  bool _loadingUploads = true;

  String? _selectedTrackLink; 
  String? _selectedArtistId; 
  bool _attachingTrack = false; 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    
    debugPrint(
      '[AttachContentSheet._loadData] Reading userId from secure storage (key="user_id")...',
    );
    final userId = await _storage.read(key: 'user_id') ?? '';
    debugPrint(
      '[AttachContentSheet._loadData] userId="$userId" (empty=${userId.isEmpty})',
    );
    if (userId.isEmpty) {
      debugPrint(
        '[AttachContentSheet._loadData] ❌ userId is EMPTY — cannot load tracks.',
      );
      if (mounted) {
        setState(() {
          _loadingLikes = false;
          _loadingUploads = false;
        });
      }
        
      return;
    }

    
    debugPrint(
      '[AttachContentSheet._loadData] Fetching liked + uploaded tracks for userId=$userId',
    );
    final results = await Future.wait([
      _api
          .getLikedTracks(userId: userId)
          .then((t) {
            debugPrint(
              '[AttachContentSheet._loadData] Liked tracks: ${t.length}',
            );
            return t;
          })
          .catchError((e) {
            debugPrint(
              '[AttachContentSheet._loadData] getLikedTracks ERROR: $e',
            );
            return <PlaybackTrackModel>[];
          }),
      _api
          .getUserPostedTracks(userId: userId)
          .then((t) {
            debugPrint(
              '[AttachContentSheet._loadData] Uploaded tracks: ${t.length}',
            );
            return t;
          })
          .catchError((e) {
            debugPrint(
              '[AttachContentSheet._loadData] getUserPostedTracks ERROR: $e',
            );
            return <PlaybackTrackModel>[];
          }),
    ]);
    if (!mounted) return;
    setState(() {
      _likedTracks = results[0];
      _loadingLikes = false;
      _uploadedTracks = results[1];
      _loadingUploads = false;
    });
  }

  
  
  
  Future<void> _handleDone() async {
    final permalink = _selectedTrackLink!;
    final artistId = _selectedArtistId ?? '';
    debugPrint('━━━ [AttachContentSheet._handleDone] ━━━');
    debugPrint(
      '[AttachContentSheet._handleDone] permalink="$permalink" artistId="$artistId"',
    );

    if (mounted) setState(() => _attachingTrack = true);

    String profileLink = '';
    try {
      if (artistId.isNotEmpty) {
        debugPrint(
          '[AttachContentSheet._handleDone] Fetching profileLink for artistId="$artistId"',
        );
        profileLink = await _api.getUserProfileLink(userId: artistId) ?? '';
        debugPrint(
          '[AttachContentSheet._handleDone] profileLink="$profileLink" (empty=${profileLink.isEmpty})',
        );
        if (profileLink.isEmpty) {
          debugPrint(
            '[AttachContentSheet._handleDone] ⚠️ getUserProfileLink returned null/empty for artistId="$artistId"',
          );
        }
      } else {
        debugPrint(
          '[AttachContentSheet._handleDone] ⚠️ artistId is empty — no posterId on track model. profileLink will be empty.',
        );
      }
    } catch (e) {
      debugPrint(
        '[AttachContentSheet._handleDone] ❌ getUserProfileLink threw: $e',
      );
    }

    
    final payload = 'track::permalink:"$permalink",profilelink:"$profileLink"';
    debugPrint('[AttachContentSheet._handleDone] payload="$payload"');
    if (profileLink.isEmpty) {
      debugPrint(
        '[AttachContentSheet._handleDone] ⚠️ profileLink is empty in payload — receiver may not be able to load the track card',
      );
    }

    if (mounted) {
      setState(() => _attachingTrack = false);
      widget.onSelected(payload);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundDark,
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
                  _buildTrackList(_likedTracks, _loadingLikes, scrollCtrl),
                  _buildEmptyTab('Playlists'),
                  _buildEmptyTab('Albums'),
                  _buildTrackList(_uploadedTracks, _loadingUploads, scrollCtrl),
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
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.white70, fontSize: 15),
            ),
          ),
          const Spacer(),
          Text(
            'Attach content',
            style: TextStyle(
              color: AppColors.whiteSmoke,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: (_selectedTrackLink != null && !_attachingTrack)
                ? () {
                    _handleDone();
                  }
                : null,
            child: _attachingTrack
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: AppColors.primaryOrange,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Done',
                    style: TextStyle(
                      color: _selectedTrackLink != null
                          ? AppColors.primaryOrange
                          : AppColors.white54,
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
      indicatorColor: AppColors.whiteSmoke,
      indicatorWeight: 2,
      labelColor: AppColors.whiteSmoke,
      unselectedLabelColor: AppColors.white54,
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      tabs: const [
        Tab(text: 'Likes'),
        Tab(text: 'Playlists'),
        Tab(text: 'Albums'),
        Tab(text: 'Uploads'),
      ],
    );
  }

  Widget _buildTrackList(
    List<PlaybackTrackModel> tracks,
    bool loading,
    ScrollController scrollCtrl,
  ) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryOrange,
          strokeWidth: 2,
        ),
      );
    }

    if (tracks.isEmpty) {
      return Center(
        child: Text(
          'No tracks',
          style: TextStyle(color: AppColors.white54, fontSize: 15),
        ),
      );
    }

    return ListView.builder(
      controller: scrollCtrl,
      itemCount: tracks.length,
      itemBuilder: (ctx, i) {
        final track = tracks[i];
        final audioLink = track.permalink ?? '';
        final artistId = track.artistId ?? '';
        debugPrint(
          '[AttachContentSheet] track="${track.title}" id="${track.id}" permalink="$audioLink" artistId="$artistId" (posterId)',
        );
        if (artistId.isEmpty) {
          debugPrint(
            '[AttachContentSheet] ⚠️ track "${track.title}" has no artistId — posterId missing from API response',
          );
        }
        final isSelected = _selectedTrackLink == audioLink;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: _TrackThumb(artworkUrl: track.artworkUrl),
          title: Text(
            track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.whiteSmoke,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            track.artistName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.white54, fontSize: 12),
          ),
          trailing: GestureDetector(
            onTap: () => setState(() {
              if (isSelected) {
                _selectedTrackLink = null;
                _selectedArtistId = null;
              } else if (audioLink.isNotEmpty) {
                _selectedTrackLink = audioLink;
                _selectedArtistId = artistId.isNotEmpty ? artistId : null;
                debugPrint(
                  '[AttachContentSheet] Selected (trailing): permalink="$audioLink" artistId="$artistId"',
                );
              }
            }),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryOrange
                      : AppColors.white54,
                  width: 2,
                ),
                color: isSelected
                    ? AppColors.primaryOrange
                    : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check_rounded,
                      color: AppColors.whiteSmoke,
                      size: 14,
                    )
                  : null,
            ),
          ),
          onTap: () => setState(() {
            if (isSelected) {
              _selectedTrackLink = null;
              _selectedArtistId = null;
            } else if (audioLink.isNotEmpty) {
              _selectedTrackLink = audioLink;
              _selectedArtistId = artistId.isNotEmpty ? artistId : null;
              debugPrint(
                '[AttachContentSheet] Selected (onTap): permalink="$audioLink" artistId="$artistId"',
              );
            }
          }),
        );
      },
    );
  }

  Widget _buildEmptyTab(String label) {
    return Center(
      child: Text(
        'No $label',
        style: TextStyle(color: AppColors.white54, fontSize: 15),
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
              errorBuilder: (context, error, _) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 48,
      height: 48,
      color: AppColors.surface,
      child: Icon(Icons.graphic_eq_rounded, color: AppColors.white24, size: 24),
    );
  }
}
