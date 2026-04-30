import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/library/models/account_settings_model.dart';
import 'package:cross_team5/features/library/services/account_settings_api_service.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _api = AccountSettingsApiService();
  final _auth = AuthApiService();

  AccountSettings? _settings;
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

  Future<void> _patch(AccountSettings updated) async {
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
                        style: const TextStyle(
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
                          _buildSectionLabel('Profile'),
                          const SizedBox(height: 4),
                          _buildCard(
                            children: [
                              _buildDobTile(),
                              _divider(),
                              _buildGenderTile(),
                            ],
                          ),
                          const SizedBox(height: 28),
                          _buildSectionLabel('Appearance'),
                          const SizedBox(height: 4),
                          _buildCard(children: [_buildThemeTile()]),
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
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.whiteSmoke,
                  size: 20,
                ),
              ),
            ),
            const Center(
              child: Text(
                'Account',
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

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: AppColors.white60,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.tileDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() => const Divider(
    height: 1,
    color: AppColors.containerMid,
    indent: 16,
    endIndent: 16,
  );

  Widget _buildDobTile() {
    final dob = _settings?.dateOfBirth ?? '';
    final display = _formatDob(dob);

    return InkWell(
      onTap: () => _showDobPicker(dob),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            const Icon(Icons.cake_outlined, color: AppColors.white60, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date of Birth',
                    style: TextStyle(color: AppColors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    display.isEmpty ? 'Not set' : display,
                    style: TextStyle(
                      color: display.isEmpty
                          ? AppColors.white60
                          : AppColors.whiteSmoke,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.white60, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderTile() {
    final gender = _settings?.gender ?? '';
    return InkWell(
      onTap: () => _showGenderPicker(gender),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            const Icon(
              Icons.person_outline,
              color: AppColors.white60,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gender',
                    style: TextStyle(color: AppColors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    gender.isEmpty ? 'Not set' : gender,
                    style: TextStyle(
                      color: gender.isEmpty
                          ? AppColors.white60
                          : AppColors.whiteSmoke,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.white60, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeTile() {
    final theme = _settings?.theme ?? 'Dark';
    return InkWell(
      onTap: () => _showThemePicker(theme),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(
              theme == 'Light'
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              color: AppColors.white60,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Theme',
                    style: TextStyle(color: AppColors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    theme,
                    style: const TextStyle(
                      color: AppColors.whiteSmoke,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.white60, size: 22),
          ],
        ),
      ),
    );
  }

  String _formatDob(String iso) {
    if (iso.isEmpty) return '';
    try {
      final datePart = iso.split('T').first;
      final parts = datePart.split('-');
      if (parts.length < 3) return datePart;
      final dt = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
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
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  void _showDobPicker(String currentDob) {
    int? selectedMonth;
    int? selectedDay;
    int? selectedYear;

    if (currentDob.isNotEmpty) {
      try {
        final parts = currentDob.split('T').first.split('-');
        selectedYear = int.parse(parts[0]);
        selectedMonth = int.parse(parts[1]);
        selectedDay = int.parse(parts[2]);
      } catch (_) {}
    }

    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final currentYear = DateTime.now().year;
    final years = List<int>.generate(
      currentYear - 1949,
      (i) => currentYear - i,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceMid,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final daysInMonth = (selectedMonth != null && selectedYear != null)
                ? DateUtils.getDaysInMonth(selectedYear!, selectedMonth!)
                : 31;
            final days = List<int>.generate(daysInMonth, (i) => i + 1);
            if (selectedDay != null && selectedDay! > daysInMonth) {
              selectedDay = null;
            }

            final InputDecoration dropdownDecoration = InputDecoration(
              filled: true,
              fillColor: AppColors.containerMid,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.brilliantOrange,
                  width: 1.2,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            );

            Widget buildDropdown<T>({
              required T? value,
              required String hint,
              required List<DropdownMenuItem<T>> items,
              required void Function(T?) onChanged,
            }) {
              return DropdownButtonFormField<T>(
                initialValue: value,
                isExpanded: true,
                dropdownColor: AppColors.surfaceMid,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.white60,
                ),
                decoration: dropdownDecoration,
                hint: Text(
                  hint,
                  style: const TextStyle(
                    color: AppColors.white60,
                    fontSize: 15,
                  ),
                ),
                items: items,
                selectedItemBuilder: (_) => items
                    .map(
                      (item) => Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item.value == null ? '' : item.value.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date of Birth',
                    style: TextStyle(
                      color: AppColors.whiteSmoke,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: buildDropdown<int>(
                          value: selectedMonth,
                          hint: 'Month',
                          items: List.generate(
                            12,
                            (i) => DropdownMenuItem(
                              value: i + 1,
                              child: Text(
                                monthNames[i],
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          onChanged: (v) =>
                              setSheetState(() => selectedMonth = v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: buildDropdown<int>(
                          value: selectedDay,
                          hint: 'Day',
                          items: days
                              .map(
                                (d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(
                                    '$d',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setSheetState(() => selectedDay = v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: buildDropdown<int>(
                          value: selectedYear,
                          hint: 'Year',
                          items: years
                              .map(
                                (y) => DropdownMenuItem(
                                  value: y,
                                  child: Text(
                                    '$y',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setSheetState(() => selectedYear = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          (selectedMonth != null &&
                              selectedDay != null &&
                              selectedYear != null)
                          ? () {
                              Navigator.pop(sheetContext);
                              if (_settings != null) {
                                final iso = DateTime(
                                  selectedYear!,
                                  selectedMonth!,
                                  selectedDay!,
                                ).toIso8601String().split('T').first;
                                _patch(_settings!.copyWith(dateOfBirth: iso));
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brilliantOrange,
                        disabledBackgroundColor: const Color(0xFF3A2A1A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showThemePicker(String currentTheme) {
    const options = ['Dark', 'Light'];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Text(
                    'Theme',
                    style: TextStyle(
                      color: AppColors.whiteSmoke,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ...options.map((opt) {
                  final selected = opt == currentTheme;
                  return ListTile(
                    leading: Icon(
                      opt == 'Light'
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      color: selected
                          ? AppColors.brilliantOrange
                          : AppColors.white60,
                      size: 20,
                    ),
                    title: Text(
                      opt,
                      style: TextStyle(
                        color: selected
                            ? AppColors.brilliantOrange
                            : AppColors.whiteSmoke,
                        fontSize: 15,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(
                            Icons.check,
                            color: AppColors.brilliantOrange,
                            size: 20,
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      if (!selected && _settings != null) {
                        _patch(_settings!.copyWith(theme: opt));
                      }
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGenderPicker(String currentGender) {
    const options = ['Male', 'Female'];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Text(
                    'Select Gender',
                    style: TextStyle(
                      color: AppColors.whiteSmoke,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ...options.map((opt) {
                  final selected = opt == currentGender;
                  return ListTile(
                    title: Text(
                      opt,
                      style: TextStyle(
                        color: selected
                            ? AppColors.brilliantOrange
                            : AppColors.whiteSmoke,
                        fontSize: 15,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(
                            Icons.check,
                            color: AppColors.brilliantOrange,
                            size: 20,
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      if (!selected && _settings != null) {
                        _patch(_settings!.copyWith(gender: opt));
                      }
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
