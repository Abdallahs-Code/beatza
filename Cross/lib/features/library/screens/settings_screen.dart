import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/library/screens/account_settings_screen.dart';
import 'package:cross_team5/features/library/screens/notification_settings_screen.dart';
import 'package:cross_team5/features/library/screens/content_settings_screen.dart';
import 'package:cross_team5/features/library/screens/privacy_settings_screen.dart';
import 'package:cross_team5/features/authentication_user_management/authentication_user_management_routes.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import '../../premium_subscription/screens/premium_subscription.dart';
import '../../premium_subscription/services/payment_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showManageSubscriptionSheet(BuildContext context) {
    final currentPriceId =
        PaymentService.subscriptionSuccessNotifier.currentPriceId;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Subscription',
                style: TextStyle(
                  color: AppColors.whiteSmoke,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),

              FutureBuilder<Map<String, dynamic>>(
                future: PaymentService.getPlans(),
                builder: (context, plansSnapshot) {
                  return FutureBuilder<Map<String, dynamic>?>(
                    future: PaymentService.getCurrentSubscriptionDetails(),
                    builder: (context, subSnapshot) {
                      if (plansSnapshot.connectionState ==
                              ConnectionState.waiting ||
                          subSnapshot.connectionState ==
                              ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.brilliantOrange,
                            ),
                          ),
                        );
                      }

                      if (!subSnapshot.hasData || subSnapshot.data == null) {
                        return Text(
                          'Active Plan (Details unavailable)',
                          style: TextStyle(
                            color: AppColors.white60,
                            fontSize: 14,
                          ),
                        );
                      }

                      final subData = subSnapshot.data!;
                      final apiPlans = plansSnapshot.data ?? {};
                      final String? periodEndStr = subData['currentPeriodEnd'];
                      final DateTime? expiryDate = periodEndStr != null
                          ? DateTime.parse(periodEndStr).toLocal()
                          : null;
                      final int daysLeft = expiryDate != null
                          ? expiryDate.difference(DateTime.now()).inDays
                          : 0;
                      Map<String, dynamic>? currentPlanData;
                      apiPlans.forEach((key, value) {
                        if (value['priceId'] == currentPriceId ||
                            key == currentPriceId) {
                          currentPlanData = value;
                        }
                      });

                      final planName = currentPlanData?['name'] ?? 'Pro Plan';
                      final isPro = planName.toLowerCase().contains('pro');

                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMid,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isPro
                                    ? AppColors.proBadgePurple
                                    : AppColors.tileDark3,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              planName,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (isPro)
                                              const Padding(
                                                padding: EdgeInsets.only(
                                                  left: 6,
                                                ),
                                                child: Icon(
                                                  Icons.stars,
                                                  color: AppColors
                                                      .primaryOrangeAccent,
                                                  size: 16,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          daysLeft > 0
                                              ? 'Expires in $daysLeft days'
                                              : 'Expires today',
                                          style: TextStyle(
                                            color: daysLeft < 5
                                                ? Colors.redAccent
                                                : AppColors.successGreen,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(color: Colors.white10),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Renewal Date',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      expiryDate != null
                                          ? '${expiryDate.day}/${expiryDate.month}/${expiryDate.year}'
                                          : '--/--/--',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.sync_alt_rounded,
                  color: AppColors.whiteSmoke,
                ),
                title: Text(
                  'Change or Upgrade Plan',
                  style: TextStyle(color: AppColors.whiteSmoke, fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PremiumSubscriptionScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.cancel_outlined,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Cancel Subscription',
                  style: TextStyle(color: Colors.redAccent, fontSize: 16),
                ),
                onTap: () async {
                  Navigator.pop(context);

                  final nav = Navigator.of(context, rootNavigator: true);
                  final messenger = ScaffoldMessenger.of(context);

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (dialogContext) => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.brilliantOrange,
                      ),
                    ),
                  );

                  try {
                    await PaymentService.cancelSubscription();
                    await PaymentService.refreshToken();

                    PaymentService.subscriptionSuccessNotifier.reset();

                    nav.pop();

                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Subscription cancelled successfully'),
                      ),
                    );
                  } catch (e) {
                    nav.pop();

                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceAll('Exception: ', ''),
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      body: SafeArea(
        child: Column(
          children: [
            const _SettingsHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  children: [
                    ValueListenableBuilder<SubscriptionState>(
                      valueListenable:
                          PaymentService.subscriptionSuccessNotifier,
                      builder: (context, state, child) {
                        if (state.isPro) {
                          return _SettingsTile(
                            title: 'Manage Subscription (Pro)',
                            onTap: () => _showManageSubscriptionSheet(context),
                          );
                        } else {
                          return _SettingsTile(
                            title: 'Upgrade to Artist Pro',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const PremiumSubscriptionScreen(),
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),
                    const _SettingsTile(
                      title: 'Autoplay related tracks',
                      hasTrailingSwitch: true,
                      initialSwitchValue: true,
                    ),
                    const _SettingsTile(
                      title: 'Use Classic feed',
                      hasTrailingSwitch: true,
                      initialSwitchValue: false,
                    ),
                    const _SettingsTile(title: 'Import my music'),
                    _SettingsTile(
                      title: 'Account',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AccountSettingsScreen(),
                        ),
                      ),
                    ),
                    const _SettingsTile(title: 'Inbox'),
                    const _SettingsTile(title: 'Social'),
                    _SettingsTile(
                      title: 'Notifications',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationSettingsScreen(),
                        ),
                      ),
                    ),
                    _SettingsTile(
                      title: 'Privacy',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()),
                      ),
                    ),
                    _SettingsTile(
                      title: 'Content',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ContentSettingsScreen()),
                      ),
                    ),
                    _SettingsTile(
                      title: 'Privacy',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()),
                      ),
                    ),
                    _SettingsTile(
                      title: 'Content',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ContentSettingsScreen()),
                      ),
                    ),
                    _SettingsTile(
                      title: 'Privacy',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()),
                      ),
                    ),
                    _SettingsTile(
                      title: 'Content',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ContentSettingsScreen()),
                      ),
                    ),
                    _SettingsTile(
                      title: 'Privacy',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()),
                      ),
                    ),
                    _SettingsTile(
                      title: 'Content',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ContentSettingsScreen()),
                      ),
                    ),
                    const _SettingsTile(title: 'App Icon'),
                    const _SettingsTile(title: 'App Language'),
                    const _SettingsTile(title: 'Storage'),
                    const _SettingsTile(title: 'Analytics'),
                    const _SettingsTile(title: 'Communications'),
                    const _SettingsTile(title: 'Advertising'),
                    const _SettingsTile(
                      title: 'Tell a friend',
                      showChevron: false,
                    ),
                    const _SettingsTile(title: 'Troubleshooting'),
                    const _SettingsTile(
                      title: 'Contact support',
                      showChevron: false,
                    ),
                    const _SettingsTile(title: 'Legal'),
                    const SizedBox(height: 28),
                    _PrimaryActionButton(
                      title: 'Sign out',
                      backgroundColor: AppColors.tileDark,
                      textColor: AppColors.whiteSmoke,
                      onTap: () async {
                        final authService = AuthApiService();
                        await authService.logout();
                        if (!context.mounted) return;
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AuthenticationRoutes.welcome,
                          (route) => false,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _PrimaryActionButton(
                      title: 'Delete account',
                      backgroundColor: AppColors.deepRed,
                      textColor: Colors.white,
                      onTap: () {
                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (_) => const DeleteAccountDialog(),
                        );
                      },
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
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
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
                'Settings',
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
}

class _SettingsTile extends StatefulWidget {
  final String title;
  final bool showChevron;
  final bool hasTrailingSwitch;
  final bool initialSwitchValue;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.title,
    this.showChevron = true,
    this.hasTrailingSwitch = false,
    this.initialSwitchValue = false,
    this.onTap,
  });

  @override
  State<_SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<_SettingsTile> {
  late bool _switchValue;

  @override
  void initState() {
    super.initState();
    _switchValue = widget.initialSwitchValue;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.hasTrailingSwitch ? null : (widget.onTap ?? () {}),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: TextStyle(
                  color: AppColors.whiteSmoke,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (widget.hasTrailingSwitch)
              Switch(
                value: _switchValue,
                onChanged: (value) {
                  setState(() {
                    _switchValue = value;
                  });
                },
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.brilliantOrange,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: AppColors.tileDark3,
              )
            else if (widget.showChevron)
              Icon(Icons.chevron_right, color: AppColors.white60, size: 26),
          ],
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String title;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  const _PrimaryActionButton({
    required this.title,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final AuthApiService _authService = AuthApiService();
  bool _confirmed = false;
  bool _isDeleting = false;

  Future<void> _handleDeleteAccount() async {
    if (!_confirmed || _isDeleting) return;

    setState(() {
      _isDeleting = true;
    });

    final (statusCode, message) = await _authService.deleteAccount();

    if (!mounted) return;

    if (statusCode == 200) {
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message?.toString() ?? 'Account deleted successfully'),
        ),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        AuthenticationRoutes.welcome,
        (route) => false,
      );
    } else {
      setState(() {
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message?.toString() ?? 'Failed to delete account'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.backgroundDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.redAccent, size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Delete Account',
                    style: TextStyle(
                      color: AppColors.whiteSmoke,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Are you sure you want to permanently delete your account? This action cannot be undone and will immediately remove:',
              style: TextStyle(
                color: AppColors.white60,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            const _BulletPoint(
              text: 'Your profile and all account information',
            ),
            const _BulletPoint(text: 'All uploaded tracks and audio content'),
            const _BulletPoint(text: 'All comments, likes, and reposts'),
            const _BulletPoint(text: 'Your followers and following lists'),
            const _BulletPoint(text: 'All stats and listening history'),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _confirmed,
                  onChanged: _isDeleting
                      ? null
                      : (value) {
                          setState(() {
                            _confirmed = value ?? false;
                          });
                        },
                  activeColor: Colors.redAccent,
                  checkColor: Colors.white,
                  side: BorderSide(color: AppColors.white60),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Yes, I understand this is permanent and want to delete my account and all my tracks, comments and stats.',
                      style: TextStyle(
                        color: AppColors.white60,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isDeleting
                        ? null
                        : () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tileDark,
                      foregroundColor: AppColors.whiteSmoke,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: (_confirmed && !_isDeleting)
                        ? _handleDeleteAccount
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepRed,
                      disabledBackgroundColor: const Color(0xFF5C1F1F),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isDeleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Delete my account',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;

  const _BulletPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•  ',
            style: TextStyle(
              color: AppColors.white60,
              fontSize: 18,
              height: 1.4,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.white60,
                fontSize: 15,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
