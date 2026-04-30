import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/library/models/content_settings_model.dart';
import 'package:cross_team5/features/library/services/content_settings_api_service.dart';

class ContentSettingsScreen extends StatefulWidget {
  const ContentSettingsScreen({super.key});

  @override
  State<ContentSettingsScreen> createState() => _ContentSettingsScreenState();
}

class _ContentSettingsScreenState extends State<ContentSettingsScreen> {
  final _api = ContentSettingsApiService();
  final _auth = AuthApiService();

  bool _loading = true;
  bool _saving = false;
  bool _isDirty = false;
  String? _error;

  // Text controllers
  late final TextEditingController _rssFeedLinkCtrl;
  late final TextEditingController _rssEmailCtrl;
  late final TextEditingController _customFieldTitleCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _statsUrlCtrl;
  late final TextEditingController _customAuthorCtrl;
  late final TextEditingController _languageCtrl;
  late final TextEditingController _subscriberRedirectCtrl;

  // Bool state
  bool _containsExplicit = false;
  bool _includeInRss = false;
  bool _creativeCommons = false;

  // Inline validation errors for URL fields
  String? _rssFeedLinkError;
  String? _statsUrlError;
  String? _subscriberRedirectError;

  bool get _hasValidationErrors =>
      _rssFeedLinkError != null ||
      _statsUrlError != null ||
      _subscriberRedirectError != null;

