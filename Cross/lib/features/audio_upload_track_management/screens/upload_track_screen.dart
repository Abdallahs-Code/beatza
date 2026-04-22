import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cross_team5/features/audio_upload_track_management/services/audio_upload_service.dart';
import 'package:cross_team5/features/audio_upload_track_management/services/track_api_service.dart';
import 'package:cross_team5/features/audio_upload_track_management/widgets/pro_disabled_switch_widget.dart';
import 'package:cross_team5/features/audio_upload_track_management/widgets/pro_radio_tile_widget.dart';
import 'package:cross_team5/features/audio_upload_track_management/screens/artist_pro_screens.dart';
import 'package:cross_team5/features/audio_upload_track_management/screens/your_uploads_screen.dart';
import 'package:cross_team5/features/premium_subscription/services/payment_service.dart';
import '../../premium_subscription/screens/premium_subscription.dart';

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({
    this.color = Colors.white,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(8),
        ),
      );
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + gap), paint);
        distance += gap * 2;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class UploadTrackScreen extends StatefulWidget {
  const UploadTrackScreen({super.key});

  @override
  State<UploadTrackScreen> createState() => _UploadTrackScreenState();
}

class _UploadTrackScreenState extends State<UploadTrackScreen> {
  final AudioUploadService _audioService = AudioUploadService();
  final TrackApiService _trackApiService = TrackApiService();
  bool _allowComments = false;
  bool _showCommentsToPublic = false;
  PlatformFile? _selectedFile;
  String? _selectedFileName;
  int _uploadProgress = 0;
  bool _isUploading = false;
  bool _uploadComplete = false;
  StreamSubscription<int>? _uploadSubscription;
  PlatformFile? _coverImage;

  final _titleController = TextEditingController();
  final _genreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _captionController = TextEditingController();
  final _tagsController = TextEditingController();
  final _artistInputController = TextEditingController();
  final List<String> _artists = [];

  int _currentTabIndex = 0;
  bool _isSaving = false;
  bool _isInit = false;

  String _privacy = 'public';
  final DateTime _scheduleDate = DateTime.now().add(const Duration(days: 1));
  final TimeOfDay _scheduleTime = TimeOfDay.now();
  bool _enableReleaseDate = false;
  DateTime _releaseDate = DateTime.now();
  bool _containsExplicitContent = false;
  bool _enableDirectDownloads = false;
  bool _offlineListening = true;
  bool _includeInRssFeed = true;
  bool _displayEmbedCode = false;
  bool _enableAppPlayback = true;
  String _availability = 'worldwide';
  String _licensing = 'all_rights';

