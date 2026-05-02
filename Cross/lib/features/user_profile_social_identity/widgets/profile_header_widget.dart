// Dart imports
import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';

// Package imports
import 'package:cross_team5/features/user_profile_social_identity/models/user_profile_model.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final UserProfileModel userProfile;

  const ProfileHeaderWidget({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          height: 280,
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 64),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark2,
            image: userProfile.bannerImgLink.trim().isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(userProfile.bannerImgLink),
                    fit: BoxFit.cover,
                    onError: (_, _) {},
                  )
                : null,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.pureBlack.withValues(alpha: 0.08),
                  AppColors.pureBlack.withValues(alpha: 0.65),
                ],
              ),
            ),
            child: userProfile.bannerImgLink.trim().isEmpty
                ? Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 48,
                      color: AppColors.white54,
                    ),
                  )
                : null,
          ),
        ),
        Positioned(
          bottom: 0,
          child: Hero(
            tag: 'avatar_${userProfile.userId}',
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.homeBackground, width: 5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.pureBlack.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 64,
                backgroundColor: AppColors.surfaceMid,
                child: ClipOval(
                  child: SizedBox(
                    width: 128,
                    height: 128,
                    child: userProfile.profileImgLink.trim().isNotEmpty
                        ? Image.network(
                            userProfile.profileImgLink,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) {
                              return const _AvatarFallback();
                            },
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                          )
                        : const _AvatarFallback(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceMid,
      child: Icon(Icons.person, size: 52, color: AppColors.greyZinc),
    );
  }
}
