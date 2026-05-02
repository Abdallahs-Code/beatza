import 'package:flutter/material.dart';

// Package imports
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/authentication_user_management/models/user.dart'
    as user_model;
import 'package:cross_team5/features/authentication_user_management/screens/check_inbox_screen.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/home/home_routes.dart';
import 'package:cross_team5/features/library/models/account_settings_model.dart';
import 'package:cross_team5/features/library/services/account_settings_api_service.dart';

class UserInfoScreen extends StatefulWidget {
  final String? email;
  final String? password;
  final String? incompleteToken;
  final String initialDisplayName;
  final bool isGoogleFlow;

  const UserInfoScreen({
    super.key,
    this.email,
    this.password,
    this.incompleteToken,
    this.initialDisplayName = "",
    required this.isGoogleFlow,
  });

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  late final TextEditingController _displayNameController;

  int? _selectedMonth;
  int? _selectedDay;
  int? _selectedYear;
  String? _selectedGender;
  bool _isLoading = false;

  final List<String> _genders = ["Male", "Female"];

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.initialDisplayName,
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  List<int> get _years {
    final currentYear = DateTime.now().year;
    return List<int>.generate(
      currentYear - 1949,
      (index) => currentYear - index,
    );
  }

  List<int> get _days {
    if (_selectedMonth == null || _selectedYear == null) {
      return List<int>.generate(31, (index) => index + 1);
    }

    final daysInMonth = DateUtils.getDaysInMonth(
      _selectedYear!,
      _selectedMonth!,
    );
    return List<int>.generate(daysInMonth, (index) => index + 1);
  }

