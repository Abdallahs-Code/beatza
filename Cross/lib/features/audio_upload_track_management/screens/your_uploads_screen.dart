import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/audio_upload_service.dart';
import '../models/track_model.dart';
import '../audio_upload_track_management_routes.dart';

class YourUploadsScreen extends StatefulWidget {
  const YourUploadsScreen({super.key});

  @override
  State<YourUploadsScreen> createState() => _YourUploadsScreenState();
}

class _YourUploadsScreenState extends State<YourUploadsScreen> {
  String _searchQuery = "";

  final AudioPlayer _audioPlayer = AudioPlayer();
  TrackModel? _currentlyPlayingTrack;
  bool _isPlaying = false;
  final Set<String> _likedTrackIds = {};

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playTrack(TrackModel track) async {
    if (_currentlyPlayingTrack?.id == track.id) {
      _togglePlayPause();
      return;
    }

    setState(() {
      _currentlyPlayingTrack = track;
    });

    if (track.audioUrl.isNotEmpty) {
      await _audioPlayer.play(DeviceFileSource(track.audioUrl));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio file not found!'), backgroundColor: Colors.red),
      );
    }
  }

  void _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  void _closePlayer() async {
    await _audioPlayer.stop();
    setState(() {
      _currentlyPlayingTrack = null;
      _isPlaying = false;
    });
  }

  void _toggleLike(String trackId) {
    setState(() {
      if (_likedTrackIds.contains(trackId)) {
        _likedTrackIds.remove(trackId);
      } else {
        _likedTrackIds.add(trackId);
      }
    });
  }

  void _showTrackOptions(BuildContext context, TrackModel track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(4)),
                    child: track.coverImagePath != null && track.coverImagePath!.isNotEmpty
                        ? ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.file(File(track.coverImagePath!), fit: BoxFit.cover))
                        : const Icon(Icons.music_note, color: Colors.white54),
                  ),
                  title: Text(track.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(track.genre.isEmpty ? 'Unknown Genre' : track.genre, style: const TextStyle(color: Colors.white54)),
                ),
                const Divider(color: Colors.white10),
                ListTile(
                  leading: const Icon(Icons.share_outlined, color: Colors.white),
                  title: const Text('Share', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share link copied!')));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: Colors.white),
                  title: const Text('Edit Track', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDialog(track);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteTrack(track);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditDialog(TrackModel track) {
    TextEditingController titleCtrl = TextEditingController(text: track.title);
    TextEditingController genreCtrl = TextEditingController(text: track.genre);

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1C1C1C),
            title: const Text('Edit Track', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: genreCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Genre',
                    labelStyle: TextStyle(color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5500)),
                onPressed: () {
                  _updateTrackData(track.id, titleCtrl.text, genreCtrl.text);
                  Navigator.pop(context);
                },
                child: const Text('Save', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
    );
  }

  void _updateTrackData(String id, String newTitle, String newGenre) {
    final currentList = List<TrackModel>.from(AudioUploadService.globalMockTracksNotifier.value);
    final index = currentList.indexWhere((t) => t.id == id);

    if (index != -1) {
      final oldTrack = currentList[index];
      final updatedTrack = TrackModel(
        id: oldTrack.id, title: newTitle, genre: newGenre, descriptiveTags: oldTrack.descriptiveTags,
        releaseDate: oldTrack.releaseDate, fileFormat: oldTrack.fileFormat, processingState: oldTrack.processingState,
        visibility: oldTrack.visibility, audioUrl: oldTrack.audioUrl, waveformPeaks: oldTrack.waveformPeaks,
        description: oldTrack.description, caption: oldTrack.caption, recordLabel: oldTrack.recordLabel,
        publisher: oldTrack.publisher, isrc: oldTrack.isrc, containsExplicitContent: oldTrack.containsExplicitContent,
        pLine: oldTrack.pLine, enableDirectDownloads: oldTrack.enableDirectDownloads, offlineListening: oldTrack.offlineListening,
        includeInRssFeed: oldTrack.includeInRssFeed, displayEmbedCode: oldTrack.displayEmbedCode, enableAppPlayback: oldTrack.enableAppPlayback,
        availability: oldTrack.availability, licensing: oldTrack.licensing, coverImagePath: oldTrack.coverImagePath,
      );

      currentList[index] = updatedTrack;
      AudioUploadService.globalMockTracksNotifier.value = currentList;

      if (_currentlyPlayingTrack?.id == id) {
        setState(() => _currentlyPlayingTrack = updatedTrack);
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Track updated!'), backgroundColor: Colors.green));
    }
  }

  void _deleteTrack(TrackModel track) {
    final currentList = List<TrackModel>.from(AudioUploadService.globalMockTracksNotifier.value);
    currentList.removeWhere((t) => t.id == track.id);
    AudioUploadService.globalMockTracksNotifier.value = currentList;

    if (_currentlyPlayingTrack?.id == track.id) {
      _closePlayer();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Track deleted successfully'), backgroundColor: Colors.redAccent, duration: Duration(seconds: 2)),
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

                final tracks = _searchQuery.isEmpty
                    ? allTracks
                    : allTracks.where((t) => t.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      backgroundColor: const Color(0xFF1A0B2E),
                      expandedHeight: 130.0,
                      pinned: true,
                      leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF3B1D60), Color(0xFF0A0A0A)],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                          ),
                        ),
                      ),
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(60),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: TextField(
                              onChanged: (val) {
                                setState(() => _searchQuery = val);
                              },
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Search ${allTracks.length} tracks',
                                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
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
                            const SizedBox(height: 24),

                            if (allTracks.isEmpty) ...[
                              const Text('No uploads yet', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              const Text('Your uploads will show up here.', style: TextStyle(color: Colors.white54, fontSize: 14)),
                            ],

                            if (allTracks.isNotEmpty && tracks.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 20),
                                child: Center(child: Text('No tracks match your search.', style: TextStyle(color: Colors.white54))),
                              ),

                            if (allTracks.isEmpty)
                              const SizedBox(height: 24),

                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, AudioUploadRoutes.uploadTrack),
                              child: const Row(
                                children: [
                                  Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 24),
                                  SizedBox(width: 16),
                                  Text('Upload a track', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),

                    if (tracks.isNotEmpty)
                      SliverPadding(
                        padding: EdgeInsets.only(bottom: _currentlyPlayingTrack != null ? 100 : 40),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                                (context, index) {
                              final track = tracks[index];
                              bool isThisTrackPlaying = _currentlyPlayingTrack?.id == track.id;

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                leading: Container(
                                  width: 50, height: 50,
                                  decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(4)),
                                  child: track.coverImagePath != null && track.coverImagePath!.isNotEmpty
                                      ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.file(File(track.coverImagePath!), fit: BoxFit.cover, width: 50, height: 50, errorBuilder: (_,__,___) => const Icon(Icons.music_note, color: Colors.white54)),
                                  )
                                      : const Icon(Icons.music_note, color: Colors.white54),
                                ),
                                title: Text(track.title, style: TextStyle(color: isThisTrackPlaying ? const Color(0xFFFF5500) : Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Text('${track.visibility.name} • ${track.fileFormat}', style: const TextStyle(color: Colors.white54), maxLines: 1, overflow: TextOverflow.ellipsis),
                                trailing: IconButton(
                                  icon: const Icon(Icons.more_vert, color: Colors.white54),
                                  onPressed: () => _showTrackOptions(context, track),
                                ),
                                onTap: () => _playTrack(track),
                              );
                            },
                            childCount: tracks.length,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),

            if (_currentlyPlayingTrack != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildMiniPlayer(_currentlyPlayingTrack!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPlayer(TrackModel track) {
    bool isLiked = _likedTrackIds.contains(track.id);

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(4)),
            child: track.coverImagePath != null && track.coverImagePath!.isNotEmpty
                ? ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.file(File(track.coverImagePath!), fit: BoxFit.cover))
                : const Icon(Icons.music_note, color: Colors.white54),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(track.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                const Text('You', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),

          IconButton(
            icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? const Color(0xFFFF5500) : Colors.white),
            onPressed: () => _toggleLike(track.id),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 28),
            onPressed: _togglePlayPause,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54, size: 20),
            onPressed: _closePlayer,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}