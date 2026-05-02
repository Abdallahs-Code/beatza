import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import '../../audio_upload_track_management/models/track_model.dart';
import '../../audio_upload_track_management/services/audio_upload_service.dart';
import 'package:provider/provider.dart';
import 'package:cross_team5/core/services/theme_service.dart';
import '../models/spotlight_models.dart';

class YourUploadsSpotlightScreen extends StatefulWidget {
  final List<SpotlightItemModel> selectedItems;
  final String artistName;

  const YourUploadsSpotlightScreen({
    super.key,
    required this.selectedItems,
    required this.artistName,
  });

  @override
  State<YourUploadsSpotlightScreen> createState() =>
      _YourUploadsSpotlightScreenState();
}

class _YourUploadsSpotlightScreenState
    extends State<YourUploadsSpotlightScreen> {
  late List<SpotlightItemModel> localSelected;

  final List<SpotlightItemModel> mockAlbums = [
    SpotlightItemModel(
      id: 'a1',
      title: 'Summer Vibes Album',
      subtitle: 'ozOo',
      type: SpotlightType.album,
      imageUrl:
          'https://images.unsplash.com/photo-1511367461989-f85a21fda167?q=80&w=300&auto=format&fit=crop',
    ),
    SpotlightItemModel(
      id: 'a2',
      title: 'Deep House Mixes',
      subtitle: 'ozOo',
      type: SpotlightType.album,
      imageUrl:
          'https://images.unsplash.com/photo-1510915361894-db8b60106cb1?q=80&w=300&auto=format&fit=crop',
    ),
  ];

  final List<SpotlightItemModel> mockPlaylists = [
    SpotlightItemModel(
      id: 'p1',
      title: 'Top Hits Playlist',
      subtitle: 'ozOo',
      type: SpotlightType.playlist,
      imageUrl:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?q=80&w=300&auto=format&fit=crop',
    ),
    SpotlightItemModel(
      id: 'p2',
      title: 'Workout Energy',
      subtitle: 'ozOo',
      type: SpotlightType.playlist,
      imageUrl:
          'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=300&auto=format&fit=crop',
    ),
  ];

  @override
  void initState() {
    super.initState();
    localSelected = List.from(widget.selectedItems);
  }

  void _toggleItem(SpotlightItemModel item) {
    setState(() {
      if (localSelected.any((e) => e.id == item.id)) {
        localSelected.removeWhere((e) => e.id == item.id);
      } else {
        if (localSelected.length < 5) {
          localSelected.add(item);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can only pin up to 5 items.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
  }

  Widget _buildList(List<SpotlightItemModel> items) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Nothing found',
          style: TextStyle(color: AppColors.white54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = localSelected.any((e) => e.id == item.id);

        return InkWell(
          onTap: () => _toggleItem(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? (item.imageUrl!.startsWith('http')
                            ? Image.network(
                                item.imageUrl!,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(item.imageUrl!),
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                              ))
                      : Container(
                          width: 52,
                          height: 52,
                          color: AppColors.tileDark,
                          child: Icon(
                            Icons.music_note,
                            color: AppColors.whiteSmoke,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          color: AppColors.whiteSmoke,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          color: AppColors.white54,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '▶ 0',
                        style: TextStyle(
                          color: AppColors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSelected ? Icons.push_pin : Icons.push_pin_outlined,
                  color: isSelected ? AppColors.whiteSmoke : AppColors.white54,
                  size: 22,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeService>();
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark3,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundDark3,
          elevation: 0,
          leading: const SizedBox.shrink(),
          leadingWidth: 0,
          title: Text(
            'Your Uploads',
            style: TextStyle(
              color: AppColors.whiteSmoke,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, localSelected);
              },
              child: Text(
                'Done',
                style: TextStyle(color: AppColors.whiteSmoke, fontSize: 16),
              ),
            ),
          ],
          bottom: TabBar(
            indicatorColor: AppColors.whiteSmoke,
            labelColor: AppColors.whiteSmoke,
            unselectedLabelColor: AppColors.white54,
            indicatorWeight: 2,
            tabs: [
              Tab(text: 'Tracks'),
              Tab(text: 'Albums'),
              Tab(text: 'Playlists'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ValueListenableBuilder<List<TrackModel>>(
              valueListenable: AudioUploadService.globalMockTracksNotifier,
              builder: (context, tracks, child) {
                final publicTracks = tracks
                    .where((t) {
                      String visibility = t.visibility.toString().toLowerCase();
                      return !visibility.contains('private') &&
                          !visibility.contains('unlisted');
                    })
                    .map(
                      (t) => SpotlightItemModel.fromTrack(t, widget.artistName),
                    )
                    .toList();

                return _buildList(publicTracks);
              },
            ),
            _buildList(mockAlbums),
            _buildList(mockPlaylists),
          ],
        ),
      ),
    );
  }
}