  int get _uploadStepsCompleted {
    int c = 0;
    if (_selectedFile != null) c++;
    if (_coverImage != null) c++;
    if (_titleController.text.trim().isNotEmpty) c++;
    if (_descriptionController.text.trim().isNotEmpty) c++;
    return c;
  }

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_refresh);
    _descriptionController.addListener(_refresh);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is PlatformFile) _processFile(args);
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_refresh);
    _descriptionController.removeListener(_refresh);
    _uploadSubscription?.cancel();
    _titleController.dispose();
    _genreController.dispose();
    _descriptionController.dispose();
    _captionController.dispose();
    _tagsController.dispose();
    _artistInputController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _processFile(PlatformFile file) {
    setState(() {
      _selectedFile = file;
      _selectedFileName = file.name;
      _titleController.text = file.name.replaceAll(
        RegExp(r'\.(mp3|wav|flac|aac)$', caseSensitive: false),
        '',
      );
      _isUploading = true;
      _uploadComplete = false;
      _uploadProgress = 0;
    });

    _uploadSubscription?.cancel();
    _uploadSubscription = _audioService.mockUploadStream().listen(
          (progress) {
        if (mounted) setState(() => _uploadProgress = progress);
      },
      onDone: () {
        if (mounted) {
          setState(() {
            _isUploading = false;
            _uploadComplete = true;
          });
        }
      },
    );
  }

  void _pickAndUploadFile() async {
    final file = await _audioService.pickAudioFile();
    if (file != null) _processFile(file);
  }

  void _pickCoverImage() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result != null && result.files.isNotEmpty) {
      setState(() => _coverImage = result.files.single);
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

  Future<void> _saveTrack() async {
    if (_selectedFile == null || !_uploadComplete) return;
    if (_titleController.text.trim().isEmpty) {
      _snack('Please enter a track title', isError: true);
      return;
    }
    if (_selectedFile!.path == null) {
      _snack('Audio file path is unavailable', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final result = await _trackApiService.uploadTrack(
      audioFilePath: _selectedFile!.path!,
      audioFileName: _selectedFile!.name,
      imageFilePath: _coverImage?.path,
      title: _titleController.text.trim(),
      permalink: _titleController.text.trim().toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9]+'),
        '-',
      ),
      mainArtists: _artists,
      genre: _genreController.text.trim(),
      tags: tags,
      description: _descriptionController.text.trim(),
      isPrivate: _privacy == 'unlisted',
      caption: _captionController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.$1 == 201) {
      await _audioService.saveTrackData(_selectedFile!, {
        'title': _titleController.text.trim(),
        'genre': _genreController.text.trim(),
        'description': _descriptionController.text.trim(),
        'caption': _captionController.text.trim(),
        'tags': _tagsController.text.trim(),
        'visibility': _privacy,
        'coverImagePath': _coverImage?.path,
      });

      if (!mounted) return;

      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      final trackTitle = _titleController.text.trim();
      navigator.pop();

      messenger.showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
          elevation: 10,
          duration: const Duration(seconds: 5),
          content: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFFFF5500),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Upload Successful',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      trackTitle,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  messenger.hideCurrentSnackBar();
                  navigator.push(
                    MaterialPageRoute(
                      builder: (_) => const YourUploadsScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5500),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'SEE TRACK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      _snack(
        result.$2.toString().isNotEmpty
            ? result.$2.toString()
            : 'Upload failed. Please try again.',
        isError: true,
      );
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red[800] : const Color(0xFF2A2A2A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showProModal() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PremiumSubscriptionScreen()),
    );
  }

  void _showGenrePicker() {
    const genres = [
      'Alternative Rock',
      'Ambient',
      'Classical',
      'Country',
      'Electronic',
      'Hip-Hop',
      'House',
      'Indie',
      'Jazz',
      'Metal',
      'Pop',
      'R&B / Soul',
      'Reggae',
      'Rock',
      'Speech',
      'Techno',
      'Trance',
      'World',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ListView.builder(
        itemCount: genres.length,
        itemBuilder: (_, i) => ListTile(
          title: Text(genres[i], style: const TextStyle(color: Colors.white)),
          trailing: _genreController.text == genres[i]
              ? const Icon(Icons.check, color: Colors.orange)
              : null,
          onTap: () {
            setState(() => _genreController.text = genres[i]);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _selectDate(
      BuildContext context,
      DateTime initial,
      void Function(DateTime) onPicked,
      ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF1DB954),
            onPrimary: Colors.white,
            surface: Color(0xFF1E1E1E),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) onPicked(picked);
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SubscriptionState>(
      valueListenable: PaymentService.subscriptionSuccessNotifier,
      builder: (context, state, _) {
        final isPro = state.isPro;
        return Scaffold(
          backgroundColor: const Color(0xFF0F0F0F),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F0F0F),
            elevation: 0,
            leadingWidth: 80,
            leading: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            title: const Text(
              'Upload',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2A1B38),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_uploadStepsCompleted/4',
                      style: const TextStyle(
                        color: Color(0xFFD47AFA),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  _buildTabBar(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 100,
                      ),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          if (_currentTabIndex != 0 && !isPro) _buildProBanner(),
                          if (_currentTabIndex != 0 && !isPro) const SizedBox(height: 20),
                          if (_currentTabIndex == 0) _buildTrackInfoTab(context, isPro),
                          if (_currentTabIndex == 1) _buildAdvancedTab(context),
                          if (_currentTabIndex == 2) _buildPermissionsTab(isPro),
                          const SizedBox(height: 24),
                          _buildSaveButton(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _tabItem(0, 'Track Info'),
          Container(width: 1, height: 20, color: Colors.white24),
          _tabItem(1, 'Advanced'),
          Container(width: 1, height: 20, color: Colors.white24),
          _tabItem(2, 'Permissions'),
        ],
      ),
    );
  }

  Widget _tabItem(int index, String label) {
    final sel = _currentTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? Colors.white12 : Colors.transparent,
            borderRadius: BorderRadius.horizontal(
              left: index == 0 ? const Radius.circular(20) : Radius.zero,
              right: index == 2 ? const Radius.circular(20) : Radius.zero,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: sel ? Colors.white : Colors.white54,
              fontWeight: sel ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackInfoTab(BuildContext context, bool isPro) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickCoverImage,
              child: _coverImage != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_coverImage!.path!),
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),
              )
                  : CustomPaint(
                painter: DashedRectPainter(
                  color: Colors.white54,
                  strokeWidth: 1.5,
                  gap: 6,
                ),
                child: Container(
                  width: 90,
                  height: 90,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filename',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _selectedFileName ?? 'Tap below to select track',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  if (_selectedFile == null)
                    GestureDetector(
                      onTap: _pickAndUploadFile,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Select File',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    )
                  else if (_isUploading)
                    _buildProgressBar()
                  else if (_uploadComplete)
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _pickAndUploadFile,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Replace',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 24,
                          ),
                        ],
                      ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _inputField('Title *', controller: _titleController),
        const SizedBox(height: 24),
        _buildArtistField(),
        const SizedBox(height: 24),
        _dropdownField(
          'Genre',
          _genreController.text.isEmpty
              ? 'Help fans discover your track'
              : _genreController.text,
          onTap: _showGenrePicker,
        ),
        const SizedBox(height: 24),
        _inputField(
          'Description',
          controller: _descriptionController,
          hint: 'Add any details about your track for fans',
        ),
        const SizedBox(height: 24),
        _inputField(
          'Caption',
          controller: _captionController,
          hint: 'Add a caption to your post (optional)',
        ),
        const SizedBox(height: 24),
        const Text(
          'Privacy',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 12),
        _radioRight('Public', 'Anyone can find this', 'public'),
        _radioRight(
          'Unlisted (Private)',
          'Anyone with private link can access',
          'unlisted',
        ),
        const SizedBox(height: 16),
        if (!isPro)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.access_time_filled, color: Colors.white38, size: 20),
                SizedBox(width: 8),
                Text(
                  'Schedule your release with ',
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
                Text(
                  'Artist Pro',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Text(
          'Schedule',
          style: TextStyle(color: isPro ? Colors.white70 : Colors.white38, fontSize: 12),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Set date and time to make your\ntrack public (Artist Pro).',
                style: TextStyle(color: isPro ? Colors.white : Colors.white38, fontSize: 12),
              ),
            ),
            if (isPro)
              CupertinoSwitch(
                value: _enableReleaseDate,
                activeTrackColor: Colors.green,
                onChanged: (v) => setState(() => _enableReleaseDate = v),
              )
            else
              ProDisabledSwitch(onTap: _showProModal),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Your track stays private until release.',
          style: TextStyle(color: isPro ? Colors.white54 : Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            GestureDetector(
              onTap: isPro && _enableReleaseDate
                  ? () => _selectDate(
                context,
                _releaseDate,
                    (d) => setState(() => _releaseDate = d),
              )
                  : null,
              child: Text(
                _formatDate(isPro && _enableReleaseDate ? _releaseDate : _scheduleDate),
                style: TextStyle(
                  color: isPro && _enableReleaseDate ? Colors.white : Colors.white38,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              _scheduleTime.format(context),
              style: TextStyle(
                color: isPro && _enableReleaseDate ? Colors.white : Colors.white38,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 24,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F3B21),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: _uploadProgress / 100,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1DB954),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PROCESSING $_uploadProgress%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                GestureDetector(
                  onTap: _cancelUpload,
                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Artists ',
            style: TextStyle(
              color: _artists.isEmpty
                  ? const Color(0xFFE57373)
                  : Colors.white70,
              fontSize: 12,
            ),
            children: const [
              TextSpan(
                text: '*',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _artists
              .map(
                (a) => Chip(
              label: Text(
                a,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.white12,
              deleteIcon: const Icon(
                Icons.close,
                color: Colors.black,
                size: 16,
              ),
              onDeleted: () => setState(() => _artists.remove(a)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.transparent),
              ),
            ),
          )
              .toList(),
        ),
        if (_artists.isNotEmpty) const SizedBox(height: 12),
        TextField(
          controller: _artistInputController,
          style: const TextStyle(color: Colors.white38, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Add artist name',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 16),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white38),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            isDense: true,
            suffixIcon: IconButton(
              icon: const Icon(Icons.add, color: Colors.white54),
              onPressed: _addArtist,
            ),
          ),
          onSubmitted: (_) => _addArtist(),
        ),
        if (_artists.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Please enter at least one Artist',
              style: TextStyle(color: Color(0xFFE57373), fontSize: 12),
            ),
          ),
        const Divider(color: Colors.white24, height: 24),
      ],
    );
  }

  void _addArtist() {
    final v = _artistInputController.text.trim();
    if (v.isNotEmpty) {
      setState(() {
        if (!_artists.contains(v)) _artists.add(v);
        _artistInputController.clear();
      });
    }
  }

  Widget _buildAdvancedTab(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inputField(
          'Record label',
          hint: 'Add your record label if applicable',
        ),
        const SizedBox(height: 24),
        const Text(
          'Release date',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: _enableReleaseDate
                  ? () => _selectDate(
                context,
                _releaseDate,
                    (d) => setState(() => _releaseDate = d),
              )
                  : null,
              child: Text(
                _formatDate(_releaseDate),
                style: TextStyle(
                  color: _enableReleaseDate ? Colors.white : Colors.white54,
                  fontSize: 16,
                ),
              ),
            ),
            CupertinoSwitch(
              value: _enableReleaseDate,
              activeTrackColor: Colors.green,
              onChanged: (v) => setState(() => _enableReleaseDate = v),
            ),
          ],
        ),
        const Divider(color: Colors.white24, height: 24),
        const SizedBox(height: 8),
        _inputField(
          'Publisher ⓘ',
          hint: 'Add your publisher if you have one',
        ),
        const SizedBox(height: 24),
        _inputField(
          'ISRC ⓘ',
          hint: 'e.g. USABC2312345',
        ),
        const SizedBox(height: 24),
        const Text(
          'Content warning',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  color: Colors.white,
                  child: const Text(
                    'E',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Contains explicit content',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
            CupertinoSwitch(
              value: _containsExplicitContent,
              activeTrackColor: Colors.green,
              onChanged: (v) => setState(() => _containsExplicitContent = v),
            ),
          ],
        ),
        const Divider(color: Colors.white24, height: 24),
        const SizedBox(height: 8),
        _inputField(
          'P line ⓘ',
          hint: 'e.g. 2024 [Owner Name]',
        ),
      ],
    );
  }

  Widget _buildPermissionsTab(bool isPro) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Access Settings',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 16),
        _switchTile(
          'Enable direct downloads',
          'Allow listeners to download the original audio file.',
          _enableDirectDownloads,
              (v) => setState(() => _enableDirectDownloads = v),
        ),
        _switchTile(
          'Offline listening',
          'Allows this track to be played without an internet connection.',
          _offlineListening,
              (v) => setState(() => _offlineListening = v),
        ),
        _switchTile(
          'Include in RSS feed',
          'Choose whether this track appears in your public RSS feed.',
          _includeInRssFeed,
              (v) => setState(() => _includeInRssFeed = v),
        ),
        _switchTile(
          'Display embed code',
          "Choose whether this track's embedded-player code is displayed publicly.",
          _displayEmbedCode,
              (v) => setState(() => _displayEmbedCode = v),
        ),
        _switchTile(
          'Enable app playback',
          'Choose whether this track is playable outside of SoundCloud.',
          _enableAppPlayback,
              (v) => setState(() => _enableAppPlayback = v),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Engagement privacy',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            if (!isPro)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B2F2F),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.star, color: Colors.orangeAccent, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Unlock with Artist Pro',
                      style: TextStyle(color: Colors.orangeAccent, fontSize: 10),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: isPro ? null : _showProModal,
          child: AbsorbPointer(
            absorbing: !isPro,
            child: _switchTile(
              'Allow people to comment on your track',
              '',
              _allowComments,
                  (v) {
                if (isPro) setState(() => _allowComments = v);
              },
              disabled: !isPro,
            ),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: isPro ? null : _showProModal,
          child: AbsorbPointer(
            absorbing: !isPro,
            child: _switchTile(
              'Show track comments to public',
              '',
              _showCommentsToPublic,
                  (v) {
                if (isPro) setState(() => _showCommentsToPublic = v);
              },
              disabled: !isPro,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Availability',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            if (!isPro)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B2F2F),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.star, color: Colors.orangeAccent, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Unlock with Artist Pro',
                      style: TextStyle(color: Colors.orangeAccent, fontSize: 10),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        ProRadioTile(
          title: 'Worldwide',
          selected: _availability == 'worldwide',
          onTap: () => setState(() => _availability = 'worldwide'),
          isPro: true,
        ),
        ProRadioTile(
          title: 'Exclusive regions',
          selected: _availability == 'exclusive',
          onTap: isPro ? () => setState(() => _availability = 'exclusive') : _showProModal,
          isPro: isPro,
        ),
        ProRadioTile(
          title: 'Blocked regions',
          selected: _availability == 'blocked',
          onTap: isPro ? () => setState(() => _availability = 'blocked') : _showProModal,
          isPro: isPro,
        ),
        const SizedBox(height: 16),
        const Text(
          'Licensing',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 16),
        _radioRight(
          'All rights reserved',
          'By choosing All Rights Reserved, you ask that others not use your material.',
          'all_rights',
          groupValue: _licensing,
          onChanged: (v) => setState(() => _licensing = v),
        ),
        _radioRight(
          'Creative Commons',
          'With Creative Commons licenses, creators can give up certain exclusive rights.',
          'creative_commons',
          groupValue: _licensing,
          onChanged: (v) => setState(() => _licensing = v),
        ),
      ],
    );
  }
  Widget _buildProBanner() {
    return GestureDetector(
      onTap: _showProModal,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF8A2BE2).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.flash_on,
                color: Colors.white38,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Amplify your track with ',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
            const Text(
              'Artist Pro',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(
      String label, {
        TextEditingController? controller,
        String? hint,
        void Function(String)? onChanged,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white38, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 16),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white38),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _dropdownField(String label, String value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: value == 'Help fans discover your track'
                      ? Colors.white38
                      : Colors.white,
                  fontSize: 16,
                ),
              ),
              const Icon(Icons.unfold_more, color: Colors.white54, size: 20),
            ],
          ),
          const Divider(color: Colors.white24, height: 16),
        ],
      ),
    );
  }

  Widget _radioRight(
      String title,
      String subtitle,
      String value, {
        String? groupValue,
        void Function(String)? onChanged,
      }) {
    final gv = groupValue ?? _privacy;
    final fn = onChanged ?? (v) => setState(() => _privacy = v);
    final sel = value == gv;
    return InkWell(
      onTap: () => fn(value),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: sel ? Colors.white : Colors.transparent,
                border: Border.all(
                  color: sel ? Colors.white : Colors.white54,
                  width: 1.5,
                ),
              ),
              child: sel
                  ? const Icon(Icons.check, color: Colors.black, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchTile(
      String title,
      String subtitle,
      bool value,
      void Function(bool) onChange, {
        bool disabled = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: subtitle.isNotEmpty
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: disabled ? Colors.white38 : Colors.white,
                    fontSize: 14,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: disabled ? Colors.white24 : Colors.white54,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: Colors.green,
            inactiveTrackColor: Colors.white24,
            onChanged: disabled ? null : onChange,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    final ready = _selectedFile != null && _uploadComplete;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: (ready && !_isSaving) ? _saveTrack : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: ready ? Colors.white : Colors.white10,
              disabledBackgroundColor: _isSaving
                  ? Colors.white
                  : Colors.white10,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 2,
              ),
            )
                : Text(
              'Save',
              style: TextStyle(
                color: ready ? Colors.black : Colors.white38,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Confirm your sounds comply with our Terms.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 11),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ArtistTermsScreen()),
          ),
          child: const Text(
            'TERMS OF USE',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}