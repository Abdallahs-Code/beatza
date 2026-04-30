// Dart imports
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// Package imports
import 'package:url_launcher/url_launcher.dart';
import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/authentication_user_management/screens/create_password_screen.dart';
import 'package:cross_team5/features/authentication_user_management/screens/password_screen.dart';
import 'package:cross_team5/features/authentication_user_management/widgets/auth_back_button.dart';
import 'package:cross_team5/features/authentication_user_management/widgets/auth_title_text.dart';
import 'package:cross_team5/features/authentication_user_management/widgets/login_widgets.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';

class EmailEntryScreen extends StatefulWidget {
  const EmailEntryScreen({super.key});

  @override
  State<EmailEntryScreen> createState() => _EmailEntryScreenState();
}

class _EmailEntryScreenState extends State<EmailEntryScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _captchaController = TextEditingController();

  bool _robotChecked = false;
  bool _captchaVerified = false;
  String _captchaCode = '';
  String? _captchaError;

  @override
  void initState() {
    super.initState();
    _captchaController.addListener(_onCaptchaInput);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _captchaController.removeListener(_onCaptchaInput);
    _captchaController.dispose();
    super.dispose();
  }

  void _generateCaptcha({String? errorMessage}) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random();
    setState(() {
      _captchaCode = String.fromCharCodes(
        List.generate(6, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
      );
      _captchaController.clear();
      _captchaVerified = false;
      _captchaError = errorMessage;
    });
  }

  void _onCaptchaInput() {
    final input = _captchaController.text.trim().toUpperCase();

    if (input.length < _captchaCode.length) {
      if (_captchaVerified || _captchaError != null) {
        setState(() {
          _captchaVerified = false;
          _captchaError = null;
        });
      }
      return;
    }

    if (input == _captchaCode) {
      setState(() {
        _captchaVerified = true;
        _captchaError = null;
      });
    } else {
      _generateCaptcha(errorMessage: "Incorrect — try the new code");
    }
  }

  void _onRobotChecked(bool? value) {
    final checked = value ?? false;
    if (checked) {
      const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
      final rng = Random();
      final code = String.fromCharCodes(
        List.generate(6, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
      );
      setState(() {
        _robotChecked = true;
        _captchaCode = code;
        _captchaController.clear();
        _captchaVerified = false;
      });
    } else {
      setState(() {
        _robotChecked = false;
        _captchaCode = '';
        _captchaVerified = false;
        _captchaError = null;
        _captchaController.clear();
      });
    }
  }

  Future<void> _handleContinue() async {
    final String email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your email address or profile URL"),
        ),
      );
      return;
    }

    try {
      final authApiService = AuthApiService();
      final bool userExists = await authApiService.checkUserExists(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;

      if (userExists) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PasswordScreen(email: _emailController.text.trim()),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CreatePasswordScreen(email: _emailController.text.trim()),
          ),
        );
      }
    } catch (err) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to continue: $err"),
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
                child: AuthTitleText(text: "Sign in or create an account"),
              ),

              const SizedBox(height: 30),

              TextInputField(
                hintText: "Your email address or profile URL",
                controller: _emailController,
                autofocus: true,
              ),

              const SizedBox(height: 20),

              _RobotCheckbox(
                checked: _robotChecked,
                onChanged: _onRobotChecked,
              ),

              if (_robotChecked) ...[
                const SizedBox(height: 14),
                _CaptchaSection(
                  captchaCode: _captchaCode,
                  controller: _captchaController,
                  verified: _captchaVerified,
                  error: _captchaError,
                  onRegenerate: _generateCaptcha,
                ),
              ],

              const SizedBox(height: 24),

              LoginButton(
                text: "Continue",
                color: _captchaVerified
                    ? AppColors.silver
                    : AppColors.greyDark,
                onPressed: _captchaVerified
                    ? _handleContinue
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Please complete the CAPTCHA to continue",
                            ),
                          ),
                        );
                      },
              ),

              const SizedBox(height: 20),

              RichText(
                text: TextSpan(
                  text: "Need help?",
                  style: const TextStyle(
                    color: AppColors.blueHyperlink,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      await launchUrl(
                        Uri.parse('${ApiServices().baseUrl}/need-help'),
                      );
                    },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Robot checkbox ─────────────────────────────────────────────────────────────

class _RobotCheckbox extends StatelessWidget {
  final bool checked;
  final ValueChanged<bool?> onChanged;

  const _RobotCheckbox({required this.checked, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Checkbox(
            value: checked,
            onChanged: onChanged,
            activeColor: AppColors.successGreen,
            checkColor: Colors.white,
            side: BorderSide(color: AppColors.greyMedium),
          ),
          const SizedBox(width: 4),
          Text(
            "I'm not a robot",
            style: TextStyle(color: AppColors.whiteSmoke, fontSize: 15),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.security, color: AppColors.successGreen, size: 28),
                const SizedBox(height: 2),
                Text(
                  "reCAPTCHA",
                  style: TextStyle(color: AppColors.greyMuted, fontSize: 9),
                ),
                Text(
                  "Privacy · Terms",
                  style: TextStyle(color: AppColors.greyMuted, fontSize: 7.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── CAPTCHA section ────────────────────────────────────────────────────────────

class _CaptchaSection extends StatelessWidget {
  final String captchaCode;
  final TextEditingController controller;
  final bool verified;
  final String? error;
  final VoidCallback onRegenerate;

  const _CaptchaSection({
    required this.captchaCode,
    required this.controller,
    required this.verified,
    required this.onRegenerate,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Type the characters you see",
            style: TextStyle(color: AppColors.white70, fontSize: 13),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 64,
                    child: _AnimatedCaptchaCanvas(
                      captchaCode: captchaCode,
                      inputController: controller,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: onRegenerate,
                icon: const Icon(Icons.refresh),
                tooltip: "Regenerate CAPTCHA",
                color: AppColors.greyMedium,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.containerMid,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          TextField(
            controller: controller,
            style: TextStyle(
              color: AppColors.whiteSmoke,
              letterSpacing: 4,
              fontWeight: FontWeight.w600,
            ),
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: "Enter characters",
              hintStyle: TextStyle(
                color: AppColors.white54,
                letterSpacing: 0,
                fontWeight: FontWeight.normal,
              ),
              filled: true,
              fillColor: AppColors.inputFill,
              suffixIcon: verified
                  ? Icon(Icons.check_circle, color: AppColors.successGreen)
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: error != null ? AppColors.anger : AppColors.borderDark,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: error != null ? AppColors.anger : AppColors.borderDark,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white70),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),

          if (error != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.anger, size: 14),
                const SizedBox(width: 6),
                Text(
                  error!,
                  style: TextStyle(color: AppColors.anger, fontSize: 13),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Animated CAPTCHA canvas ────────────────────────────────────────────────────

class _AnimatedCaptchaCanvas extends StatefulWidget {
  final String captchaCode;
  final TextEditingController inputController;

  const _AnimatedCaptchaCanvas({
    required this.captchaCode,
    required this.inputController,
  });

  @override
  State<_AnimatedCaptchaCanvas> createState() => _AnimatedCaptchaCanvasState();
}

class _AnimatedCaptchaCanvasState extends State<_AnimatedCaptchaCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  List<double> _charX = [];
  List<double> _hueOffsets = [];
  int _lastInputLength = -1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _regenerateLayout();
    widget.inputController.addListener(_onInput);
  }

  @override
  void didUpdateWidget(_AnimatedCaptchaCanvas old) {
    super.didUpdateWidget(old);
    if (old.inputController != widget.inputController) {
      old.inputController.removeListener(_onInput);
      widget.inputController.addListener(_onInput);
    }
    if (old.captchaCode != widget.captchaCode) {
      _lastInputLength = -1;
      _regenerateLayout();
    }
  }

  @override
  void dispose() {
    widget.inputController.removeListener(_onInput);
    _ctrl.dispose();
    super.dispose();
  }

  void _onInput() {
    final len = widget.inputController.text.length;
    if (len != _lastInputLength) {
      _lastInputLength = len;
      _regenerateLayout();
    }
  }

  void _regenerateLayout() {
    final rng = Random();
    final n = widget.captchaCode.length;
    _hueOffsets = List.generate(n, (_) => rng.nextDouble() * 360);
    // Random gap between each pair of adjacent characters: 16–36 px.
    double x = 0;
    _charX = [];
    for (int i = 0; i < n; i++) {
      _charX.add(x);
      x += 16 + rng.nextDouble() * 20;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => CustomPaint(
        painter: _CaptchaPainter(
          widget.captchaCode,
          _ctrl.value,
          List.of(_charX),
          List.of(_hueOffsets),
        ),
      ),
    );
  }
}

// ── CAPTCHA painter ────────────────────────────────────────────────────────────

class _CaptchaPainter extends CustomPainter {
  final String code;
  final double animValue;
  final List<double> charX;
  final List<double> hueOffsets;
  late final Random _rng;

  _CaptchaPainter(this.code, this.animValue, this.charX, this.hueOffsets)
      : _rng = Random(code.hashCode);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF2A2A2A),
    );

    final linePaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1.2;
    for (int i = 0; i < 6; i++) {
      canvas.drawLine(
        Offset(_rng.nextDouble() * size.width, _rng.nextDouble() * size.height),
        Offset(_rng.nextDouble() * size.width, _rng.nextDouble() * size.height),
        linePaint,
      );
    }

    final dotPaint = Paint()..color = Colors.white24;
    for (int i = 0; i < 40; i++) {
      canvas.drawCircle(
        Offset(
          _rng.nextDouble() * size.width,
          _rng.nextDouble() * size.height,
        ),
        _rng.nextDouble() * 2,
        dotPaint,
      );
    }

    if (code.isEmpty || charX.length < code.length) return;

    // Centre the group using the span from first to last char position.
    final double groupWidth = charX.last - charX.first;
    final double startX = (size.width - groupWidth) / 2;

    for (int i = 0; i < code.length; i++) {
      // Each character cycles hue from its own random starting offset.
      final double hue = (hueOffsets[i] + animValue * 360) % 360;
      final color = HSVColor.fromAHSV(1.0, hue, 0.9, 1.0).toColor();

      final double wobbleX = sin(animValue * 2 * pi + i * 1.2) * 3.0;
      final double wobbleY = cos(animValue * 2 * pi * 0.8 + i * 0.9) * 5.0;
      final double baseRotation = (_rng.nextDouble() - 0.5) * 0.5;
      final double rotation =
          baseRotation + sin(animValue * 2 * pi + i * 0.7) * 0.2;

      final tp = TextPainter(
        text: TextSpan(
          text: code[i],
          style: TextStyle(
            fontSize: 22 + _rng.nextDouble() * 6,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(
        startX + (charX[i] - charX.first) + wobbleX,
        size.height / 2 + wobbleY,
      );
      canvas.rotate(rotation);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CaptchaPainter old) =>
      old.code != code || old.animValue != animValue;
}
