import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cross_team5/features/audio_upload_track_management/models/track.dart';
import 'package:cross_team5/features/audio_upload_track_management/models/track_model.dart';
import 'package:cross_team5/features/audio_upload_track_management/services/audio_upload_service.dart';
import 'package:cross_team5/features/audio_upload_track_management/services/track_api_service.dart';
import 'package:cross_team5/features/audio_upload_track_management/widgets/pro_disabled_switch_widget.dart';
import 'package:cross_team5/features/audio_upload_track_management/widgets/pro_radio_tile_widget.dart';
import 'package:cross_team5/features/audio_upload_track_management/screens/artist_pro_screens.dart';
import 'package:cross_team5/features/audio_upload_track_management/screens/your_uploads_screen.dart';
import 'package:cross_team5/features/premium_subscription/services/payment_service.dart';
import 'package:provider/provider.dart';
import 'package:cross_team5/core/services/theme_service.dart';
import '../../premium_subscription/screens/premium_subscription.dart';

// ── Geo-blocking data ────────────────────────────────────────────────────────

const _kGeoRegions = [
  'Africa', 'Antarctica', 'Asia', 'Europe',
  'NorthAmerica', 'Oceania', 'SouthAmerica',
];

const _kGeoDisplayNames = <String, String>{
  'NorthAmerica': 'North America',
  'SouthAmerica': 'South America',
  'CongoDemocraticRepublic': 'DR Congo',
  'CongoRepublic': 'Republic of Congo',
  'BurkinaFaso': 'Burkina Faso',
  'CaboVerde': 'Cabo Verde',
  'CentralAfricanRepublic': 'Central African Republic',
  'KoreaNorth': 'North Korea',
  'KoreaSouth': 'South Korea',
  'CostaRica': 'Costa Rica',
  'CzechRepublic': 'Czech Republic',
  'ElSalvador': 'El Salvador',
  'EquatorialGuinea': 'Equatorial Guinea',
  'GuineaBissau': 'Guinea-Bissau',
  'MarshallIslands': 'Marshall Islands',
  'NewZealand': 'New Zealand',
  'NorthMacedonia': 'North Macedonia',
  'PapuaNewGuinea': 'Papua New Guinea',
  'SaintKittsAndNevis': 'Saint Kitts & Nevis',
  'SaintLucia': 'Saint Lucia',
  'SaintVincentAndTheGrenadines': 'Saint Vincent & the Grenadines',
  'SanMarino': 'San Marino',
  'SaoTomeAndPrincipe': 'São Tomé & Príncipe',
  'SaudiArabia': 'Saudi Arabia',
  'SierraLeone': 'Sierra Leone',
  'SolomonIslands': 'Solomon Islands',
  'SouthAfrica': 'South Africa',
  'SouthSudan': 'South Sudan',
  'SriLanka': 'Sri Lanka',
  'TimorLeste': 'Timor-Leste',
  'TrinidadAndTobago': 'Trinidad & Tobago',
  'UnitedArabEmirates': 'United Arab Emirates',
  'UnitedKingdom': 'United Kingdom',
  'UnitedStates': 'United States',
  'VaticanCity': 'Vatican City',
  'AntiguaAndBarbuda': 'Antigua & Barbuda',
  'BosniaAndHerzegovina': 'Bosnia & Herzegovina',
  'DominicanRepublic': 'Dominican Republic',
  'Ivory Coast': 'Ivory Coast',
};

