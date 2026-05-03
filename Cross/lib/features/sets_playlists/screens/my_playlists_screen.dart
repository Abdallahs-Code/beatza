




import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:cross_team5/core/services/theme_service.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/premium_subscription/services/payment_service.dart';
import 'package:cross_team5/features/sets_playlists/models/playlist_model.dart';
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
  List<PlaylistModel> _filtered = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  static const int _freeUserLimit = 2;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_playlists)
          : _playlists
              .where((p) => p.title.toLowerCase().contains(q))
              .toList();
    });
  }

  Future<void> _loadPlaylists() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final (statusCode, playlists) = await _playlistService.getMyPlaylists();

    if (!mounted) return;

    if (statusCode == 200) {
      setState(() {
        _playlists = playlists;
        _filtered = List.from(playlists);
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
  }

  bool get _isPro => PaymentService.subscriptionSuccessNotifier.value.isPro;
  bool get _atFreeLimit => !_isPro && _playlists.length >= _freeUserLimit;

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
        title: const Text('Upgrade to Pro',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Free users can create up to 2 playlists. Upgrade to Pro for unlimited playlists.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.crusta),
            onPressed: () => Navigator.pop(ctx),
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
      backgroundColor: Colors.transparent,
      builder: (_) => CreatePlaylistSheet(
        onCreated: (PlaylistModel playlist) {
          setState(() {
            _playlists.insert(0, playlist);
            _filtered.insert(0, playlist);
          });
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlaylistDetailScreen(
                playlistId: playlist.id,
                isOwner: true,
              ),
            ),
          ).then((_) => _loadPlaylists());
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

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeService>();
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
          'Playlists',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 26),
            onPressed: _onCreatePlaylist,
            tooltip: 'Create new',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.crusta));
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: _loadPlaylists,
      color: AppColors.crusta,
      child: CustomScrollView(
        slivers: [
          
          SliverToBoxAdapter(child: _buildSearchBar()),

          
          SliverToBoxAdapter(child: _buildCreateButton()),

          
          if (_atFreeLimit)
            SliverToBoxAdapter(child: _buildFreeLimitBanner()),

          
          if (_filtered.isEmpty && _searchController.text.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No playlists matching "${_searchController.text}"',
                    style: const TextStyle(color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else if (_playlists.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyState())
          else
            SliverPadding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: PlaylistCard(
                      playlist: _filtered[index],
                      onTap: () => _onPlaylistTap(_filtered[index]),
                    ),
                  ),
                  childCount: _filtered.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText:
              'Search ${_playlists.length} playlist${_playlists.length == 1 ? '' : 's'}',
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
          prefixIcon:
              const Icon(Icons.search, color: Colors.white38, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close,
                      color: Colors.white38, size: 18),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.cardDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _onCreatePlaylist,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Create new',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: AppColors.borderDark),
            backgroundColor: AppColors.cardDark,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }

  Widget _buildFreeLimitBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.crusta.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: AppColors.crusta, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Free plan: 2 playlist limit reached.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: _showUpgradeDialog,
            style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8)),
            child: const Text('Upgrade',
                style: TextStyle(color: AppColors.crusta, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.queue_music_rounded,
                color: Colors.white24, size: 72),
            const SizedBox(height: 20),
            const Text('No playlists yet',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
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
            const Icon(Icons.error_outline, color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54)),
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
