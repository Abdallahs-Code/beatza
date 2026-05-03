import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/sets_playlists/models/playlist_model.dart';
import 'package:cross_team5/features/sets_playlists/services/playlist_api_service.dart';

class CreatePlaylistSheet extends StatefulWidget {
  final void Function(PlaylistModel playlist)? onCreated;

  /// Pre-selected track IDs added to the playlist immediately after creation.
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

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Untitled Playlist');

  bool _isPublic = true;
  bool _isCreating = false;

  // Track IDs that were passed in — added to the playlist right after creation.
  late final List<String> _initialTracks;

  @override
  void initState() {
    super.initState();
    _initialTracks = [
      ...widget.initialTrackIds,
      if (widget.initialTrackId != null) widget.initialTrackId!,
    ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    final (statusCode, playlist) = await _service.createPlaylistWithImage(
      title: _nameController.text.trim(),
      isPrivate: !_isPublic,
      listOfTracks: _initialTracks,
    );

    if (!mounted) return;
    setState(() => _isCreating = false);

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
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
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
              const SizedBox(height: 16),

              // Header row: × title Save
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Create playlist',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _isCreating ? null : _create,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: _isCreating
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black),
                            )
                          : const Text(
                              'Save',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Playlist title field
              Text(
                'Playlist title',
                style: TextStyle(color: AppColors.white54, fontSize: 12),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.transparent,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.white24),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.crusta),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 8),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 28),

              // Make public toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Make public',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500),
                  ),
                  Switch(
                    value: _isPublic,
                    onChanged: (v) => setState(() => _isPublic = v),
                    activeThumbColor: AppColors.crusta,
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
