import 'package:flutter/material.dart';

class ProRadioTile extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const ProRadioTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? Colors.white24
                      : Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
                color: selected
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.transparent,
              ),
              child: selected
                  ? const Center(
                      child: Icon(Icons.check, size: 16, color: Colors.white24),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
