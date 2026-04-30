import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/library/models/notification_settings_model.dart';
import 'package:cross_team5/features/library/services/notification_settings_api_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final _api = NotificationSettingsApiService();
  final _auth = AuthApiService();

  NotificationSettings? _settings;
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
      if (mounted)
        setState(() {
          _settings = settings;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
    }
  }

  Future<void> _patch(NotificationSettings updated) async {
    if (_saving) return;
    setState(() {
      _settings = updated;
      _saving = true;
    });
    try {
      final token = await _auth.getStoredAccessToken();
      if (token == null) throw Exception('Not authenticated');
      final confirmed = await _api.updateSettings(token, updated);
      if (mounted)
        setState(() {
          _settings = confirmed;
          _saving = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _saving = false;
        });
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
                    color: AppColors.brilliantOrange,
                  ),
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
                        style: TextStyle(
                          color: AppColors.white60,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _load,
                        child: const Text(
                          'Retry',
                          style: TextStyle(color: AppColors.brilliantOrange),
                        ),
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
                            title: 'Push Notifications',
                            rows: _buildPushRows(),
                          ),
                          const SizedBox(height: 28),
                          _buildSection(
                            title: 'Email Notifications',
                            rows: _buildEmailRows(),
                          ),
                        ],
                      ),
                    ),
                    if (_saving)
                      Positioned(
                        top: 8,
                        right: 16,
                        child: const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.brilliantOrange,
                          ),
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
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.whiteSmoke,
                  size: 20,
                ),
              ),
            ),
            Center(
              child: Text(
                'Notifications',
                style: TextStyle(
                  color: AppColors.whiteSmoke,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> rows}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.white60,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: AppColors.tileDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }

  List<Widget> _buildPushRows() {
    if (_settings == null) return [];
    final s = _settings!;
    return [
      _NotifRow(
        label: 'New follower',
        hasDevices: NotificationSettings.hasDevices(s.newFollower),
        hasEmail: NotificationSettings.hasEmail(s.newFollower),
        onDeviceToggle: () => _patch(
          s.copyWith(
            newFollower: NotificationSettings.toggleDevices(s.newFollower),
          ),
        ),
        onEmailToggle: () => _patch(
          s.copyWith(
            newFollower: NotificationSettings.toggleEmail(s.newFollower),
          ),
        ),
        showEmail: false,
      ),
      _divider(),
      _NotifRow(
        label: 'Repost of your post',
        hasDevices: NotificationSettings.hasDevices(s.repostOfYourPost),
        hasEmail: NotificationSettings.hasEmail(s.repostOfYourPost),
        onDeviceToggle: () => _patch(
          s.copyWith(
            repostOfYourPost: NotificationSettings.toggleDevices(
              s.repostOfYourPost,
            ),
          ),
        ),
        onEmailToggle: () => _patch(
          s.copyWith(
            repostOfYourPost: NotificationSettings.toggleEmail(
              s.repostOfYourPost,
            ),
          ),
        ),
        showEmail: false,
      ),
      _divider(),
      _NotifRow(
        label: 'New post by followed user',
        hasDevices: NotificationSettings.hasDevices(s.newPostByFollowedUser),
        hasEmail: NotificationSettings.hasEmail(s.newPostByFollowedUser),
        onDeviceToggle: () => _patch(
          s.copyWith(
            newPostByFollowedUser: NotificationSettings.toggleDevices(
              s.newPostByFollowedUser,
            ),
          ),
        ),
        onEmailToggle: () => _patch(
          s.copyWith(
            newPostByFollowedUser: NotificationSettings.toggleEmail(
              s.newPostByFollowedUser,
            ),
          ),
        ),
        showEmail: false,
      ),
      _divider(),
      _NotifRow(
        label: 'Likes & plays on your post',
        hasDevices: NotificationSettings.hasDevices(s.likesAndPlaysOnYourPost),
        hasEmail: NotificationSettings.hasEmail(s.likesAndPlaysOnYourPost),
        onDeviceToggle: () => _patch(
          s.copyWith(
            likesAndPlaysOnYourPost: NotificationSettings.toggleDevices(
              s.likesAndPlaysOnYourPost,
            ),
          ),
        ),
        onEmailToggle: () => _patch(
          s.copyWith(
            likesAndPlaysOnYourPost: NotificationSettings.toggleEmail(
              s.likesAndPlaysOnYourPost,
            ),
          ),
        ),
        showEmail: false,
      ),
      _divider(),
      _NotifRow(
        label: 'Comment on your post',
        hasDevices: NotificationSettings.hasDevices(s.commentOnYourPost),
        hasEmail: NotificationSettings.hasEmail(s.commentOnYourPost),
        onDeviceToggle: () => _patch(
          s.copyWith(
            commentOnYourPost: NotificationSettings.toggleDevices(
              s.commentOnYourPost,
            ),
          ),
        ),
        onEmailToggle: () => _patch(
          s.copyWith(
            commentOnYourPost: NotificationSettings.toggleEmail(
              s.commentOnYourPost,
            ),
          ),
        ),
        showEmail: false,
      ),
      _divider(),
      _NotifRow(
        label: 'Recommended content',
        hasDevices: NotificationSettings.hasDevices(s.recommendedContent),
        hasEmail: NotificationSettings.hasEmail(s.recommendedContent),
        onDeviceToggle: () => _patch(
          s.copyWith(
            recommendedContent: NotificationSettings.toggleDevices(
              s.recommendedContent,
            ),
          ),
        ),
        onEmailToggle: () => _patch(
          s.copyWith(
            recommendedContent: NotificationSettings.toggleEmail(
              s.recommendedContent,
            ),
          ),
        ),
        showEmail: false,
      ),
      _divider(),
      _NewMessageRow(
        deviceValue: s.newMessageDevices,
        onDeviceChanged: (val) => _patch(s.copyWith(newMessageDevices: val)),
      ),
    ];
  }

  List<Widget> _buildEmailRows() {
    if (_settings == null) return [];
    final s = _settings!;
    return [
      // Add the 5 items from push notifications to email section
      _NotifRow(
        label: 'New follower',
        hasDevices: NotificationSettings.hasDevices(s.newFollower),
        hasEmail: NotificationSettings.hasEmail(s.newFollower),
        onDeviceToggle: () => _patch(
          s.copyWith(
            newFollower: NotificationSettings.toggleDevices(s.newFollower),
          ),
        ),
        onEmailToggle: () => _patch(
          s.copyWith(
            newFollower: NotificationSettings.toggleEmail(s.newFollower),
          ),
        ),
        showEmail: true,
        showDevice: false,
      ),
      _divider(),
      _NotifRow(
        label: 'Repost of your post',
        hasDevices: NotificationSettings.hasDevices(s.repostOfYourPost),
        hasEmail: NotificationSettings.hasEmail(s.repostOfYourPost),
        onDeviceToggle: () => _patch(
          s.copyWith(
            repostOfYourPost: NotificationSettings.toggleDevices(
              s.repostOfYourPost,
            ),
          ),
        ),
        onEmailToggle: () => _patch(
          s.copyWith(
            repostOfYourPost: NotificationSettings.toggleEmail(
              s.repostOfYourPost,
            ),
          ),
        ),
        showEmail: true,
        showDevice: false,
      ),
      _divider(),
      _NotifRow(
        label: 'New post by followed user',
        hasDevices: NotificationSettings.hasDevices(s.newPostByFollowedUser),
        hasEmail: NotificationSettings.hasEmail(s.newPostByFollowedUser),
        onDeviceToggle: () => _patch(
          s.copyWith(
            newPostByFollowedUser: NotificationSettings.toggleDevices(
              s.newPostByFollowedUser,
            ),
          ),
        ),
        onEmailToggle: () => _patch(
          s.copyWith(
            newPostByFollowedUser: NotificationSettings.toggleEmail(
              s.newPostByFollowedUser,
            ),
          ),
        ),
        showEmail: true,
        showDevice: false,
      ),
      _divider(),
      _NotifRow(
        label: 'Likes & plays on your post',
        hasDevices: NotificationSettings.hasDevices(s.likesAndPlaysOnYourPost),
        hasEmail: NotificationSettings.hasEmail(s.likesAndPlaysOnYourPost),
        onDeviceToggle: () => _patch(
          s.copyWith(
            likesAndPlaysOnYourPost: NotificationSettings.toggleDevices(
              s.likesAndPlaysOnYourPost,
            ),
          ),
        ),
        onEmailToggle: () => _patch(
          s.copyWith(
            likesAndPlaysOnYourPost: NotificationSettings.toggleEmail(
              s.likesAndPlaysOnYourPost,
            ),
          ),
        ),
        showEmail: true,
        showDevice: false,
      ),
      _divider(),
      _NotifRow(
        label: 'Comment on your post',
        hasDevices: NotificationSettings.hasDevices(s.commentOnYourPost),
        hasEmail: NotificationSettings.hasEmail(s.commentOnYourPost),
        onDeviceToggle: () => _patch(
          s.copyWith(
            commentOnYourPost: NotificationSettings.toggleDevices(
              s.commentOnYourPost,
            ),
          ),
        ),
        onEmailToggle: () => _patch(
          s.copyWith(
            commentOnYourPost: NotificationSettings.toggleEmail(
              s.commentOnYourPost,
            ),
          ),
        ),
        showEmail: true,
        showDevice: false,
      ),
      _divider(),
      // Existing email-only items
      _NotifRow(
        label: 'Updates from Beatza',
        hasDevices: NotificationSettings.hasDevices(s.updatesFromSoundcloud),
        hasEmail: NotificationSettings.hasEmail(s.updatesFromSoundcloud),
        onDeviceToggle: () => _patch(
          s.copyWith(
            updatesFromSoundcloud: NotificationSettings.toggleDevices(
              s.updatesFromSoundcloud,
            ),
          ),
        ),
        onEmailToggle: () => _patch(
          s.copyWith(
            updatesFromSoundcloud: NotificationSettings.toggleEmail(
              s.updatesFromSoundcloud,
            ),
          ),
        ),
        showEmail: true,
        showDevice: false,
      ),
      _divider(),
      _NotifRow(
        label: 'Feature updates & education',
        hasDevices: NotificationSettings.hasDevices(
          s.soundcloudFeatureUpdatesEducation,
        ),
        hasEmail: NotificationSettings.hasEmail(
          s.soundcloudFeatureUpdatesEducation,
        ),
        onDeviceToggle: () => _patch(
          s.copyWith(
            soundcloudFeatureUpdatesEducation:
                NotificationSettings.toggleDevices(
                  s.soundcloudFeatureUpdatesEducation,
                ),
          ),
        ),
        onEmailToggle: () => _patch(
          s.copyWith(
            soundcloudFeatureUpdatesEducation: NotificationSettings.toggleEmail(
              s.soundcloudFeatureUpdatesEducation,
            ),
          ),
        ),
        showEmail: true,
        showDevice: false,
      ),
      _divider(),
      _NotifRow(
        label: 'Surveys & feedback',
        hasDevices: NotificationSettings.hasDevices(s.surveysAndFeedback),
        hasEmail: NotificationSettings.hasEmail(s.surveysAndFeedback),
        onDeviceToggle: () => _patch(
          s.copyWith(
            surveysAndFeedback: NotificationSettings.toggleDevices(
              s.surveysAndFeedback,
            ),
          ),
        ),
        onEmailToggle: () => _patch(
          s.copyWith(
            surveysAndFeedback: NotificationSettings.toggleEmail(
              s.surveysAndFeedback,
            ),
          ),
        ),
        showEmail: true,
        showDevice: false,
      ),
      _divider(),
      _NotifRow(
        label: 'Promotional & partnership content',
        hasDevices: NotificationSettings.hasDevices(
          s.promotionalPartnershipContent,
        ),
        hasEmail: NotificationSettings.hasEmail(
          s.promotionalPartnershipContent,
        ),
        onDeviceToggle: () => _patch(
          s.copyWith(
            promotionalPartnershipContent: NotificationSettings.toggleDevices(
              s.promotionalPartnershipContent,
            ),
          ),
        ),
        onEmailToggle: () => _patch(
          s.copyWith(
            promotionalPartnershipContent: NotificationSettings.toggleEmail(
              s.promotionalPartnershipContent,
            ),
          ),
        ),
        showEmail: true,
        showDevice: false,
      ),
      _divider(),
      _NotifRow(
        label: 'Newsletter',
        hasDevices: NotificationSettings.hasDevices(s.soundcloudNewsletter),
        hasEmail: NotificationSettings.hasEmail(s.soundcloudNewsletter),
        onDeviceToggle: () => _patch(
          s.copyWith(
            soundcloudNewsletter: NotificationSettings.toggleDevices(
              s.soundcloudNewsletter,
            ),
          ),
        ),
        onEmailToggle: () => _patch(
          s.copyWith(
            soundcloudNewsletter: NotificationSettings.toggleEmail(
              s.soundcloudNewsletter,
            ),
          ),
        ),
        showEmail: true,
        showDevice: false,
      ),
      _divider(),
      _EmailToggleRow(
        label: 'New message',
        value: s.newMessageEmail,
        onToggle: (val) => _patch(s.copyWith(newMessageEmail: val)),
      ),
    ];
  }

  Widget _divider() => Divider(
    height: 1,
    color: AppColors.containerMid,
    indent: 16,
    endIndent: 16,
  );
}