const _kRegionCountries = <String, List<String>>{
  'Africa': [
    'Algeria', 'Angola', 'Benin', 'Botswana', 'BurkinaFaso', 'Burundi',
    'CaboVerde', 'Cameroon', 'CentralAfricanRepublic', 'Chad', 'Comoros',
    'CongoDemocraticRepublic', 'CongoRepublic', 'Djibouti', 'Egypt',
    'EquatorialGuinea', 'Eritrea', 'Eswatini', 'Ethiopia', 'Gabon', 'Gambia',
    'Ghana', 'Guinea', 'GuineaBissau', 'Ivory Coast', 'Kenya', 'Lesotho',
    'Liberia', 'Libya', 'Madagascar', 'Malawi', 'Mali', 'Mauritania',
    'Mauritius', 'Morocco', 'Mozambique', 'Namibia', 'Niger', 'Nigeria',
    'Rwanda', 'SaoTomeAndPrincipe', 'Senegal', 'Seychelles', 'SierraLeone',
    'Somalia', 'SouthAfrica', 'SouthSudan', 'Sudan', 'Tanzania', 'Togo',
    'Tunisia', 'Uganda', 'Zambia', 'Zimbabwe',
  ],
  'Antarctica': [],
  'Asia': [
    'Afghanistan', 'Armenia', 'Azerbaijan', 'Bahrain', 'Bangladesh', 'Bhutan',
    'Brunei', 'Cambodia', 'China', 'Cyprus', 'Georgia', 'India', 'Indonesia',
    'Iran', 'Iraq', 'Japan', 'Jordan', 'Kazakhstan', 'Kuwait', 'Kyrgyzstan',
    'Laos', 'Lebanon', 'Malaysia', 'Maldives', 'Mongolia', 'Myanmar', 'Nepal',
    'KoreaNorth', 'Oman', 'Pakistan', 'Palestine', 'Philippines', 'Qatar',
    'Russia', 'SaudiArabia', 'Singapore', 'KoreaSouth', 'SriLanka', 'Syria',
    'Taiwan', 'Tajikistan', 'Thailand', 'TimorLeste', 'Turkey', 'Turkmenistan',
    'UnitedArabEmirates', 'Uzbekistan', 'Vietnam', 'Yemen',
  ],
  'Europe': [
    'Albania', 'Andorra', 'Austria', 'Belarus', 'Belgium', 'BosniaAndHerzegovina',
    'Bulgaria', 'Croatia', 'Cyprus', 'CzechRepublic', 'Denmark', 'Estonia',
    'Finland', 'France', 'Georgia', 'Germany', 'Greece', 'Hungary', 'Iceland',
    'Ireland', 'Italy', 'Kosovo', 'Latvia', 'Liechtenstein', 'Lithuania',
    'Luxembourg', 'Malta', 'Moldova', 'Monaco', 'Montenegro', 'Netherlands',
    'NorthMacedonia', 'Norway', 'Poland', 'Portugal', 'Romania', 'Russia',
    'SanMarino', 'Serbia', 'Slovakia', 'Slovenia', 'Spain', 'Sweden',
    'Switzerland', 'Ukraine', 'UnitedKingdom', 'VaticanCity',
  ],
  'NorthAmerica': [
    'AntiguaAndBarbuda', 'Bahamas', 'Barbados', 'Belize', 'Canada', 'CostaRica',
    'Cuba', 'Dominica', 'DominicanRepublic', 'ElSalvador', 'Grenada', 'Guatemala',
    'Haiti', 'Honduras', 'Jamaica', 'Mexico', 'Nicaragua', 'Panama',
    'SaintKittsAndNevis', 'SaintLucia', 'SaintVincentAndTheGrenadines',
    'TrinidadAndTobago', 'UnitedStates',
  ],
  'Oceania': [
    'Australia', 'Fiji', 'Kiribati', 'MarshallIslands', 'Micronesia', 'Nauru',
    'NewZealand', 'Palau', 'PapuaNewGuinea', 'Samoa', 'SolomonIslands', 'Tonga',
    'Tuvalu', 'Vanuatu',
  ],
  'SouthAmerica': [
    'Argentina', 'Bolivia', 'Brazil', 'Chile', 'Colombia', 'Ecuador', 'Guyana',
    'Paraguay', 'Peru', 'Suriname', 'Uruguay', 'Venezuela',
  ],
};

String _displayGeoName(String key) =>
    _kGeoDisplayNames[key] ??
    key.replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (_) => ' ');

