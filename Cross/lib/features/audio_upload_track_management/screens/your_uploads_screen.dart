import 'dart:io';
import 'package:flutter/material.dart';
import '../widgets/smart_player_widget.dart';
import 'upload_track_screen.dart';
import '../services/audio_upload_service.dart';
import '../models/track_model.dart';

enum SortOption { recentlyAdded, firstAdded, trackName }
enum FilterOption { all, public, private }

class YourUploadsScreen extends StatefulWidget {
  const YourUploadsScreen({super.key});

  @override
  State<YourUploadsScreen> createState() => _YourUploadsScreenState();
}

class _YourUploadsScreenState extends State<YourUploadsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  SortOption _currentSort = SortOption.recentlyAdded;
  FilterOption _currentFilter = FilterOption.all;

  TrackModel? _currentlyPlayingTrack;
  final Set<String> _likedTrackIds = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _playTrack(TrackModel track) {
    if (_currentlyPlayingTrack?.id == track.id) {
      return;
    }
    setState(() {
      _currentlyPlayingTrack = track;
    });
  }

  List<TrackModel> _getFilteredAndSortedTracks(List<TrackModel> allTracks) {
    var filtered = allTracks.where((t) => t.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    if (_currentFilter == FilterOption.public) {
      filtered = filtered.where((t) => t.visibility == TrackVisibility.public).toList();
    } else if (_currentFilter == FilterOption.private) {
      filtered = filtered.where((t) => t.visibility != TrackVisibility.public).toList();
    }

    if (_currentSort == SortOption.recentlyAdded) {
      filtered.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
    } else if (_currentSort == SortOption.trackName) {
      filtered.sort((a, b) => a.title.compareTo(b.title));
    }
    return filtered;
  }

  void _showFilterMenu(BuildContext context) async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset position = button.localToGlobal(Offset.zero, ancestor: overlay);

    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy + 50, 16, 0),
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: <PopupMenuEntry<String>>[
        _buildPopupMenuItem('recent', 'Recently added', _currentSort == SortOption.recentlyAdded),
        _buildPopupMenuItem('track', 'Track name', _currentSort == SortOption.trackName),
        const PopupMenuDivider(height: 1),
        _buildPopupMenuItem('all', 'All', _currentFilter == FilterOption.all),
        _buildPopupMenuItem('pub', 'Public', _currentFilter == FilterOption.public),
        _buildPopupMenuItem('priv', 'Private', _currentFilter == FilterOption.private),
      ],
    );

    if (result != null) {
      setState(() {
        if (result == 'recent') _currentSort = SortOption.recentlyAdded;
        if (result == 'track') _currentSort = SortOption.trackName;
        if (result == 'all') _currentFilter = FilterOption.all;
        if (result == 'pub') _currentFilter = FilterOption.public;
        if (result == 'priv') _currentFilter = FilterOption.private;
      });
    }
  }

  PopupMenuItem<String> _buildPopupMenuItem(String value, String title, bool isSelected) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          SizedBox(width: 24, child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
        ],
      ),
    );
  }

  void _showArtistToolsBottomSheet(BuildContext context, TrackModel track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                const Text('Artist Tools', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildToolCard(Icons.flash_on, const Color(0xFFD47AFA), 'Amplify', 'TRY IT', () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Amplify requires Artist Pro subscription'), backgroundColor: Color(0xFF8A2BE2)));
                    })),
                    const SizedBox(width: 12),
                    Expanded(child: _buildToolCard(Icons.cloud_upload, const Color(0xFF4A90E2), 'Upload time', '0/120 mins used', () {
                      Navigator.pop(context);
                    })),
                    const SizedBox(width: 12),
                    Expanded(child: _buildToolCard(Icons.sync_alt, const Color(0xFF4A90E2), 'Replace file', 'TRY IT', () async {
                      Navigator.pop(context);
                      final newFile = await AudioUploadService().pickAudioFile();
                      if (newFile != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File replaced with: ${newFile.name}'), backgroundColor: Colors.green));
                      }
                    })),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolCard(IconData icon, Color iconColor, String title, String subtitle, VoidCallback onTap) {
    bool isPro = title == 'Amplify' || title == 'Replace file';

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isPro ? 0.4 : 1.0,
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: isPro ? Border.all(color: Colors.white10) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isPro ? Colors.grey : iconColor, size: 32),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.white24, fontSize: 10)),
            ],
          ),
        ),
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
              builder: (context, allTracks, child) {
                final tracks = _getFilteredAndSortedTracks(allTracks);
                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      backgroundColor: const Color(0xFF0A0A0A),
                      expandedHeight: 120.0, pinned: true,
                      leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          children: [
                            Positioned(top: -80, right: -50, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFF8A2BE2).withOpacity(0.4), Colors.transparent])))),
                          ],
                        ),
                      ),
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(60),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                  child: Container(
                                      height: 40,
                                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                                      child: TextField(
                                          controller: _searchController,
                                          onChanged: (v) => setState(() => _searchQuery = v),
                                          style: const TextStyle(color: Colors.white),
                                          decoration: const InputDecoration(
                                              hintText: 'Search tracks',
                                              prefixIcon: Icon(Icons.search, color: Colors.white54),
                                              border: InputBorder.none
                                          )
                                      )
                                  )
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(onTap: () => _showFilterMenu(context), child: const Icon(Icons.tune, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Your uploads', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const UploadTrackScreen()))),
                                GestureDetector(
                                  onTap: () {
                                    if (tracks.isNotEmpty) _playTrack(tracks.first);
                                  },
                                  child: Container(width: 44, height: 44, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.play_arrow, color: Colors.black)),
                                )
                              ],
                            ),
                            const SizedBox(height: 20),
                            Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(6)), child: const Center(child: Text('View remaining Artist tools credits →', style: TextStyle(color: Colors.white, fontSize: 13)))),
                          ],
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final track = tracks[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: Container(width: 50, height: 50, decoration: BoxDecoration(color: const Color(0xFF1C1C1C), borderRadius: BorderRadius.circular(4)), child: track.coverImagePath != null ? ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.file(File(track.coverImagePath!), fit: BoxFit.cover)) : const Icon(Icons.music_note, color: Colors.white24)),
                            title: Text(track.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text('Belal Elseddik • ${track.visibility.name}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            trailing: IconButton(icon: const Icon(Icons.more_horiz, color: Colors.white54), onPressed: () => _showArtistToolsBottomSheet(context, track)),
                            onTap: () => _playTrack(track),
                          );
                        },
                        childCount: tracks.length,
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
                    ),
                  ],
                );
              },
            ),
            if (_currentlyPlayingTrack != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: SafeArea(
                  child: SmartWaveformPlayer(
                    track: _currentlyPlayingTrack!,
                    onClose: () {
                      setState(() {
                        _currentlyPlayingTrack = null;
                      });
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}