// ─── Row with device and/or email toggles ─────────────────────────────────────

class _NotifRow extends StatelessWidget {
  final String label;
  final bool hasDevices;
  final bool hasEmail;
  final VoidCallback onDeviceToggle;
  final VoidCallback onEmailToggle;
  final bool showDevice;
  final bool showEmail;

  const _NotifRow({
    required this.label,
    required this.hasDevices,
    required this.hasEmail,
    required this.onDeviceToggle,
    required this.onEmailToggle,
    this.showDevice = true,
    this.showEmail = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.whiteSmoke,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (showDevice) ...[
            const SizedBox(width: 12),
            _ToggleChip(
              icon: Icons.notifications_outlined,
              active: hasDevices,
              onTap: onDeviceToggle,
            ),
          ],
          if (showEmail) ...[
            const SizedBox(width: 8),
            _ToggleChip(
              icon: Icons.email_outlined,
              active: hasEmail,
              onTap: onEmailToggle,
            ),
          ],
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: active ? AppColors.brilliantOrange : AppColors.containerMid,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: active ? Colors.white : AppColors.white60,
        ),
      ),
    );
  }
}

// ─── New message row with device dropdown ─────────────────────────────────────

class _NewMessageRow extends StatelessWidget {
  final String deviceValue;
  final ValueChanged<String> onDeviceChanged;

  const _NewMessageRow({
    required this.deviceValue,
    required this.onDeviceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'New message',
              style: TextStyle(
                color: AppColors.whiteSmoke,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _DeviceDropdown(value: deviceValue, onChanged: onDeviceChanged),
        ],
      ),
    );
  }
}

class _DeviceDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _DeviceDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.containerMid,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: AppColors.surfaceMid,
          style: TextStyle(color: AppColors.whiteSmoke, fontSize: 13),
          iconEnabledColor: AppColors.white60,
          isDense: true,
          items: const [
            DropdownMenuItem(value: 'everyone', child: Text('Everyone')),
            DropdownMenuItem(value: 'followed', child: Text('Followed')),
            DropdownMenuItem(value: 'off', child: Text('Off')),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ─── Email-only boolean toggle row ────────────────────────────────────────────

class _EmailToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onToggle;

  const _EmailToggleRow({
    required this.label,
    required this.value,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.whiteSmoke,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onToggle,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.brilliantOrange,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.containerMid,
          ),
        ],
      ),
    );
  }
}