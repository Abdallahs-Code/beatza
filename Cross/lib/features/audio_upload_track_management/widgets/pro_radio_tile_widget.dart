import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';

class ProRadioTile extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;
  final bool isPro;

  const ProRadioTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.isPro = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isPro || selected
                    ? AppColors.whiteSmoke
                    : AppColors.white54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.whiteSmoke : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? AppColors.whiteSmoke
                      : (isPro ? AppColors.white54 : AppColors.white24),
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.black, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
