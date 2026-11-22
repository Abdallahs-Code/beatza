import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/audio_upload_track_management/models/track.dart';
import 'package:cross_team5/features/audio_upload_track_management/services/track_api_service.dart';
import 'package:cross_team5/features/sets_playlists/models/playlist_model.dart';
import 'package:cross_team5/features/sets_playlists/services/playlist_api_service.dart';

class CreatePlaylistSheet extends StatefulWidget {
  final void Function(PlaylistModel playlist)? onCreated;

  /// Pre-selected track IDs (list form, e.g. passed programmatically).
  final List<String> initialTrackIds;

  /// Single pre-selected track ID (e.g. opened from a track's context menu).
  final String? initialTrackId;

  const CreatePlaylistSheet({
    super.key,
    this.onCreated,
    this.initialTrackIds = const [],
    this.initialTrackId,
  });

  @override
  State<CreatePlaylistSheet> createState() => _CreatePlaylistSheetState();
}

class _CreatePlaylistSheetState extends State<CreatePlaylistSheet> {
  final PlaylistApiService _service = PlaylistApiService();
  final TrackApiService _trackService = TrackApiService();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  bool _isPrivate = false;
  bool _isCreating = false;
  String? _imagePath;

  List<Track> _availableTracks = [];
  bool _loadingTracks = true;
  final Set<String> _selectedTrackIds = {};

  @override
  void initState() {
    super.initState();
    _selectedTrackIds.addAll(widget.initialTrackIds);
    if (widget.initialTrackId != null) {
      _selectedTrackIds.add(widget.initialTrackId!);
    }
    _loadTracks();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadTracks() async {
    debugPrint('[CreatePlaylistSheet] loading tracks for pickerΓÇª');
    setState(() => _loadingTracks = true);
    try {
      final (status, data) = await _trackService.getAllTracksPaginated(
        page: 1,
        limit: 30,
      );
      debugPrint('[CreatePlaylistSheet] getAllTracksPaginated status=$status');
      if (status == 200 && data is Map) {
        final tracks = data['tracks'];
        debugPrint('[CreatePlaylistSheet] tracks type: ${tracks.runtimeType}');
        List<Track> parsed = [];
        if (tracks is List<Track>) {
          parsed = tracks;
        } else if (tracks is List) {
          parsed = List<Track>.from(tracks);
        }
        debugPrint('[CreatePlaylistSheet] loaded ${parsed.length} tracks');
        if (mounted) setState(() => _availableTracks = parsed);
      } else {
        debugPrint('[CreatePlaylistSheet] failed to load tracks: status=$status data=$data');
      }
    } catch (e, st) {
      debugPrint('[CreatePlaylistSheet] EXCEPTION loading tracks: $e\n$st');
    } finally {
      if (mounted) setState(() => _loadingTracks = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      debugPrint('[CreatePlaylistSheet] image picked: ${picked.path}');
      setState(() => _imagePath = picked.path);
    }
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTrackIds.isEmpty) {
      debugPrint('[CreatePlaylistSheet] validation failed: no tracks selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least 1 track to your playlist.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final trackIds = _selectedTrackIds.toList();
    debugPrint(
      '[CreatePlaylistSheet] submitting: title="${_nameController.text.trim()}" tracks=$trackIds imagePath=$_imagePath',
    );

    setState(() => _isCreating = true);

    final (statusCode, playlist) = await _service.createPlaylistWithImage(
      title: _nameController.text.trim(),
      description: _descController.text.trim(),
      isPrivate: _isPrivate,
      listOfTracks: trackIds,
      imagePath: _imagePath,
    );

    if (!mounted) return;
    setState(() => _isCreating = false);

    debugPrint(
      '[CreatePlaylistSheet] createPlaylistWithImage result: status=$statusCode playlist=${playlist?.id}',
    );

    if ((statusCode == 200 || statusCode == 201) && playlist != null) {
      widget.onCreated?.call(playlist);
      Navigator.pop(context);
    } else if (statusCode == 403) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Free plan limit reached. Upgrade to Pro for unlimited playlists.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create playlist. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleTrack(String id) {
    setState(() {
      if (_selectedTrackIds.contains(id)) {
        _selectedTrackIds.remove(id);
      } else {
        _selectedTrackIds.add(id);
      }
    });
    debugPrint('[CreatePlaylistSheet] selected tracks: $_selectedTrackIds');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'New Playlist',
                  style: TextStyle(
                    color: AppColors.whiteSmoke,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),

                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _imagePath != null
                              ? AppColors.crusta
                              : AppColors.white24,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _imagePath != null
                          ? Image.file(File(_imagePath!), fit: BoxFit.cover)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: AppColors.white54,
                                  size: 32,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Add cover',
                                  style: TextStyle(
                                    color: AppColors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  style: TextStyle(color: AppColors.whiteSmoke),
                  decoration: InputDecoration(
                    hintText: 'Playlist name',
                    hintStyle: TextStyle(color: AppColors.white54),
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.crusta),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _descController,
                  style: TextStyle(color: AppColors.whiteSmoke),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Description (optional)',
                    hintStyle: TextStyle(color: AppColors.white54),
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.crusta),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Text(
                      'Add Tracks',
                      style: TextStyle(
                        color: AppColors.whiteSmoke,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedTrackIds.length} selected',
                      style: TextStyle(color: AppColors.white54, fontSize: 13),
                    ),
                    if (_selectedTrackIds.isEmpty)
                      Text(
                        ' (required)',
                        style: TextStyle(color: Colors.redAccent, fontSize: 13),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildTrackPicker(),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Secret playlist',
                      style:
                          TextStyle(color: AppColors.whiteSmoke, fontSize: 15),
                    ),
                    Switch(
                      value: _isPrivate,
                      onChanged: (v) => setState(() => _isPrivate = v),
                      activeThumbColor: AppColors.crusta,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isCreating ? null : _create,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.crusta,
                      foregroundColor: AppColors.whiteSmoke,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isCreating
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.whiteSmoke,
                            ),
                          )
                        : const Text(
                            'Create Playlist',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackPicker() {
    if (_loadingTracks) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_availableTracks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No tracks found. Upload a track first.',
          style: TextStyle(color: AppColors.white54, fontSize: 13),
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: _availableTracks.length,
        itemBuilder: (_, i) {
          final track = _availableTracks[i];
          final selected = _selectedTrackIds.contains(track.id);
          return InkWell(
            onTap: () => _toggleTrack(track.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: track.imageUrl != null
                        ? Image.network(
                            track.imageUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, st) => _trackPlaceholder(),
                          )
                        : _trackPlaceholder(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.whiteSmoke,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          track.displayArtist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Checkbox(
                    value: selected,
                    onChanged: (_) => _toggleTrack(track.id),
                    activeColor: AppColors.crusta,
                    checkColor: AppColors.whiteSmoke,
                    side: BorderSide(color: AppColors.white54),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _trackPlaceholder() {
    return Container(
      width: 40,
      height: 40,
      color: AppColors.cardDark,
      child: Icon(Icons.music_note, color: AppColors.white54, size: 20),
    );
  }
}
