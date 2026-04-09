import 'package:flutter/material.dart';

class WaveformWidget extends StatelessWidget {
  final List<double> peaks;

  const WaveformWidget({super.key, required this.peaks});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: peaks.map((peak) {
          return Container(
            width: 4,
            height: (peak / 100) * 50 < 4 ? 4 : (peak / 100) * 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFF7700), Color(0xFFFF4400)],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }).toList(),
      ),
    );
  }
}