import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/library/models/privacy_settings_model.dart';
import 'package:cross_team5/features/library/services/privacy_settings_api_service.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final _api = PrivacySettingsApiService();
  final _auth = AuthApiService();

  PrivacySettings? _settings;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
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
        setState(() {
          _settings = settings;
          _loading = false;
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

  Future<void> _patch(PrivacySettings updated) async {
    if (_saving) return;
    setState(() {
      _settings = updated;
      _saving = true;
    });
    try {
      final token = await _auth.getStoredAccessToken();
      if (token == null) throw Exception('Not authenticated');
      final confirmed = await _api.updateSettings(token, updated);
      if (mounted) setState(() {
        _settings = confirmed;
        _saving = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
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
                            style:
                                TextStyle(color: AppColors.brilliantOrange)),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection(
                            title: 'Messaging',
                            children: [
                              _PrivacyRow(
                                icon: Icons.chat_bubble_outline_rounded,
                                label: 'Allow messages from anyone',
                                subtitle:
                                    'Anyone can send you direct messages. Turn off to limit to people you follow.',
                                value: _settings!.allowMessagesAnyone,
                                onChanged: (v) => _patch(
                                    _settings!.copyWith(allowMessagesAnyone: v)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildSection(
                            title: 'Discovery',
                            children: [
                              _PrivacyRow(
                                icon: Icons.explore_outlined,
                                label: 'Show activity in discovery',
                                subtitle:
                                    'Your listening activity may appear in discovery and recommendations for others.',
                                value: _settings!.showActivityDiscovery,
                                onChanged: (v) => _patch(_settings!
                                    .copyWith(showActivityDiscovery: v)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildSection(
                            title: 'Top Fans',
                            children: [
                              _PrivacyRow(
                                icon: Icons.star_outline_rounded,
                                label: 'Show as first top fan',
                                subtitle:
                                    'Allow your profile to be highlighted as the first top fan on tracks you support.',
                                value: _settings!.showFirstTopFan,
                                onChanged: (v) => _patch(
                                    _settings!.copyWith(showFirstTopFan: v)),
                              ),
                              const Divider(
                                  height: 1,
                                  color: Color(0xFF2A2A2A),
                                  indent: 16,
                                  endIndent: 16),
                              _PrivacyRow(
                                icon: Icons.people_outline_rounded,
                                label: 'Show track top fans',
                                subtitle:
                                    'Display the top fans list on your uploaded tracks.',
                                value: _settings!.showTrackTopFans,
                                onChanged: (v) => _patch(
                                    _settings!.copyWith(showTrackTopFans: v)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_saving)
                      const Positioned(
                        top: 8,
                        right: 16,
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.brilliantOrange),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

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
                'Privacy',
                style: TextStyle(
                    color: AppColors.whiteSmoke,
                    fontSize: 22,
                    fontWeight: FontWeight.w700),
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

// ─── Single privacy toggle row ─────────────────────────────────────────────────

class _PrivacyRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrivacyRow({
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
