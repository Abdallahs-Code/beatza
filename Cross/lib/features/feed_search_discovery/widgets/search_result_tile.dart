












import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';

class SearchResultTile extends StatelessWidget {
  final String id;
  final String type;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final VoidCallback onTap;

  const SearchResultTile({
    super.key,
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.imageUrl,
    required this.onTap,
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
                    style: TextStyle(
                      color: AppColors.whiteSmoke,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
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

            
            if (type == 'user')
              _buildFollowChip()
            else
              Icon(Icons.chevron_right, color: AppColors.white54, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    final bool isUser = type == 'user';
    final double size = 50;

    Widget placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: isUser
            ? BorderRadius.circular(size / 2)
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
          ? BorderRadius.circular(size / 2)
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

  Widget _buildFollowChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.white54),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Follow',
        style: TextStyle(color: AppColors.whiteSmoke, fontSize: 12),
      ),
    );
  }
}
