import 'package:flutter/material.dart';

import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/home/home_routes.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String pendingToken;

  // Optional because your current flow only passes pendingToken.
  // If you later have the email from backend/callback, pass it here.
  final String? email;

  const VerifyCodeScreen({super.key, required this.pendingToken, this.email});

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isSendingAgain = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _codeFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the verification code")),
      );
      return;
    }

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("The verification code must be 6 digits")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authApiService = AuthApiService();

    final result = await authApiService.verifyGoogleCode(
      pendingToken: widget.pendingToken,
      code: code,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.$1 >= 200 && result.$1 < 300) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        HomeRoutes.home,
        (route) => false,
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

  Future<void> _handleSendAgain() async {
    setState(() {
      _isSendingAgain = true;
    });

    final authApiService = AuthApiService();

    final result = await authApiService.resendGoogleVerificationCode(
      pendingToken: widget.pendingToken,
    );

    if (!mounted) return;

    setState(() {
      _isSendingAgain = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.$2.toString()),
        backgroundColor: (result.$1 >= 200 && result.$1 < 300)
            ? Colors.green
            : AppColors.anger,
      ),
    );
  }

  void _onCodeChanged(String value) {
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    final limited = digitsOnly.length > 6
        ? digitsOnly.substring(0, 6)
        : digitsOnly;

    if (limited != _codeController.text) {
      _codeController.value = TextEditingValue(
        text: limited,
        selection: TextSelection.collapsed(offset: limited.length),
      );
    } else {
      setState(() {});
    }
  }

  Widget _buildCodeBox(int index) {
    final code = _codeController.text;
    final char = index < code.length ? code[index] : '';

    return GestureDetector(
      onTap: () {
        _codeFocusNode.requestFocus();
      },
      child: Container(
        width: 54,
        height: 76,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.greyInputDark,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          char,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 30,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // final displayedEmail =
    //     (widget.email != null && widget.email!.trim().isNotEmpty)
    //         ? widget.email!.trim()
    //         : "your email";

    return Scaffold(
      backgroundColor: AppColors.chineseBlack,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => _codeFocusNode.requestFocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    const SizedBox(height: 18),

                    Text(
                      "An account exists\nwith this email address!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.whiteSmoke,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),

                    const SizedBox(height: 26),

                    Text(
                      "We can connect your Google credentials to this account\nso you can use it to log in next time.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.whiteSmoke,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      "To continue, enter the code we have sent to this email as\nverification.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.whiteSmoke,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(height: 52),

                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: 0.0,
                          child: TextField(
                            controller: _codeController,
                            focusNode: _codeFocusNode,
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            maxLength: 6,
                            onChanged: _onCodeChanged,
                            onSubmitted: (_) {
                              if (_codeController.text.trim().length == 6 &&
                                  !_isLoading) {
                                _handleVerify();
                              }
                            },
                            style: const TextStyle(color: Colors.transparent),
                            cursorColor: Colors.transparent,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              counterText: "",
                            ),
                          ),
                        ),

                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: List.generate(6, _buildCodeBox),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleVerify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.greyButton,
                          disabledBackgroundColor: AppColors.greyButton,
                          foregroundColor: Colors.black,
                          disabledForegroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.black,
                                ),
                              )
                            : Text(
                                "Continue",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: _isSendingAgain ? null : _handleSendAgain,
                      child: Text(
                        _isSendingAgain ? "Sending..." : "Send again",
                        style: const TextStyle(
                          color: AppColors.blueAccent,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    Text(
                      "Otherwise, you can go back and choose another\nauthentication method.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.whiteSmoke,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
