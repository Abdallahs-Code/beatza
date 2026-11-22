




import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:provider/provider.dart';
import 'package:cross_team5/core/services/theme_service.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/sets_playlists/models/playlist_model.dart';
import 'package:cross_team5/features/sets_playlists/services/playlist_api_service.dart';
import 'package:cross_team5/features/sets_playlists/widgets/playlist_track_tile.dart';
import 'package:cross_team5/features/sets_playlists/playlist_playback.dart';

class EditPlaylistScreen extends StatefulWidget {
  final PlaylistModel playlist;
  final List<PlaylistTrack> tracks;

  const EditPlaylistScreen({
    super.key,
    required this.playlist,
    this.tracks = const [],
  });

  @override
  State<EditPlaylistScreen> createState() => _EditPlaylistScreenState();
}

class _EditPlaylistScreenState extends State<EditPlaylistScreen>
    with SingleTickerProviderStateMixin {
  final PlaylistApiService _service = PlaylistApiService();
  final _formKey = GlobalKey<FormState>();
  late final TabController _tabController;

  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _genreController;

  late List<PlaylistTrack> _tracks;

  bool _isPrivate = false;
  bool _isSaving = false;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tracks = List.from(widget.tracks);

    final p = widget.playlist;
    _titleController = TextEditingController(text: p.title);
    _descController = TextEditingController(text: p.description);
    _genreController = TextEditingController(text: p.genre);
    _isPrivate = p.isPrivate;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _genreController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  Future<void> _save() async {
    // currentState is null when the Details tab hasn't been rendered yet
    // (user is on the Tracks tab). Skip validation in that case.
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final (statusCode, message) = await _service.updatePlaylist(
      playlistId: widget.playlist.id,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      genre: _genreController.text.trim(),
      isPrivate: _isPrivate,
      imagePath: _pickedImage?.path,
      permalink: widget.playlist.permalink,
      listOfTracks: _tracks.map((t) => t.id).toList(),
      additionalTags: widget.playlist.additionalTags,
      playlistType: widget.playlist.playlistType,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playlist updated successfully.')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.deepRed),
      );
    }
  }

  Future<void> _playTrackAt(int index) async {
    await playPlaylistTracksAt(
      context,
      _tracks,
      index,
      playlistArtistId: widget.playlist.artistId,
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final track = _tracks[oldIndex];
    setState(() {
      _tracks.removeAt(oldIndex);
      _tracks.insert(newIndex, track);
    });
    _service.reorderTrack(
      playlistId: widget.playlist.id,
      trackId: track.id,
      oldPosition: oldIndex,
      newPosition: newIndex,
    );
  }

  Future<void> _removeTrack(PlaylistTrack track) async {
    final index = _tracks.indexOf(track);
    setState(() => _tracks.remove(track));

    final (code, _) = await _service.removeTrackFromPlaylist(
      playlistId: widget.playlist.id,
      trackId: track.id,
    );

    if (!mounted) return;
    if (code != 200) {
      setState(() => _tracks.insert(index, track));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to remove track'),
            backgroundColor: Colors.red),
      );
    }
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
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Playlist',
          style:
              TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.crusta),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.crusta,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.crusta,
          unselectedLabelColor: Colors.white54,
          indicatorColor: AppColors.crusta,
          tabs: const [
            Tab(text: 'Tracks'),
            Tab(text: 'Details'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTracksTab(),
          _buildDetailsTab(),
        ],
      ),
    );
  }

  Widget _buildTracksTab() {
    if (_tracks.isEmpty) {
      return const Center(
        child: Text(
          'No tracks yet.\nAdd music from the playlist screen.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _tracks.length,
      itemBuilder: (context, index) {
        final track = _tracks[index];
        return Padding(
          key: ValueKey(track.id),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          child: PlaylistTrackTile(
            track: track,
            showDragHandle: true,
            showOptions: true,
            playlistOwnerArtistId: widget.playlist.artistId,
            onTap: () => _playTrackAt(index),
            onRemove: () => _removeTrack(track),
          ),
        );
      },
      onReorder: _onReorder,
      proxyDecorator: (child, index, animation) => Material(
        color: Colors.transparent,
        elevation: 4,
        child: child,
      ),
    );
  }

  Widget _buildDetailsTab() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _pickedImage != null
                        ? Image.file(_pickedImage!,
                            width: 160, height: 160, fit: BoxFit.cover)
                        : (widget.playlist.image?.imgLink.isNotEmpty == true
                            ? Image.network(
                                widget.playlist.image!.imgLink,
                                width: 160,
                                height: 160,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, st) =>
                                    _placeholderArt(),
                              )
                            : _placeholderArt()),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.crusta,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _pickImage,
              child: const Text('Change Image',
                  style: TextStyle(color: AppColors.crusta)),
            ),
          ),
          const SizedBox(height: 20),

          _buildLabel('Title *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Playlist title'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Title is required' : null,
          ),
          const SizedBox(height: 20),

          _buildLabel('Description'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Optional description'),
            maxLines: 3,
          ),
          const SizedBox(height: 20),

          _buildLabel('Genre'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _genreController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('e.g. Electronic, Hip-Hop'),
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isPrivate ? 'Secret playlist' : 'Public playlist',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isPrivate
                        ? 'Shareable only via secret link'
                        : 'Visible on your profile',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              Switch(
                value: _isPrivate,
                onChanged: (v) => setState(() => _isPrivate = v),
                activeThumbColor: AppColors.crusta,
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: AppColors.cardDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.crusta),
      ),
    );
  }

  Widget _placeholderArt() {
    return Container(
      width: 160,
      height: 160,
      color: AppColors.cardDark,
      child:
          const Icon(Icons.queue_music, color: Colors.white24, size: 60),
    );
  }
}
