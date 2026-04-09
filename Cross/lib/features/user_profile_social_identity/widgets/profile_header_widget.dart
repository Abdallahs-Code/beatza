// Dart imports
import 'package:flutter/material.dart';

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
            color: const Color(0xFF141414),
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
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.65),
                ],
              ),
            ),
            child: userProfile.bannerImgLink.trim().isEmpty
                ? const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 48,
                      color: Colors.white38,
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
                border: Border.all(color: const Color(0xFF0A0A0A), width: 5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 64,
                backgroundColor: const Color(0xFF1E1E1E),
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
      color: const Color(0xFF1E1E1E),
      child: const Icon(Icons.person, size: 52, color: Color(0xFF71717A)),
    );
  }
}
