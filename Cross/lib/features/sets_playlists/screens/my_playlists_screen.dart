// Screen: MyPlaylistsScreen
// Shows the current user's playlists (API #15).
// Allows creating new playlists (API #19) via FAB.
// Navigates to PlaylistDetailScreen on tap.
// Free users capped at 2 playlists — FAB disabled + banner shown.

import 'package:flutter/material.dart';

import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/premium_subscription/services/payment_service.dart';
import 'package:cross_team5/features/sets_playlists/models/playlist_model.dart';
import 'package:cross_team5/features/sets_playlists/screens/edit_playlist_screen.dart';
import 'package:cross_team5/features/sets_playlists/screens/playlist_detail_screen.dart';
import 'package:cross_team5/features/sets_playlists/services/playlist_api_service.dart';
import 'package:cross_team5/features/sets_playlists/widgets/playlist_card.dart';
import 'package:cross_team5/features/sets_playlists/widgets/create_playlist_sheet.dart';

class MyPlaylistsScreen extends StatefulWidget {
  const MyPlaylistsScreen({super.key});

  @override
  State<MyPlaylistsScreen> createState() => _MyPlaylistsScreenState();
}

class _MyPlaylistsScreenState extends State<MyPlaylistsScreen> {
  final PlaylistApiService _playlistService = PlaylistApiService();

  List<PlaylistModel> _playlists = [];
  bool _isLoading = true;
  String? _error;

  static const int _freeUserLimit = 2;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadPlaylists() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final (statusCode, playlists) =
          await _playlistService.getMyPlaylists();

      debugPrint("GET /api/playlists/v1/my-playlists -> $statusCode");

      if (!mounted) return;

      if (statusCode == 200) {
        setState(() {
          _playlists = playlists.where((p) => !p.isAlbum).toList();
          _isLoading = false;
        });
      } else if (statusCode == 401) {
        setState(() {
          _error = 'Please sign in to view your playlists.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load playlists. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  bool get _isPro {
    final state = PaymentService.subscriptionSuccessNotifier.value;
    return state.isPro;
  }

  bool get _atFreeLimit =>
      !_isPro && _playlists.length >= _freeUserLimit;

  void _onCreatePlaylist() {
    if (_atFreeLimit) {
      _showUpgradeDialog();
      return;
    }
    _showCreateSheet();
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          'Upgrade to Pro',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Free users can create up to 2 playlists. Upgrade to Pro for unlimited playlists.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.crusta),
            onPressed: () {
              Navigator.pop(ctx);
              // Navigate to premium screen
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CreatePlaylistSheet(
        onCreated: (PlaylistModel playlist) {
          setState(() {
            _playlists.insert(0, playlist);
          });
        },
      ),
    );
  }

  void _onPlaylistTap(PlaylistModel playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaylistDetailScreen(
          playlistId: playlist.id,
          isOwner: true,
        ),
      ),
    ).then((_) => _loadPlaylists());
  }

  void _onEditPlaylist(PlaylistModel playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditPlaylistScreen(playlist: playlist),
      ),
    ).then((updated) {
      if (updated == true) _loadPlaylists();
    });
  }

  Future<void> _onDeletePlaylist(PlaylistModel playlist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Delete Playlist',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete "${playlist.title}"? This cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final (statusCode, deleted) =
        await _playlistService.deletePlaylist(playlistId: playlist.id);

    if (!mounted) return;
    if (statusCode == 200 && deleted) {
      setState(() => _playlists.removeWhere((p) => p.id == playlist.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playlist deleted.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete playlist. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      appBar: AppBar(
        backgroundColor: AppColors.pureBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Your Playlists',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onCreatePlaylist,
        backgroundColor:
            _atFreeLimit ? Colors.grey : AppColors.crusta,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.crusta),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_playlists.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadPlaylists,
      color: AppColors.crusta,
      child: CustomScrollView(
        slivers: [
          if (_atFreeLimit)
            SliverToBoxAdapter(
              child: _buildFreeLimitBanner(),
            ),
          SliverPadding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PlaylistCard(
                    playlist: _playlists[index],
                    onTap: () => _onPlaylistTap(_playlists[index]),
                    onMenuEdit: () => _onEditPlaylist(_playlists[index]),
                    onMenuDelete: () => _onDeletePlaylist(_playlists[index]),
                  ),
                ),
                childCount: _playlists.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildFreeLimitBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.crusta.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline,
              color: AppColors.crusta, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Free plan: 2 playlist limit reached. Upgrade to Pro for unlimited playlists.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: _showUpgradeDialog,
            child: const Text('Upgrade',
                style: TextStyle(color: AppColors.crusta)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.queue_music_rounded,
              color: Colors.white38,
              size: 72,
            ),
            const SizedBox(height: 20),
            const Text(
              'No playlists yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Create your first playlist and start adding tracks.',
              style: TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.crusta,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: _onCreatePlaylist,
              icon: const Icon(Icons.add),
              label: const Text('Create Playlist',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadPlaylists,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.crusta,
                  foregroundColor: Colors.white),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
