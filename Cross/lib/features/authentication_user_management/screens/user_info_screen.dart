// Dart imports
import 'package:flutter/material.dart';

// Package imports
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/authentication_user_management/screens/check_inbox_screen.dart';
import 'package:cross_team5/features/authentication_user_management/widgets/auth_back_button.dart';
import 'package:cross_team5/features/authentication_user_management/widgets/auth_title_text.dart';
import 'package:cross_team5/features/authentication_user_management/widgets/login_widgets.dart';
import 'package:cross_team5/features/authentication_user_management/models/user.dart'
    as user_model;
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';

class UserInfoScreen extends StatefulWidget {
  final String email;
  final String password;

  const UserInfoScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final TextEditingController _displayNameController = TextEditingController();

  String? _selectedMonth;
  String? _selectedDay;
  String? _selectedYear;
  String? _selectedGender;
  bool _isLoading = false;

  final List<String> _months = const [
    "Month",
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ];

  final List<String> _days = List<String>.generate(
    31,
    (index) => "${index + 1}",
  );

  final List<String> _years = List<String>.generate(
    100,
    (index) => "${DateTime.now().year - index}",
  );

  final List<String> _genders = const [
    "Male",
    "Female",
    "Non-binary",
    "Prefer not to say",
  ];

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (_displayNameController.text.trim().isEmpty ||
        _selectedMonth == null ||
        _selectedDay == null ||
        _selectedYear == null ||
        _selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please complete all required fields"),
        ),
      );
      return;
    }

    final int monthIndex = _months.indexOf(_selectedMonth!);
    final String formattedMonth = monthIndex.toString().padLeft(2, '0');
    final String formattedDay = _selectedDay!.padLeft(2, '0');
    final String formattedDate =
        "${_selectedYear!}-$formattedMonth-$formattedDay";

    setState(() {
      _isLoading = true;
    });

    final authApiService = AuthApiService();

    final result = await authApiService.signup(
      user: user_model.User(
        widget.email,
        widget.password,
        _displayNameController.text.trim(),
        formattedDate,
        _selectedGender!,
      ),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.$1 >= 200 && result.$1 < 300) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CheckInboxScreen(email: widget.email),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.$2.toString()),
          backgroundColor: AppColors.anger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.chineseBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AuthBackButton(),
              const SizedBox(height: 20),

              const Center(
                child: AuthTitleText(
                  text: "Tell us more about you",
                ),
              ),

              const SizedBox(height: 28),

              TextField(
                controller: _displayNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Display name",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: AppColors.googleBackGround,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Your display name can be anything you like. Your name or artist name are good choices.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                "Date of birth (required)",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: _buildDropdown(
                      hint: "Month",
                      value: _selectedMonth,
                      items: _months
                          .where((month) => month != "Month")
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMonth = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: _buildDropdown(
                      hint: "Day",
                      value: _selectedDay,
                      items: _days,
                      onChanged: (value) {
                        setState(() {
                          _selectedDay = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: _buildDropdown(
                      hint: "Year",
                      value: _selectedYear,
                      items: _years,
                      onChanged: (value) {
                        setState(() {
                          _selectedYear = value;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              const Text(
                "Your date of birth is used to verify your age and is not shared publicly.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 28),

              _buildDropdown(
                hint: "Gender (required)",
                value: _selectedGender,
                items: _genders,
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
              ),

              const SizedBox(height: 24),

              LoginButton(
                text: _isLoading ? "Loading..." : "Continue",
                color: AppColors.silver,
                onPressed: _isLoading ? () {} : _handleContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.googleBackGround,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(color: Colors.white54),
          ),
          isExpanded: true,
          dropdownColor: AppColors.googleBackGround,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          onChanged: onChanged,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}