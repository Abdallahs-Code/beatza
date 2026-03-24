// Dart imports
import 'package:flutter/material.dart';

// Package imports
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/home/home_routes.dart';
import 'package:cross_team5/features/library/library_routes.dart';

enum AppNavItem { home, feed, search, library, upgrade }

class CommonBottomNavBar extends StatelessWidget {
  final AppNavItem currentItem;

  const CommonBottomNavBar({super.key, required this.currentItem});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      decoration: const BoxDecoration(
        color: AppColors.chineseBlack,
        border: Border(top: BorderSide(color: AppColors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_filled,
            label: 'Home',
            active: currentItem == AppNavItem.home,
            onTap: () {
              if (currentItem != AppNavItem.home) {
                Navigator.pushNamed(context, HomeRoutes.home);
              }
            },
          ),
          _NavItem(
            icon: Icons.feed_outlined,
            label: 'Feed',
            active: currentItem == AppNavItem.feed,
            onTap: () {},
          ),
          _NavItem(
            icon: Icons.search,
            label: 'Search',
            active: currentItem == AppNavItem.search,
            onTap: () {},
          ),
          _NavItem(
            key: const Key('test_home_to_library_nav'),
            icon: Icons.library_books_outlined,
            label: 'Library',
            active: currentItem == AppNavItem.library,
            onTap: () {
              if (currentItem != AppNavItem.library) {
                Navigator.pushNamed(context, LibraryRoutes.library);
              }
            },
          ),
          _NavItem(
            icon: Icons.graphic_eq,
            label: 'Upgrade',
            active: currentItem == AppNavItem.upgrade,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.whiteSmoke : AppColors.white54;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