  String _monthName(int month) {
    const monthNames = [
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
    return monthNames[month];
  }

  String? _buildDateOfBirth() {
    if (_selectedYear == null ||
        _selectedMonth == null ||
        _selectedDay == null) {
      return null;
    }

    try {
      final date = DateTime(_selectedYear!, _selectedMonth!, _selectedDay!);
      return date.toIso8601String().split('T').first;
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleSubmit() async {
    final displayName = _displayNameController.text.trim();
    final dateOfBirth = _buildDateOfBirth();

    if (displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your display name"),
          backgroundColor: AppColors.anger,
        ),
      );
      return;
    }

    if (dateOfBirth == null || _selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required fields"),
          backgroundColor: AppColors.anger,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final gender = _selectedGender!;

      if (widget.isGoogleFlow) {
        final incompleteToken = widget.incompleteToken?.trim() ?? "";

        if (incompleteToken.isEmpty) {
          throw Exception("Missing incomplete token");
        }

        final result = await AuthApiService().completeGoogleSignup(
          incompleteToken: incompleteToken,
          displayName: displayName,
          dateOfBirth: dateOfBirth,
          gender: gender,
        );

        if (!mounted) return;

        if (result.$1 == 200) {
          try {
            final token = await AuthApiService().getStoredAccessToken();
            if (token != null) {
              await AccountSettingsApiService().updateSettings(
                token,
                AccountSettings(
                  theme: 'Dark',
                  dateOfBirth: dateOfBirth,
                  gender: gender,
                ),
              );
            }
          } catch (_) {}

          if (!mounted) return;
          Navigator.pushNamedAndRemoveUntil(
            context,
            HomeRoutes.home,
            (route) => false,
          );
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.$2.toString()),
            backgroundColor: AppColors.anger,
          ),
        );
      } else {
        final email = widget.email?.trim() ?? "";
        final password = widget.password?.trim() ?? "";

        if (email.isEmpty) {
          throw Exception("Missing email");
        }

        if (password.isEmpty) {
          throw Exception("Missing password");
        }

        final result = await AuthApiService().signup(
          user: user_model.User(
            email,
            password,
            displayName,
            dateOfBirth,
            gender,
          ),
        );

        if (!mounted) return;

        if (result.$1 == 200 || result.$1 == 201) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => CheckInboxScreen(email: email)),
          );
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.$2.toString()),
            backgroundColor: AppColors.anger,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.anger),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(
          color: AppColors.whiteSmoke.withValues(alpha: 0.14),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: AppColors.white70, width: 1.2),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.whiteSmoke,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildDropdownBox<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String Function(T value)? selectedLabelBuilder,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: AppColors.chineseBlack,
      style: TextStyle(
        color: AppColors.whiteSmoke,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      icon: Icon(Icons.keyboard_arrow_down, color: AppColors.greyButton),
      decoration: _inputDecoration(),
      hint: Text(
        hint,
        style: TextStyle(
          color: AppColors.greyButton,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      items: items,
      selectedItemBuilder: (context) {
        return items.map((item) {
          final itemValue = item.value;
          final text = itemValue == null
              ? ""
              : (selectedLabelBuilder != null
                    ? selectedLabelBuilder(itemValue)
                    : itemValue.toString());

          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.whiteSmoke,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList();
      },
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('test_user_info_screen'),
      backgroundColor: AppColors.chineseBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: AppColors.whiteSmoke.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.whiteSmoke,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Text(
                      "Tell us more about you",
                      style: TextStyle(
                        color: AppColors.whiteSmoke,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 34),
              TextField(
                key: const Key('test_user_info_display_name_input'),
                controller: _displayNameController,
                style: TextStyle(
                  color: AppColors.whiteSmoke,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: "Display name",
                  hintStyle: TextStyle(
                    color: AppColors.greyButton,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: AppColors.whiteSmoke.withValues(alpha: 0.14),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: AppColors.white70,
                      width: 1.2,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Your display name can be anything you like. Your name or artist name are good choices.",
                style: TextStyle(
                  color: AppColors.greyButton,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 26),
              _buildFieldLabel("Date of birth (required)"),
              const SizedBox(height: 14),
              Row(
                key: const Key('test_user_info_dob_row'),
                children: [
                  Expanded(
                    child: _buildDropdownBox<int>(
                      value: _selectedMonth,
                      hint: "Month",
                      selectedLabelBuilder: (month) => _monthName(month),
                      items: List.generate(12, (index) {
                        final month = index + 1;
                        return DropdownMenuItem<int>(
                          value: month,
                          child: Text(
                            _monthName(month),
                            style: TextStyle(color: AppColors.whiteSmoke),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                      onChanged: (value) {
                        setState(() {
                          _selectedMonth = value;
                          if (_selectedDay != null &&
                              _selectedYear != null &&
                              value != null) {
                            final maxDays = DateUtils.getDaysInMonth(
                              _selectedYear!,
                              value,
                            );
                            if (_selectedDay! > maxDays) {
                              _selectedDay = null;
                            }
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDropdownBox<int>(
                      value: _selectedDay,
                      hint: "Day",
                      items: _days.map((day) {
                        return DropdownMenuItem<int>(
                          value: day,
                          child: Text(
                            day.toString(),
                            style: TextStyle(color: AppColors.whiteSmoke),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDay = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDropdownBox<int>(
                      value: _selectedYear,
                      hint: "Year",
                      items: _years.map((year) {
                        return DropdownMenuItem<int>(
                          value: year,
                          child: Text(
                            year.toString(),
                            style: TextStyle(color: AppColors.whiteSmoke),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedYear = value;
                          if (_selectedDay != null &&
                              _selectedMonth != null &&
                              value != null) {
                            final maxDays = DateUtils.getDaysInMonth(
                              value,
                              _selectedMonth!,
                            );
                            if (_selectedDay! > maxDays) {
                              _selectedDay = null;
                            }
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "Your date of birth is used to verify your age and is not shared publicly.",
                style: TextStyle(
                  color: AppColors.greyButton,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              _buildDropdownBox<String>(
                value: _selectedGender,
                hint: "Gender (required)",
                items: _genders.map((gender) {
                  return DropdownMenuItem<String>(
                    value: gender,
                    child: Text(
                      gender,
                      style: TextStyle(color: AppColors.whiteSmoke),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('test_user_info_submit_btn'),
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.greyButton,
                    disabledBackgroundColor: AppColors.greyButton,
                    foregroundColor: AppColors.pureBlack,
                    disabledForegroundColor: AppColors.pureBlack,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: AppColors.pureBlack,
                          ),
                        )
                      : const Text(
                          "Continue",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
