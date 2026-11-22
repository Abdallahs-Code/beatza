import 'package:flutter/material.dart';



const double kMiniPlayerTotalHeight = 156.0;


const double kNavBarHeight = 84.0;



final ValueNotifier<double> miniPlayerHeightNotifier = ValueNotifier<double>(
  0.0,
);





class MiniPlayerSpacer extends StatelessWidget {
  const MiniPlayerSpacer({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: miniPlayerHeightNotifier,
      builder: (_, h, _) => SizedBox(height: h),
    );
  }
}
