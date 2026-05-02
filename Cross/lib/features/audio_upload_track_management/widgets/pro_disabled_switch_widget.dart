import 'package:flutter/cupertino.dart';
import 'package:cross_team5/core/theme/app_colors.dart';

class ProDisabledSwitch extends StatelessWidget {
  final VoidCallback onTap;

  const ProDisabledSwitch({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 30,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.containerMid,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.waveformInactive,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
