import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/audio_upload_service.dart';
class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  DashedRectPainter({this.color = Colors.white, this.strokeWidth = 1.0, this.gap = 5.0});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = color..strokeWidth = strokeWidth..style = PaintingStyle.stroke;
    var path = Path();
    path.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(8)));
    PathMetrics pathMetrics = path.computeMetrics();
    for (PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        canvas.drawPath(pathMetric.extractPath(distance, distance + gap), paint);
        distance += gap * 2;
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class UploadTrackScreen extends StatefulWidget {
  const UploadTrackScreen({super.key});

  @override
  State<UploadTrackScreen> createState() => _UploadTrackScreenState();
}

class _UploadTrackScreenState extends State<UploadTrackScreen> {
  final TextEditingController _artistInputController = TextEditingController();
  List<String> _artists = ['BELAL ELSEDDIK', 'SHREK'];
  final AudioUploadService _audioService = AudioUploadService();
  int _currentTabIndex = 0;
  bool _isSaving = false;

  PlatformFile? _selectedFile;
  String? _selectedFileName;
  int _uploadProgress = 0;
  bool _isUploading = false;
  bool _uploadComplete = false;
  StreamSubscription<int>? _uploadSubscription;
  PlatformFile? _coverImage;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _genreController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  String _privacy = 'unlisted';
  bool _scheduleRelease = false;
  DateTime _scheduleDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _scheduleTime = TimeOfDay.now();
  String _recordLabel = '';
  bool _enableReleaseDate = false;
  DateTime _releaseDate = DateTime.now();
  String _publisher = '';
  String _isrc = '';
  bool _containsExplicitContent = false;
  String _pLine = '';
  bool _enableDirectDownloads = false;
  bool _offlineListening = true;
  bool _includeInRssFeed = true;
  bool _displayEmbedCode = false;
  bool _enableAppPlayback = true;
  String _availability = 'worldwide';
  String _licensing = 'all_rights';
  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _pickCoverImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _coverImage = result.files.single;
      });
    }
  }

  void _pickAndUploadFile() async {
    final file = await _audioService.pickAudioFile();
    if (file != null) {
      setState(() {
        _selectedFile = file;
        _selectedFileName = file.name;
        _titleController.text = file.name.replaceAll(RegExp(r'\.(mp3|wav|flac|aac)$', caseSensitive: false), '');
        _isUploading = true;
        _uploadComplete = false;
        _uploadProgress = 0;
      });

      _uploadSubscription = _audioService.mockUploadStream().listen((progress) {
        setState(() => _uploadProgress = progress);
      }, onDone: () {
        setState(() {
          _isUploading = false;
          _uploadComplete = true;
        });
      });
    }
  }

  void _cancelUpload() {
    _uploadSubscription?.cancel();
    setState(() {
      _selectedFile = null;
      _selectedFileName = null;
      _isUploading = false;
      _uploadComplete = false;
      _uploadProgress = 0;
      _titleController.clear();
    });
  }

  Future<void> _selectDate(BuildContext context, DateTime initialDate, Function(DateTime) onDateSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF1DB954),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _scheduleTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF1DB954),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _scheduleTime = picked;
      });
    }
  }

  void _saveTrack() async {
    if (_selectedFile == null || !_uploadComplete) return;

    setState(() => _isSaving = true);
    final metadata = {
      'title': _titleController.text, 'genre': _genreController.text, 'description': _descriptionController.text,
      'caption': _captionController.text, 'tags': _tagsController.text, 'visibility': _privacy,
      'coverImagePath': _coverImage?.path,
      'isScheduled': _scheduleRelease, 'scheduleDate': _scheduleRelease ? _scheduleDate.toIso8601String() : null,
      'scheduleTime': _scheduleRelease ? '${_scheduleTime.hour}:${_scheduleTime.minute}' : null,
      'recordLabel': _recordLabel, 'publisher': _publisher, 'isrc': _isrc, 'containsExplicitContent': _containsExplicitContent,
      'pLine': _pLine, 'enableReleaseDate': _enableReleaseDate, 'releaseDate': _enableReleaseDate ? _releaseDate.toIso8601String() : null,
      'enableDirectDownloads': _enableDirectDownloads, 'offlineListening': _offlineListening,
      'includeInRssFeed': _includeInRssFeed, 'displayEmbedCode': _displayEmbedCode, 'enableAppPlayback': _enableAppPlayback,
      'availability': _availability, 'licensing': _licensing,
    };

    bool success = await _audioService.saveTrackData(_selectedFile!, metadata);
    setState(() => _isSaving = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Track saved successfully!'), backgroundColor: Colors.green));
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _uploadSubscription?.cancel();
    _titleController.dispose();
    _genreController.dispose();
    _descriptionController.dispose();
    _captionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        leadingWidth: 80,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70, fontSize: 16)),
        ),
        title: const Text('Upload', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Color(0xFF2A1B38), shape: BoxShape.circle),
                child: const Text('4/4', style: TextStyle(color: Color(0xFFD47AFA), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  if (_currentTabIndex != 0) _buildProBanner(),
                  if (_currentTabIndex != 0) const SizedBox(height: 20),

                  if (_currentTabIndex == 0) _buildTrackInfoTab(context),
                  if (_currentTabIndex == 1) _buildAdvancedTab(context),
                  if (_currentTabIndex == 2) _buildPermissionsTab(),

                  const SizedBox(height: 24),
                  _buildSaveButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24, width: 1)),
      child: Row(
        children: [
          _buildTabItem(0, 'Track Info'),
          Container(width: 1, height: 20, color: Colors.white24),
          _buildTabItem(1, 'Advanced'),
          Container(width: 1, height: 20, color: Colors.white24),
          _buildTabItem(2, 'Permissions'),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String title) {
    bool isSelected = _currentTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white12 : Colors.transparent,
            borderRadius: BorderRadius.horizontal(left: index == 0 ? const Radius.circular(20) : Radius.zero, right: index == 2 ? const Radius.circular(20) : Radius.zero),
          ),
          alignment: Alignment.center,
          child: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }

  Widget _buildProBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Color(0xFF8A2BE2), shape: BoxShape.circle),
            child: const Icon(Icons.flash_on, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          const Text('Amplify your track with ', style: TextStyle(color: Colors.white, fontSize: 14)),
          const Text('Artist Pro', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  Widget _buildTrackInfoTab(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Picker Section
            GestureDetector(
              onTap: _pickCoverImage,
              child: _coverImage != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_coverImage!.path!),
                  width: 90, height: 90, fit: BoxFit.cover,
                ),
              )
                  : CustomPaint(
                painter: DashedRectPainter(color: Colors.white54, strokeWidth: 1.5, gap: 6.0),
                child: Container(width: 90, height: 90, alignment: Alignment.center, child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 28)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filename', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(_selectedFileName ?? 'Tap below to select track', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),

                  if (_selectedFile == null)
                    GestureDetector(
                      onTap: _pickAndUploadFile,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(border: Border.all(color: Colors.white), borderRadius: BorderRadius.circular(20)),
                        child: const Text('Select File', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    )
                  else if (_isUploading)
                    Container(
                      height: 24, width: double.infinity,
                      decoration: BoxDecoration(color: const Color(0xFF0F3B21), borderRadius: BorderRadius.circular(4)),
                      child: Stack(
                        children: [
                          FractionallySizedBox(widthFactor: _uploadProgress / 100, child: Container(decoration: BoxDecoration(color: const Color(0xFF1DB954), borderRadius: BorderRadius.circular(4)))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('PROCESSING $_uploadProgress%', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                GestureDetector(onTap: _cancelUpload, child: const Icon(Icons.close, color: Colors.white, size: 14))
                              ],
                            ),
                          )
                        ],
                      ),
                    )
                  else if (_uploadComplete)
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _pickAndUploadFile,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(border: Border.all(color: Colors.white), borderRadius: BorderRadius.circular(20)),
                              child: const Text('Replace', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.check_circle, color: Colors.green, size: 24),
                        ],
                      ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        _buildInputField('Title *', controller: _titleController),
        const SizedBox(height: 24),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
                text: TextSpan(
                    text: 'Artists ',
                    style: TextStyle(color: _artists.isEmpty ? const Color(0xFFE57373) : Colors.white70, fontSize: 12),
                    children: const [TextSpan(text: '*', style: TextStyle(color: Colors.red))]
                )
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _artists.map((artist) => Chip(
                label: Text(artist, style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.white12,
                deleteIcon: const Icon(Icons.close, color: Colors.black, size: 16),
                onDeleted: () {
                  setState(() {
                    _artists.remove(artist);
                  });
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.transparent)),
              )).toList(),
            ),

            if (_artists.isNotEmpty) const SizedBox(height: 12),
            TextField(
              controller: _artistInputController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Add any other collaborators of the track',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _artists.isEmpty ? Colors.red.withOpacity(0.7) : Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _artists.isEmpty ? Colors.red : Colors.white)),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                isDense: true,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                  onPressed: () {
                    if (_artistInputController.text.trim().isNotEmpty) {
                      setState(() {
                        if (!_artists.contains(_artistInputController.text.trim())) {
                          _artists.add(_artistInputController.text.trim());
                        }
                        _artistInputController.clear();
                      });
                    }
                  },
                ),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  setState(() {
                    if (!_artists.contains(value.trim())) {
                      _artists.add(value.trim());
                    }
                    _artistInputController.clear();
                  });
                }
              },
            ),
            if (_artists.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Please enter at least one Artist',
                  style: TextStyle(color: Color(0xFFE57373), fontSize: 12),
                ),
              ),

            const Divider(color: Colors.white24, height: 24),
          ],
        ),
        const SizedBox(height: 24),

        _buildDropdownField('Genre', _genreController.text.isEmpty ? 'Help fans discover your track' : _genreController.text, onTap: () => _genreController.text = 'INDIE'),
        const SizedBox(height: 24),
        _buildInputField('Description', controller: _descriptionController, hint: 'Add any details about your track for fans'),
        const SizedBox(height: 24),
        _buildInputField('Caption', controller: _captionController, hint: 'Add a caption to your post (optional)'),
        const SizedBox(height: 24),

        const Text('Privacy', style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 12),
        _buildCustomRadioRight('Public', 'Anyone can find this', 'public', _privacy, (val) => setState(() => _privacy = val)),
        _buildCustomRadioRight('Unlisted (Private)', 'Anyone with private link can access', 'unlisted', _privacy, (val) => setState(() => _privacy = val)),

        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              const Icon(Icons.access_time_filled, color: Colors.tealAccent, size: 20),
              const SizedBox(width: 8),
              const Text('Schedule your release with ', style: TextStyle(color: Colors.white, fontSize: 14)),
              const Text('Artist Pro', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Schedule', style: TextStyle(color: Colors.white70, fontSize: 12)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(child: Text('Set date and time to make your\ntrack public.', style: TextStyle(color: Colors.white54, fontSize: 12))),
            CupertinoSwitch(value: _scheduleRelease, onChanged: (v) => setState(() => _scheduleRelease = v), activeColor: Colors.green),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Your track stays private until release.', style: TextStyle(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 16),

        Row(
          children: [
            GestureDetector(
              onTap: _scheduleRelease ? () => _selectDate(context, _scheduleDate, (picked) => setState(() => _scheduleDate = picked)) : null,
              child: Text(_formatDate(_scheduleDate), style: TextStyle(color: _scheduleRelease ? Colors.white : Colors.white38, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: _scheduleRelease ? () => _selectTime(context) : null,
              child: Text(_scheduleTime.format(context), style: TextStyle(color: _scheduleRelease ? Colors.white : Colors.white38, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }
  Widget _buildAdvancedTab(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField('Record label', hint: 'Add your record label if applicable', onChanged: (v) => _recordLabel = v),
        const SizedBox(height: 24),
        const Text('Release date', style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: _enableReleaseDate ? () => _selectDate(context, _releaseDate, (picked) => setState(() => _releaseDate = picked)) : null,
              child: Text(_formatDate(_releaseDate), style: TextStyle(color: _enableReleaseDate ? Colors.white : Colors.white54, fontSize: 16)),
            ),
            CupertinoSwitch(value: _enableReleaseDate, activeColor: Colors.green, onChanged: (v) => setState(() => _enableReleaseDate = v)),
          ],
        ),
        const Divider(color: Colors.white24, height: 24),
        const SizedBox(height: 8),
        _buildInputField('Publisher ⓘ', hint: 'Add your publisher if you have one', onChanged: (v) => _publisher = v),
        const SizedBox(height: 24),
        _buildInputField('ISRC ⓘ', hint: 'e.g. USABC2312345', onChanged: (v) => _isrc = v),
        const SizedBox(height: 24),
        const Text('Content warning', style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(padding: const EdgeInsets.all(2), color: Colors.white, child: const Text('E', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold))),
                const SizedBox(width: 8),
                const Text('Contains explicit content', style: TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
            CupertinoSwitch(value: _containsExplicitContent, activeColor: Colors.green, onChanged: (v) => setState(() => _containsExplicitContent = v)),
          ],
        ),
        const Divider(color: Colors.white24, height: 24),
        const SizedBox(height: 8),
        _buildInputField('P line ⓘ', hint: 'e.g. 2024 [Owner Name]', onChanged: (v) => _pLine = v),
      ],
    );
  }
  Widget _buildPermissionsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Access Settings', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 16),
        _buildSwitchTile('Enable direct downloads', 'Allow listeners to download the original\naudio file.', _enableDirectDownloads, (v) => setState(() => _enableDirectDownloads = v)),
        _buildSwitchTile('Offline listening', 'Offline listening allows this track to be played\non devices without an internet connection.', _offlineListening, (v) => setState(() => _offlineListening = v)),
        _buildSwitchTile('Include in RSS feed', 'Choose whether you want this track to show up\nin your public RSS feed.', _includeInRssFeed, (v) => setState(() => _includeInRssFeed = v)),
        _buildSwitchTile('Display embed code', "Choose whether you want this track's\nembedded-player code to be displayed\npublicly.", _displayEmbedCode, (v) => setState(() => _displayEmbedCode = v)),
        _buildSwitchTile('Enable app playback', 'Choose whether you want this track to be\nplayable outside of SoundCloud and its apps.', _enableAppPlayback, (v) => setState(() => _enableAppPlayback = v)),

        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Engagement privacy', style: TextStyle(color: Colors.white70, fontSize: 14)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF3B2F2F), borderRadius: BorderRadius.circular(4)),
              child: const Row(children: [Icon(Icons.star, color: Colors.orangeAccent, size: 12), SizedBox(width: 4), Text('Unlock with Artist Pro', style: TextStyle(color: Colors.orangeAccent, fontSize: 10))]),
            )
          ],
        ),
        const SizedBox(height: 16),
        _buildSwitchTile('Allow people to comment on your track', '', false, (v) {}, disabled: true),
        _buildSwitchTile('Show track comments to public', '', false, (v) {}, disabled: true),
        _buildSwitchTile('Show track insights to public', '', false, (v) {}, disabled: true),

        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Availability', style: TextStyle(color: Colors.white70, fontSize: 14)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF3B2F2F), borderRadius: BorderRadius.circular(4)),
              child: const Row(children: [Icon(Icons.star, color: Colors.orangeAccent, size: 12), SizedBox(width: 4), Text('Unlock with Artist Pro', style: TextStyle(color: Colors.orangeAccent, fontSize: 10))]),
            )
          ],
        ),
        const SizedBox(height: 16),
        _buildCustomRadioRight('Worldwide', '', 'worldwide', _availability, (val) => setState(() => _availability = val)),
        _buildCustomRadioRight('Exclusive regions', '', 'exclusive', _availability, (val) => setState(() => _availability = val)),
        _buildCustomRadioRight('Blocked regions', '', 'blocked', _availability, (val) => setState(() => _availability = val)),

        const SizedBox(height: 16),
        const Text('Licensing', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 16),
        _buildCustomRadioRight('All rights reserved', 'By choosing All Rights Reserved, you ask that other\ncreators not use your material. Copyright is\nautomatically granted to you when you begin\ncreating your work.', 'all_rights', _licensing, (val) => setState(() => _licensing = val)),
        _buildCustomRadioRight('Creative Commons', 'With Creative Commons licenses, creators have the\nchoice to give up certain exclusive rights normally\nassociated with copyright, while retaining others.\nThere are six different licenses that provide users\nwith different levels of freedom.', 'creative_commons', _licensing, (val) => setState(() => _licensing = val)),
      ],
    );
  }
  Widget _buildInputField(String label, {TextEditingController? controller, String? hint, Function(String)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        TextField(
          controller: controller, onChanged: onChanged, style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint, hintStyle: const TextStyle(color: Colors.white38, fontSize: 16),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
            contentPadding: const EdgeInsets.symmetric(vertical: 8), isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: TextStyle(color: value == 'INDIE' ? Colors.white : Colors.white38, fontSize: 16)),
              const Icon(Icons.unfold_more, color: Colors.white54, size: 20),
            ],
          ),
          const Divider(color: Colors.white24, height: 16),
        ],
      ),
    );
  }

  Widget _buildCustomRadioRight(String title, String subtitle, String value, String groupValue, Function(String) onChanged) {
    bool isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4)),
                  ]
                ],
              ),
            ),
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.white : Colors.transparent,
                border: Border.all(color: isSelected ? Colors.white : Colors.white54, width: 1.5),
              ),
              child: isSelected ? const Icon(Icons.check, color: Colors.black, size: 14) : null,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged, {bool disabled = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: subtitle.isNotEmpty ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: disabled ? Colors.white38 : Colors.white, fontSize: 14)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: disabled ? Colors.white24 : Colors.white54, fontSize: 12, height: 1.4)),
                ]
              ],
            ),
          ),
          CupertinoSwitch(value: value, activeColor: Colors.green, trackColor: Colors.white24, onChanged: disabled ? null : onChanged),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity, height: 48,
          child: ElevatedButton(
            onPressed: (_isSaving || _selectedFile == null || !_uploadComplete) ? null : _saveTrack,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white, disabledBackgroundColor: Colors.white38, foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                : const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),
        const Text('By uploading, you confirm that your sounds\ncomply with our Terms of Use and you don\'t\ninfringe anyone else\'s rights.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.4)),
        const SizedBox(height: 8),
        const Text('TERMS OF USE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
      ],
    );
  }
}