  static String? _validateUrl(String value) {
    if (value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'Enter a valid URL (e.g. https://example.com)';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _rssFeedLinkCtrl = TextEditingController();
    _rssEmailCtrl = TextEditingController();
    _customFieldTitleCtrl = TextEditingController();
    _categoryCtrl = TextEditingController();
    _statsUrlCtrl = TextEditingController();
    _customAuthorCtrl = TextEditingController();
    _languageCtrl = TextEditingController();
    _subscriberRedirectCtrl = TextEditingController();

    for (final c in _allControllers) {
      c.addListener(_markDirty);
    }

    _load();
  }

  List<TextEditingController> get _allControllers => [
        _rssFeedLinkCtrl,
        _rssEmailCtrl,
        _customFieldTitleCtrl,
        _categoryCtrl,
        _statsUrlCtrl,
        _customAuthorCtrl,
        _languageCtrl,
        _subscriberRedirectCtrl,
      ];

  void _markDirty() {
    if (mounted) {
      setState(() {
        _isDirty = true;
        _rssFeedLinkError = _validateUrl(_rssFeedLinkCtrl.text.trim());
        _statsUrlError = _validateUrl(_statsUrlCtrl.text.trim());
        _subscriberRedirectError =
            _validateUrl(_subscriberRedirectCtrl.text.trim());
      });
    }
  }

  @override
  void dispose() {
    for (final c in _allControllers) {
      c.dispose();
    }
    _api.dispose();
    super.dispose();
  }

  void _populateControllers(ContentSettings s) {
    _rssFeedLinkCtrl.text = s.rssFeedLink ?? '';
    _rssEmailCtrl.text = s.rssEmailDisplayed ?? '';
    _customFieldTitleCtrl.text = s.customFieldTitle ?? '';
    _categoryCtrl.text = s.category ?? '';
    _statsUrlCtrl.text = s.statsServiceUrlPrefix ?? '';
    _customAuthorCtrl.text = s.customAuthorName ?? '';
    _languageCtrl.text = s.language ?? '';
    _subscriberRedirectCtrl.text = s.subscriberRedirect ?? '';
    _containsExplicit = s.containsExplicitContent;
    _includeInRss = s.includeInRssFeed;
    _creativeCommons = s.creativeCommonsLicense;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await _auth.getStoredAccessToken();
      if (token == null) throw Exception('Not authenticated');
      final settings = await _api.getSettings(token);
      if (mounted) {
        // Temporarily remove listeners to avoid marking dirty during init
        for (final c in _allControllers) {
          c.removeListener(_markDirty);
        }
        _populateControllers(settings);
        for (final c in _allControllers) {
          c.addListener(_markDirty);
        }
        setState(() {
          _loading = false;
          _isDirty = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  ContentSettings _buildFromControllers() => ContentSettings(
        rssFeedLink: _rssFeedLinkCtrl.text.trim(),
        rssEmailDisplayed: _rssEmailCtrl.text.trim(),
        customFieldTitle: _customFieldTitleCtrl.text.trim(),
        category: _categoryCtrl.text.trim(),
        statsServiceUrlPrefix: _statsUrlCtrl.text.trim(),
        customAuthorName: _customAuthorCtrl.text.trim(),
        language: _languageCtrl.text.trim(),
        subscriberRedirect: _subscriberRedirectCtrl.text.trim(),
        containsExplicitContent: _containsExplicit,
        includeInRssFeed: _includeInRss,
        creativeCommonsLicense: _creativeCommons,
      );

  Future<void> _save() async {
    if (_saving || _hasValidationErrors) return;
    setState(() => _saving = true);
    try {
      final token = await _auth.getStoredAccessToken();
      if (token == null) throw Exception('Not authenticated');

      debugPrint('[ContentSettings] saving: ${_buildFromControllers().toJson()}');
      final confirmed = await _api.updateSettings(token, _buildFromControllers());
      debugPrint('[ContentSettings] confirmed: ${confirmed.toJson()}');

      if (mounted) {
        // Repopulate with what the server confirmed so we stay in sync
        for (final c in _allControllers) {
          c.removeListener(_markDirty);
        }
        _populateControllers(confirmed);
        for (final c in _allControllers) {
          c.addListener(_markDirty);
        }

        setState(() {
          _saving = false;
          _isDirty = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF1E1E1E),
          ),
        );
      }
    } catch (e) {
      debugPrint('[ContentSettings] save error: $e');
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save. Please try again.'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_loading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.brilliantOrange),
                ),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(
                            color: AppColors.white60, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Retry',
                            style: TextStyle(
                                color: AppColors.brilliantOrange)),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        title: 'RSS Feed',
                        children: [
                          _ContentTextTile(
                            label: 'RSS feed link',
                            controller: _rssFeedLinkCtrl,
                            hint: 'https://example.com/feed',
                            keyboardType: TextInputType.url,
                            errorText: _rssFeedLinkError,
                          ),
                          _divider(),
                          _ContentTextTile(
                            label: 'RSS email displayed',
                            controller: _rssEmailCtrl,
                            hint: 'contact@example.com',
                            keyboardType: TextInputType.emailAddress,
                          ),
                          _divider(),
                          _ContentToggleRow(
                            icon: Icons.rss_feed_rounded,
                            label: 'Include in RSS feed',
                            subtitle:
                                'Make your content available in the RSS feed for podcast apps.',
                            value: _includeInRss,
                            onChanged: (v) =>
                                setState(() {
                                  _includeInRss = v;
                                  _isDirty = true;
                                }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        title: 'Content Info',
                        children: [
                          _ContentTextTile(
                            label: 'Category',
                            controller: _categoryCtrl,
                            hint: 'e.g. Music, Podcast',
                          ),
                          _divider(),
                          _ContentTextTile(
                            label: 'Language',
                            controller: _languageCtrl,
                            hint: 'e.g. en, ar',
                          ),
                          _divider(),
                          _ContentTextTile(
                            label: 'Custom author name',
                            controller: _customAuthorCtrl,
                            hint: 'Author display name',
                          ),
                          _divider(),
                          _ContentToggleRow(
                            icon: Icons.explicit_rounded,
                            label: 'Contains explicit content',
                            subtitle:
                                'Mark your content as explicit. This may restrict availability on certain platforms.',
                            value: _containsExplicit,
                            onChanged: (v) =>
                                setState(() {
                                  _containsExplicit = v;
                                  _isDirty = true;
                                }),
                          ),
                          _divider(),
                          _ContentToggleRow(
                            icon: Icons.balance_rounded,
                            label: 'Creative Commons license',
                            subtitle:
                                'Allow others to share and adapt your content under a Creative Commons license.',
                            value: _creativeCommons,
                            onChanged: (v) =>
                                setState(() {
                                  _creativeCommons = v;
                                  _isDirty = true;
                                }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        title: 'Advanced',
                        children: [
                          _ContentTextTile(
                            label: 'Custom field title',
                            controller: _customFieldTitleCtrl,
                            hint: 'Custom metadata field name',
                          ),
                          _divider(),
                          _ContentTextTile(
                            label: 'Stats service URL prefix',
                            controller: _statsUrlCtrl,
                            hint: 'https://stats.example.com/',
                            keyboardType: TextInputType.url,
                            errorText: _statsUrlError,
                          ),
                          _divider(),
                          _ContentTextTile(
                            label: 'Subscriber redirect',
                            controller: _subscriberRedirectCtrl,
                            hint: 'https://example.com/subscribe',
                            keyboardType: TextInputType.url,
                            errorText: _subscriberRedirectError,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Divider(
        height: 1,
        color: Color(0xFF2A2A2A),
        indent: 16,
        endIndent: 16,
      );

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: AppColors.whiteSmoke, size: 20),
              ),
            ),
            const Center(
              child: Text(
                'Content',
                style: TextStyle(
                    color: AppColors.whiteSmoke,
                    fontSize: 22,
                    fontWeight: FontWeight.w700),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: _saving
                  ? const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.brilliantOrange),
                      ),
                    )
                  : TextButton(
                      onPressed: (_isDirty && !_hasValidationErrors) ? _save : null,
                      child: Text(
                        'Save',
                        style: TextStyle(
                          color: (_isDirty && !_hasValidationErrors)
                              ? AppColors.brilliantOrange
                              : AppColors.white60,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
              color: AppColors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.tileDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ─── Text input tile ────────────────────────────────────────────────────────

class _ContentTextTile extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final String? errorText;

  const _ContentTextTile({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
                color: hasError ? Colors.redAccent : AppColors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
                color: AppColors.whiteSmoke, fontSize: 14),
            cursorColor: AppColors.brilliantOrange,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                  color: Color(0xFF555555), fontSize: 14),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 8),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: hasError
                          ? Colors.redAccent
                          : const Color(0xFF2A2A2A))),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: hasError
                          ? Colors.redAccent
                          : AppColors.brilliantOrange)),
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: 4),
            Text(
              errorText!,
              style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 11,
                  height: 1.3),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Toggle row ─────────────────────────────────────────────────────────────

class _ContentToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ContentToggleRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, color: AppColors.white60, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      color: AppColors.whiteSmoke,
                      fontSize: 15,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                      color: AppColors.white60,
                      fontSize: 12,
                      height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.brilliantOrange,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFF2A2A2A),
          ),
        ],
      ),
    );
  }
}
