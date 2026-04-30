// Widget: SearchHistoryTile
// Single row in the "Recently searched" list.
// Shows thumbnail, title + metadata, and an X to delete the item.

import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';

class SearchHistoryTile extends StatelessWidget {
  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String type;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const SearchHistoryTile({
    super.key,
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    required this.type,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _buildThumbnail(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(
                      subtitle!,
                      style: TextStyle(color: AppColors.white54, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: AppColors.white54, size: 18),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    const double size = 50;
    final bool isUser = type == 'user';

    Widget placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: isUser
            ? BorderRadius.circular(25)
            : BorderRadius.circular(6),
      ),
      child: Icon(
        isUser ? Icons.person : Icons.music_note,
        color: AppColors.white54,
        size: 24,
      ),
    );

    if (imageUrl == null || imageUrl!.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: isUser
          ? BorderRadius.circular(25)
          : BorderRadius.circular(6),
      child: Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }
}