// ─────────────────────────────────────────────────────────────────────────────

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({Color? color, this.strokeWidth = 1.0, this.gap = 5.0})
    : color = color ?? AppColors.whiteSmoke;

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
  TrackModel? _editingTrack;
  Track? _editingServerTrack;
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
  final _recordLabelController = TextEditingController();
  final _publisherController = TextEditingController();
  final _isrcController = TextEditingController();
  final _pLineController = TextEditingController();
  final List<String> _artists = [];

  int _currentTabIndex = 0;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isInit = false;
  List<String> _selectedRegions = [];
  List<String> _selectedCountries = [];

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
  bool _mobileProPreview = false;

  int get _uploadStepsCompleted {
    final bool inEditMode =
        _editingTrack != null || _editingServerTrack != null;
    int c = 0;
    if (inEditMode || _selectedFile != null) c++;
    if (_coverImage != null) c++;
    if (_genreController.text.trim().isNotEmpty) c++;
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
      if (args is PlatformFile) {
        _processFile(args);
      } else if (args is Track) {
        _editingServerTrack = args;
        _selectedFileName = args.title;

        // basic info
        _titleController.text = args.title;
        _genreController.text = args.genre;
        _descriptionController.text = args.description;
        _captionController.text = args.caption;
        _tagsController.text = args.tags.join(', ');
        _privacy = args.isPrivate ? 'unlisted' : 'public';
        if (args.mainArtists.isNotEmpty) _artists.addAll(args.mainArtists);

        // permissions
        _enableDirectDownloads = args.enableDirectDownload;
        _offlineListening = args.offlineListening;
        _includeInRssFeed = args.includeInRssFeed;
        _displayEmbedCode = args.displayedEmbedCode;
        _enableAppPlayback = args.enableAppPlayback;

        // license
        _licensing = args.licenseType == 'creativeCommons'
            ? 'creative_commons'
            : 'all_rights';

        // geo-blocking
        _availability = args.geoBlockingMode;
        _selectedRegions = List.from(args.geoBlockingRegions);
        _selectedCountries = List.from(args.geoBlockingCountries);

        // advanced
        _containsExplicitContent = args.explicitContent;
        _recordLabelController.text = args.recordLabel ?? '';
        _publisherController.text = args.publisher ?? '';
        _isrcController.text = args.isrc ?? '';
        _pLineController.text = args.pLine ?? '';

        // mobileProPreview
        _mobileProPreview = args.mobileProPreview;

        // release date
        if (args.releaseDate.isNotEmpty) {
          final parsed = DateTime.tryParse(args.releaseDate);
          if (parsed != null) {
            _releaseDate = parsed;
            _enableReleaseDate = true;
          }
        }

        _uploadComplete = true;
      } else if (args is TrackModel) {
        _editingTrack = args;
        _selectedFileName = args.audioUrl.split(RegExp(r'[/\\]')).last;
        _titleController.text = args.title;
        _genreController.text = args.genre;
        _descriptionController.text = args.description;
        _captionController.text = args.caption;
        _tagsController.text = args.descriptiveTags.join(', ');
        _privacy =
            args.visibility == TrackVisibility.private ||
                args.visibility == TrackVisibility.unlisted
            ? 'unlisted'
            : 'public';
        _uploadComplete = true;
      }
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
    _recordLabelController.dispose();
    _publisherController.dispose();
    _isrcController.dispose();
    _pLineController.dispose();
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
    if (_editingServerTrack != null) {
      await _updateServerTrack();
    } else if (_editingTrack != null) {
      await _updateExistingTrack();
    } else {
      await _uploadNewTrack();
    }
  }

  Future<void> _updateServerTrack() async {
    final track = _editingServerTrack!;
    if (track.id.trim().isEmpty) {
      _showErrorSnack('Cannot update: track ID is missing.');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      _showErrorSnack('Please enter a track title');
      return;
    }

    setState(() => _isSaving = true);

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final genre = _genreController.text.trim();
    final effectiveTags = tags.isNotEmpty
        ? tags
        : (genre.isNotEmpty ? [genre] : ['uncategorized']);

    final result = await _trackApiService.updateTrack(
      trackId: track.id,
      imageFilePath: _coverImage?.path,
      title: _titleController.text.trim(),
      mainArtists: _artists.isNotEmpty ? _artists : null,
      genre: genre.isNotEmpty ? genre : null,
      tags: effectiveTags,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      isPrivate: _privacy == 'unlisted',
      caption: _captionController.text.trim().isNotEmpty
          ? _captionController.text.trim()
          : null,
      enableDirectDownload: _enableDirectDownloads,
      offlineListening: _offlineListening,
      includeInRssFeed: _includeInRssFeed,
      displayedEmbedCode: _displayEmbedCode,
      enableAppPlayback: _enableAppPlayback,
      licensing: _licensing,
      containsExplicit: _containsExplicitContent,
      releaseDate: _enableReleaseDate ? _releaseDate.toIso8601String() : null,
      recordLabel: _recordLabelController.text.trim().isNotEmpty
          ? _recordLabelController.text.trim()
          : null,
      publisher: _publisherController.text.trim().isNotEmpty
          ? _publisherController.text.trim()
          : null,
      isrc: _isrcController.text.trim().isNotEmpty
          ? _isrcController.text.trim()
          : null,
      pLine: _pLineController.text.trim().isNotEmpty
          ? _pLineController.text.trim()
          : null,
      availability: _availability,
      geoBlockingRegions: _selectedRegions,
      geoBlockingCountries: _selectedCountries,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.$1 == 200) {
      await _trackApiService.updateMobileProPreview(
        trackId: track.id,
        mobileProPreview: _mobileProPreview,
      );
      if (!mounted) return;
      Navigator.pop(context);
      _showSuccessSnack(
        'Track Updated',
        subtitle: _titleController.text.trim(),
      );
    } else {
      _showErrorSnack(
        result.$2.toString().isNotEmpty
            ? result.$2.toString()
            : 'Update failed. Please try again.',
      );
    }
  }

  Future<void> _uploadNewTrack() async {
    if (_selectedFile == null || !_uploadComplete) return;
    if (_titleController.text.trim().isEmpty) {
      _showErrorSnack('Please enter a track title');
      return;
    }
    if (_artists.isEmpty) {
      _showErrorSnack('Please add at least one artist');
      return;
    }
    if (_selectedFile!.path == null) {
      _showErrorSnack('Audio file path is unavailable');
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
      artists: _artists,
      genre: _genreController.text.trim(),
      tags: tags,
      description: _descriptionController.text.trim(),
      privacy: _privacy == 'unlisted',
      caption: _captionController.text.trim(),
      enableDirectDownload: _enableDirectDownloads,
      offlineListening: _offlineListening,
      includeInRssFeed: _includeInRssFeed,
      displayedEmbedCode: _displayEmbedCode,
      enableAppPlayback: _enableAppPlayback,
      licensing: _licensing,
      containsExplicit: _containsExplicitContent,
      releaseDate: _enableReleaseDate ? _releaseDate.toIso8601String() : null,
      recordLabel: _recordLabelController.text.trim().isNotEmpty
          ? _recordLabelController.text.trim()
          : null,
      publisher: _publisherController.text.trim().isNotEmpty
          ? _publisherController.text.trim()
          : null,
      isrc: _isrcController.text.trim().isNotEmpty
          ? _isrcController.text.trim()
          : null,
      pLine: _pLineController.text.trim().isNotEmpty
          ? _pLineController.text.trim()
          : null,
      availability: _availability,
      geoBlockingRegions: _selectedRegions,
      geoBlockingCountries: _selectedCountries,
      mobileProPreview: _mobileProPreview,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.$1 == 201) {
      final resultData = result.$2 is Map<String, dynamic>
          ? result.$2 as Map<String, dynamic>
          : null;
      final serverId = resultData?['trackId'] as String?;

      await _audioService.saveTrackData(_selectedFile!, {
        'title': _titleController.text.trim(),
        'genre': _genreController.text.trim(),
        'description': _descriptionController.text.trim(),
        'caption': _captionController.text.trim(),
        'tags': _tagsController.text.trim(),
        'visibility': _privacy,
        'coverImagePath': _coverImage?.path,
      }, serverId: serverId);

      if (!mounted) return;

      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      final trackTitle = _titleController.text.trim();
      navigator.pop();

      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.containerMid,
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
                color: AppColors.primaryOrange,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Upload Successful',
                      style: TextStyle(
                        color: AppColors.whiteSmoke,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      trackTitle,
                      style: TextStyle(
                        color: AppColors.whiteSmoke,
                        fontSize: 12,
                      ),
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
                    color: AppColors.primaryOrange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'SEE TRACK',
                    style: TextStyle(
                      color: AppColors.whiteSmoke,
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
      _showErrorSnack(
        result.$2.toString().isNotEmpty
            ? result.$2.toString()
            : 'Upload failed. Please try again.',
      );
    }
  }

  Future<void> _updateExistingTrack() async {
    final track = _editingTrack!;
    if (_titleController.text.trim().isEmpty) {
      _showErrorSnack('Please enter a track title');
      return;
    }
    if (track.serverId == null || track.serverId!.trim().isEmpty) {
      _showErrorSnack('Cannot update: server ID not available for this track.');
      return;
    }

    setState(() => _isSaving = true);

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final result = await _trackApiService.updateTrack(
      trackId: track.serverId!,
      imageFilePath: _coverImage?.path,
      title: _titleController.text.trim(),
      mainArtists: _artists.isNotEmpty ? _artists : null,
      genre: _genreController.text.trim().isNotEmpty
          ? _genreController.text.trim()
          : null,
      tags: tags.isNotEmpty ? tags : null,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      isPrivate: _privacy == 'unlisted',
      caption: _captionController.text.trim().isNotEmpty
          ? _captionController.text.trim()
          : null,
      enableDirectDownload: _enableDirectDownloads,
      offlineListening: _offlineListening,
      includeInRssFeed: _includeInRssFeed,
      displayedEmbedCode: _displayEmbedCode,
      enableAppPlayback: _enableAppPlayback,
      licensing: _licensing,
      containsExplicit: _containsExplicitContent,
      releaseDate: _enableReleaseDate ? _releaseDate.toIso8601String() : null,
      recordLabel: _recordLabelController.text.trim().isNotEmpty
          ? _recordLabelController.text.trim()
          : null,
      publisher: _publisherController.text.trim().isNotEmpty
          ? _publisherController.text.trim()
          : null,
      isrc: _isrcController.text.trim().isNotEmpty
          ? _isrcController.text.trim()
          : null,
      pLine: _pLineController.text.trim().isNotEmpty
          ? _pLineController.text.trim()
          : null,
      availability: _availability,
      geoBlockingRegions: _selectedRegions,
      geoBlockingCountries: _selectedCountries,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.$1 == 200) {
      if (track.serverId != null) {
        await _trackApiService.updateMobileProPreview(
          trackId: track.serverId!,
          mobileProPreview: _mobileProPreview,
        );
      }
      if (!mounted) return;
      final updated = track.copyWith(
        title: _titleController.text.trim(),
        genre: _genreController.text.trim(),
        descriptiveTags: tags,
        description: _descriptionController.text.trim(),
        caption: _captionController.text.trim(),
        visibility: _privacy == 'unlisted'
            ? TrackVisibility.unlisted
            : TrackVisibility.public,
        coverImagePath: _coverImage?.path ?? track.coverImagePath,
      );

      final list = List<TrackModel>.from(
        AudioUploadService.globalMockTracksNotifier.value,
      );
      final idx = list.indexWhere((t) => t.id == track.id);
      if (idx != -1) list[idx] = updated;
      AudioUploadService.globalMockTracksNotifier.value = list;

      if (!mounted) return;
      Navigator.pop(context);
      _showSuccessSnack(
        'Track Updated',
        subtitle: _titleController.text.trim(),
      );
    } else {
      _showErrorSnack(
        result.$2.toString().isNotEmpty
            ? result.$2.toString()
            : 'Update failed. Please try again.',
      );
    }
  }

  Widget _coverPlaceholder() {
    return CustomPaint(
      painter: DashedRectPainter(
        color: AppColors.white54,
        strokeWidth: 1.5,
        gap: 6,
      ),
      child: Container(
        width: 90,
        height: 90,
        alignment: Alignment.center,
        child: Icon(
          Icons.camera_alt_outlined,
          color: AppColors.whiteSmoke,
          size: 28,
        ),
      ),
    );
  }

  void _showSuccessSnack(String title, {String? subtitle}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.containerMid,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        elevation: 10,
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.primaryOrange, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.whiteSmoke,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: AppColors.white70, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.errorContainerDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        elevation: 10,
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.errorRed, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: AppColors.whiteSmoke, fontSize: 13),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
      backgroundColor: AppColors.container,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ListView.builder(
        itemCount: genres.length,
        itemBuilder: (_, i) => ListTile(
          title: Text(genres[i], style: TextStyle(color: AppColors.whiteSmoke)),
          trailing: _genreController.text == genres[i]
              ? const Icon(Icons.check, color: AppColors.primaryOrange)
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
          colorScheme: ColorScheme.dark(
            primary: AppColors.datepickerGreen,
            onPrimary: AppColors.whiteSmoke,
            surface: AppColors.surfaceMid,
            onSurface: AppColors.whiteSmoke,
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
    context.watch<ThemeService>();
    return ValueListenableBuilder<SubscriptionState>(
      valueListenable: PaymentService.subscriptionSuccessNotifier,
      builder: (context, state, _) {
        final isPro = state.isPro;
        return Scaffold(
          backgroundColor: AppColors.backgroundDark3,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundDark3,
            elevation: 0,
            leadingWidth: 80,
            leading: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.white70, fontSize: 16),
              ),
            ),
            title: Text(
              (_editingTrack != null || _editingServerTrack != null)
                  ? 'Update Track'
                  : 'Upload',
              style: TextStyle(
                color: AppColors.whiteSmoke,
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
                    decoration: BoxDecoration(
                      color: AppColors.uploadProgressBg,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_uploadStepsCompleted/4',
                      style: TextStyle(
                        color: AppColors.flashPurple,
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
                          if (_currentTabIndex != 0 && !isPro)
                            _buildProBanner(),
                          if (_currentTabIndex != 0 && !isPro)
                            const SizedBox(height: 20),
                          if (_currentTabIndex == 0)
                            _buildTrackInfoTab(context, isPro),
                          if (_currentTabIndex == 1) _buildAdvancedTab(context),
                          if (_currentTabIndex == 2)
                            _buildPermissionsTab(isPro),
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
        border: Border.all(color: AppColors.white24),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _tabItem(0, 'Track Info'),
          Container(width: 1, height: 20, color: AppColors.white24),
          _tabItem(1, 'Advanced'),
          Container(width: 1, height: 20, color: AppColors.white24),
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
            color: sel ? AppColors.white12 : Colors.transparent,
            borderRadius: BorderRadius.horizontal(
              left: index == 0 ? const Radius.circular(20) : Radius.zero,
              right: index == 2 ? const Radius.circular(20) : Radius.zero,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: sel ? AppColors.whiteSmoke : AppColors.white54,
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _coverImage != null
                    ? Image.file(
                        File(_coverImage!.path!),
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      )
                    : _editingServerTrack?.imageUrl != null
                    ? Image.network(
                        _editingServerTrack!.imageUrl!,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) =>
                            _coverPlaceholder(),
                      )
                    : _coverPlaceholder(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filename',
                    style: TextStyle(color: AppColors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _selectedFileName ?? 'Tap below to select track',
                    style: TextStyle(
                      color: AppColors.whiteSmoke,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  if (_editingTrack != null || _editingServerTrack != null)
                    Icon(Icons.lock_outline, color: AppColors.white54, size: 20)
                  else if (_selectedFile == null)
                    GestureDetector(
                      onTap: _pickAndUploadFile,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.whiteSmoke),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Select File',
                          style: TextStyle(
                            color: AppColors.whiteSmoke,
                            fontSize: 12,
                          ),
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
                              border: Border.all(color: AppColors.whiteSmoke),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Replace',
                              style: TextStyle(
                                color: AppColors.whiteSmoke,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.check_circle,
                          color: AppColors.successGreen,
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
        Text(
          'Privacy',
          style: TextStyle(color: AppColors.white70, fontSize: 12),
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
              color: AppColors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_filled,
                  color: AppColors.white54,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Schedule your release with ',
                  style: TextStyle(color: AppColors.white54, fontSize: 14),
                ),
                Text(
                  'Artist Pro',
                  style: TextStyle(
                    color: AppColors.white54,
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
          style: TextStyle(
            color: isPro ? AppColors.white70 : AppColors.white54,
            fontSize: 12,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Set date and time to make your\ntrack public (Artist Pro).',
                style: TextStyle(
                  color: isPro ? AppColors.whiteSmoke : AppColors.white54,
                  fontSize: 12,
                ),
              ),
            ),
            if (isPro)
              CupertinoSwitch(
                value: _enableReleaseDate,
                activeTrackColor: AppColors.successGreen,
                onChanged: (v) => setState(() => _enableReleaseDate = v),
              )
            else
              ProDisabledSwitch(onTap: _showProModal),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Your track stays private until release.',
          style: TextStyle(
            color: isPro ? AppColors.white54 : AppColors.white54,
            fontSize: 12,
          ),
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
                _formatDate(
                  isPro && _enableReleaseDate ? _releaseDate : _scheduleDate,
                ),
                style: TextStyle(
                  color: isPro && _enableReleaseDate
                      ? AppColors.whiteSmoke
                      : AppColors.white54,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              _scheduleTime.format(context),
              style: TextStyle(
                color: isPro && _enableReleaseDate
                    ? AppColors.whiteSmoke
                    : AppColors.white54,
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
        color: AppColors.successContainerDark,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: _uploadProgress / 100,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.datepickerGreen,
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
                  style: TextStyle(
                    color: AppColors.whiteSmoke,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                GestureDetector(
                  onTap: _cancelUpload,
                  child: Icon(
                    Icons.close,
                    color: AppColors.whiteSmoke,
                    size: 14,
                  ),
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
                  ? AppColors.errorSoft
                  : AppColors.white70,
              fontSize: 12,
            ),
            children: const [
              TextSpan(
                text: '*',
                style: TextStyle(color: AppColors.anger),
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
                    style: TextStyle(
                      color: AppColors.pureBlack,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: AppColors.white12,
                  deleteIcon: Icon(
                    Icons.close,
                    color: AppColors.pureBlack,
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
          style: TextStyle(color: AppColors.white54, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Add artist name',
            hintStyle: TextStyle(color: AppColors.white54, fontSize: 16),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.white54),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            isDense: true,
            suffixIcon: IconButton(
              icon: Icon(Icons.add, color: AppColors.white54),
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
              style: TextStyle(color: AppColors.errorSoft, fontSize: 12),
            ),
          ),
        Divider(color: AppColors.white24, height: 24),
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
          controller: _recordLabelController,
          hint: 'Add your record label if applicable',
        ),
        const SizedBox(height: 24),
        Text(
          'Release date',
          style: TextStyle(color: AppColors.white70, fontSize: 12),
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
                  color: _enableReleaseDate
                      ? AppColors.whiteSmoke
                      : AppColors.white54,
                  fontSize: 16,
                ),
              ),
            ),
            CupertinoSwitch(
              value: _enableReleaseDate,
              activeTrackColor: AppColors.successGreen,
              onChanged: (v) => setState(() => _enableReleaseDate = v),
            ),
          ],
        ),
        Divider(color: AppColors.white24, height: 24),
        const SizedBox(height: 8),
        _inputField('Publisher ⓘ', controller: _publisherController, hint: 'Add your publisher if you have one'),
        const SizedBox(height: 24),
        _inputField('ISRC ⓘ', controller: _isrcController, hint: 'e.g. USABC2312345'),
        const SizedBox(height: 24),
        Text(
          'Content warning',
          style: TextStyle(color: AppColors.white70, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  color: AppColors.whiteSmoke,
                  child: Text(
                    'E',
                    style: TextStyle(
                      color: AppColors.pureBlack,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Contains explicit content',
                  style: TextStyle(color: AppColors.whiteSmoke, fontSize: 14),
                ),
              ],
            ),
            CupertinoSwitch(
              value: _containsExplicitContent,
              activeTrackColor: AppColors.successGreen,
              onChanged: (v) => setState(() => _containsExplicitContent = v),
            ),
          ],
        ),
        Divider(color: AppColors.white24, height: 24),
        const SizedBox(height: 8),
        _inputField('P line ⓘ', controller: _pLineController, hint: 'e.g. 2024 [Owner Name]'),
      ],
    );
  }

  Widget _buildPermissionsTab(bool isPro) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Access Settings',
          style: TextStyle(color: AppColors.white54, fontSize: 12),
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
          'Choose whether this track is playable outside of Beatza.',
          _enableAppPlayback,
          (v) => setState(() => _enableAppPlayback = v),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Engagement privacy',
              style: TextStyle(color: AppColors.white70, fontSize: 14),
            ),
            if (!isPro)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.proFeatureBadgeBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.star, color: AppColors.primaryOrange, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Unlock with Artist Pro',
                      style: TextStyle(
                        color: AppColors.primaryOrange,
                        fontSize: 10,
                      ),
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
            Text(
              'Availability',
              style: TextStyle(color: AppColors.white70, fontSize: 14),
            ),
            if (!isPro)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.proFeatureBadgeBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.star, color: AppColors.primaryOrange, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Unlock with Artist Pro',
                      style: TextStyle(
                        color: AppColors.primaryOrange,
                        fontSize: 10,
                      ),
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
          onTap: isPro
              ? () => setState(() => _availability = 'exclusive')
              : _showProModal,
          isPro: isPro,
        ),
        ProRadioTile(
          title: 'Blocked regions',
          selected: _availability == 'blocked',
          onTap: isPro
              ? () => setState(() => _availability = 'blocked')
              : _showProModal,
          isPro: isPro,
        ),
        if (isPro && _availability != 'worldwide') ...[
          const SizedBox(height: 12),
          _buildGeoSelector(),
        ],
        const SizedBox(height: 16),
        // ── Mobile Pro Preview ────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mobile Pro Preview',
              style: TextStyle(color: AppColors.white70, fontSize: 14),
            ),
            if (!isPro)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.proFeatureBadgeBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.star, color: AppColors.primaryOrange, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Unlock with Artist Pro',
                      style: TextStyle(
                        color: AppColors.primaryOrange,
                        fontSize: 10,
                      ),
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
              'Enable mobile pro preview',
              'Allow a mobile preview of this track for Pro listeners.',
              _mobileProPreview,
              (v) {
                if (isPro) setState(() => _mobileProPreview = v);
              },
              disabled: !isPro,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Licensing',
          style: TextStyle(color: AppColors.white54, fontSize: 12),
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
          color: AppColors.surfaceMid,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.uploadGlowPurple.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.flash_on, color: AppColors.white54, size: 16),
            ),
            const SizedBox(width: 12),
            Text(
              'Amplify your track with ',
              style: TextStyle(color: AppColors.white54, fontSize: 14),
            ),
            Text(
              'Artist Pro',
              style: TextStyle(
                color: AppColors.white54,
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
        Text(label, style: TextStyle(color: AppColors.white54, fontSize: 12)),
        TextField(
          controller: controller,
          onChanged: onChanged,
          style: TextStyle(color: AppColors.white54, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.white54, fontSize: 16),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.white54),
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
          Text(label, style: TextStyle(color: AppColors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: value == 'Help fans discover your track'
                      ? AppColors.white54
                      : AppColors.whiteSmoke,
                  fontSize: 16,
                ),
              ),
              Icon(Icons.unfold_more, color: AppColors.white54, size: 20),
            ],
          ),
          Divider(color: AppColors.white24, height: 16),
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
                    style: TextStyle(
                      color: AppColors.whiteSmoke,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.white54,
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
                color: sel ? AppColors.whiteSmoke : Colors.transparent,
                border: Border.all(
                  color: sel ? AppColors.whiteSmoke : AppColors.white54,
                  width: 1.5,
                ),
              ),
              child: sel
                  ? Icon(Icons.check, color: AppColors.pureBlack, size: 14)
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
                    color: disabled ? AppColors.white54 : AppColors.whiteSmoke,
                    fontSize: 14,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: disabled ? AppColors.white24 : AppColors.white54,
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
            activeTrackColor: AppColors.successGreen,
            inactiveTrackColor: AppColors.white24,
            onChanged: disabled ? null : onChange,
          ),
        ],
      ),
    );
  }

  void _showGeoBlockingPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.container,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, controller) => _GeoBlockingSheet(
          initialRegions: Set.from(_selectedRegions),
          initialCountries: Set.from(_selectedCountries),
          scrollController: controller,
          onSave: (regions, countries) => setState(() {
            _selectedRegions = regions.toList();
            _selectedCountries = countries.toList();
          }),
        ),
      ),
    );
  }

  Widget _buildGeoSelector() {
    final hasSelections =
        _selectedRegions.isNotEmpty || _selectedCountries.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasSelections) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ..._selectedRegions.map((r) => _geoChip(r, isRegion: true)),
              ..._selectedCountries.map((c) => _geoChip(c, isRegion: false)),
            ],
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showGeoBlockingPicker,
            icon: Icon(
              Icons.add_location_alt_outlined,
              color: AppColors.white54,
              size: 16,
            ),
            label: Text(
              'Add continent or country',
              style: TextStyle(color: AppColors.white54, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.white24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _geoChip(String key, {required bool isRegion}) {
    return Chip(
      label: Text(
        _displayGeoName(key),
        style: TextStyle(
          color: AppColors.pureBlack,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor:
          isRegion ? AppColors.primaryOrange : AppColors.whiteSmoke,
      deleteIcon: Icon(Icons.close, size: 14, color: AppColors.black54),
      onDeleted: () => setState(() {
        if (isRegion) {
          _selectedRegions.remove(key);
        } else {
          _selectedCountries.remove(key);
        }
      }),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
    );
  }

  Future<void> _deleteTrack() async {
    final trackId = _editingServerTrack?.id ?? _editingTrack?.serverId;
    if (trackId == null || trackId.trim().isEmpty) {
      _showErrorSnack('Cannot delete: track ID is missing.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.containerMid,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Track',
          style: TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${_titleController.text.trim()}"? This cannot be undone.',
          style: TextStyle(color: AppColors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    final result = await _trackApiService.deleteTrack(trackId: trackId);
    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (result.$1 == 200) {
      Navigator.pop(context);
      _showSuccessSnack('Track Deleted', subtitle: _titleController.text.trim());
    } else {
      _showErrorSnack(
        result.$2.toString().isNotEmpty
            ? result.$2.toString()
            : 'Delete failed. Please try again.',
      );
    }
  }

  Widget _buildSaveButton() {
    final isEditing = _editingTrack != null || _editingServerTrack != null;
    final ready =
        isEditing || (_selectedFile != null && _uploadComplete);
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: (ready && !_isSaving && !_isDeleting) ? _saveTrack : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: ready ? AppColors.whiteSmoke : AppColors.white10,
              disabledBackgroundColor: _isSaving
                  ? AppColors.whiteSmoke
                  : AppColors.white10,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.pureBlack,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: ready ? AppColors.pureBlack : AppColors.white54,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        if (isEditing) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: (_isSaving || _isDeleting) ? null : _deleteTrack,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.errorRed),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.errorRed,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                'Delete Track',
                style: TextStyle(
                  color: _isSaving ? AppColors.white54 : AppColors.errorRed,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Confirm your sounds comply with our Terms.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.white54, fontSize: 11),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ArtistTermsScreen()),
          ),
          child: Text(
            'TERMS OF USE',
            style: TextStyle(
              color: AppColors.white54,
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

// ── Geo-blocking picker ───────────────────────────────────────────────────────

class _GeoItem {
  final String key;
  final String display;
  final bool isRegion;
  const _GeoItem({
    required this.key,
    required this.display,
    required this.isRegion,
  });
}

class _GeoBlockingSheet extends StatefulWidget {
  final Set<String> initialRegions;
  final Set<String> initialCountries;
  final ScrollController scrollController;
  final void Function(Set<String> regions, Set<String> countries) onSave;

  const _GeoBlockingSheet({
    required this.initialRegions,
    required this.initialCountries,
    required this.scrollController,
    required this.onSave,
  });

  @override
  State<_GeoBlockingSheet> createState() => _GeoBlockingSheetState();
}

class _GeoBlockingSheetState extends State<_GeoBlockingSheet> {
  late Set<String> _regions;
  late Set<String> _countries;
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _regions = Set.from(widget.initialRegions);
    _countries = Set.from(widget.initialCountries);
    _search.addListener(
      () => setState(() => _query = _search.text.toLowerCase().trim()),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<_GeoItem> _buildItems() {
    final items = <_GeoItem>[];
    for (final region in _kGeoRegions) {
      final regionDisplay = _displayGeoName(region);
      final countries = _kRegionCountries[region] ?? [];
      final regionMatches =
          _query.isEmpty || regionDisplay.toLowerCase().contains(_query);
      final matchingCountries = regionMatches
          ? countries
          : countries
              .where(
                (c) => _displayGeoName(c).toLowerCase().contains(_query),
              )
              .toList();

      if (!regionMatches && matchingCountries.isEmpty) continue;

      items.add(
        _GeoItem(key: region, display: regionDisplay, isRegion: true),
      );
      for (final country in matchingCountries) {
        items.add(
          _GeoItem(
            key: country,
            display: _displayGeoName(country),
            isRegion: false,
          ),
        );
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildItems();
    final selectedCount = _regions.length + _countries.length;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 4),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Regions & Countries',
                style: TextStyle(
                  color: AppColors.whiteSmoke,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  widget.onSave(_regions, _countries);
                  Navigator.pop(context);
                },
                child: Text(
                  selectedCount > 0 ? 'Done ($selectedCount)' : 'Done',
                  style: TextStyle(
                    color: AppColors.primaryOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: _search,
            style: TextStyle(color: AppColors.whiteSmoke, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Add continent or country',
              hintStyle: TextStyle(color: AppColors.white54, fontSize: 14),
              prefixIcon: Icon(
                Icons.search,
                color: AppColors.white54,
                size: 20,
              ),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.close,
                        color: AppColors.white54,
                        size: 18,
                      ),
                      onPressed: _search.clear,
                    )
                  : null,
              filled: true,
              fillColor: AppColors.white10,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    'No results',
                    style: TextStyle(color: AppColors.white54),
                  ),
                )
              : ListView.builder(
                  controller: widget.scrollController,
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final sel = item.isRegion
                        ? _regions.contains(item.key)
                        : _countries.contains(item.key);
                    return ListTile(
                      contentPadding: EdgeInsets.only(
                        left: item.isRegion ? 16 : 36,
                        right: 16,
                      ),
                      leading: item.isRegion
                          ? Icon(
                              Icons.public,
                              color: sel
                                  ? AppColors.primaryOrange
                                  : AppColors.white54,
                              size: 18,
                            )
                          : null,
                      title: Text(
                        item.display,
                        style: TextStyle(
                          color: sel
                              ? AppColors.primaryOrange
                              : AppColors.whiteSmoke,
                          fontSize: item.isRegion ? 15 : 14,
                          fontWeight: item.isRegion
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: sel
                          ? Icon(
                              Icons.check,
                              color: AppColors.primaryOrange,
                              size: 18,
                            )
                          : null,
                      tileColor:
                          sel ? AppColors.white10 : Colors.transparent,
                      onTap: () => setState(() {
                        if (item.isRegion) {
                          if (sel) {
                            _regions.remove(item.key);
                          } else {
                            _regions.add(item.key);
                          }
                        } else {
                          if (sel) {
                            _countries.remove(item.key);
                          } else {
                            _countries.add(item.key);
                          }
                        }
                      }),
                    );
                  },
                ),
        ),
        if (selectedCount > 0)
          Container(
            constraints: const BoxConstraints(maxHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.white12)),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._regions.map((r) => _chip(r, isRegion: true)),
                ..._countries.map((c) => _chip(c, isRegion: false)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _chip(String key, {required bool isRegion}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Chip(
        label: Text(
          _displayGeoName(key),
          style: TextStyle(
            color: AppColors.pureBlack,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor:
            isRegion ? AppColors.primaryOrange : AppColors.whiteSmoke,
        deleteIcon: Icon(Icons.close, size: 14, color: AppColors.black54),
        onDeleted: () => setState(() {
          if (isRegion) {
            _regions.remove(key);
          } else {
            _countries.remove(key);
          }
        }),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
      ),
    );
  }
}
