import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import '../../audio_upload_track_management/models/track.dart' as api_track;
import '../../audio_upload_track_management/models/track_model.dart';
import '../../audio_upload_track_management/services/audio_upload_service.dart';
import '../../audio_upload_track_management/services/track_api_service.dart';
import 'package:provider/provider.dart';
import 'package:cross_team5/core/services/theme_service.dart';
import '../models/spotlight_models.dart';

class YourUploadsSpotlightScreen extends StatefulWidget {
  final List<SpotlightItemModel> selectedItems;
  final String artistName;
  final String userId;

  const YourUploadsSpotlightScreen({
    super.key,
    required this.selectedItems,
    required this.artistName,
    required this.userId,
  });

  @override
  State<YourUploadsSpotlightScreen> createState() =>
      _YourUploadsSpotlightScreenState();
}

class _YourUploadsSpotlightScreenState
    extends State<YourUploadsSpotlightScreen> {
  late List<SpotlightItemModel> localSelected;

  final TrackApiService _trackApiService = TrackApiService();
  late Future<(int, dynamic)> _postedTracksFuture;

  @override
  void initState() {
    super.initState();
    localSelected = List.from(widget.selectedItems);
    _postedTracksFuture = _trackApiService.getUserPostedTracks(
      userId: widget.userId,
    );
  }

  /// Posted tracks from API plus public local uploads (deduped by server id / track id).
  List<SpotlightItemModel> _buildTrackSpotlightItems(List<api_track.Track> apiTracks) {
    final Set<String> seenIds = {};
    final List<SpotlightItemModel> out = [];

    for (final t in apiTracks) {
      final id = t.id.trim();
      if (id.isEmpty) continue;
      seenIds.add(id);
      out.add(SpotlightItemModel.fromPostedTrack(t, widget.artistName));
    }

    for (final t in AudioUploadService.globalMockTracksNotifier.value) {
      final String visibility = t.visibility.toString().toLowerCase();
      if (visibility.contains('private') || visibility.contains('unlisted')) {
        continue;
      }
      final sid = (t.serverId ?? '').trim();
      if (sid.isNotEmpty && seenIds.contains(sid)) continue;
      final localId = t.id.trim();
      if (sid.isEmpty && seenIds.contains(localId)) continue;

      final item = SpotlightItemModel.fromTrack(t, widget.artistName);
      final dedupeKey = sid.isNotEmpty ? sid : item.id;
      if (seenIds.contains(dedupeKey)) continue;
      seenIds.add(dedupeKey);
      out.add(item);
    }

    return out;
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
    return Scaffold(
      backgroundColor: AppColors.backgroundDark3,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark3,
        elevation: 0,
        leading: const SizedBox.shrink(),
        leadingWidth: 0,
        title: Text(
          'Posted tracks',
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
      ),
      body: FutureBuilder<(int, dynamic)>(
        future: _postedTracksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryOrange),
            );
          }
          final result = snapshot.data;
          if (result == null || result.$1 != 200) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  result == null
                      ? 'Could not load posted tracks.'
                      : '${result.$2}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.white54, fontSize: 14),
                ),
              ),
            );
          }
          final apiTracks = result.$2 as List<api_track.Track>;
          return ValueListenableBuilder<List<TrackModel>>(
            valueListenable: AudioUploadService.globalMockTracksNotifier,
            builder: (context, _, _) {
              return _buildList(_buildTrackSpotlightItems(apiTracks));
            },
          );
        },
      ),
    );
  }
}
