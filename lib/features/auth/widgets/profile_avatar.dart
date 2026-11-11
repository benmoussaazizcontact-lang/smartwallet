import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../repositories/profile_repository.dart';

class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({
    super.key,
    required this.storedPath,
    required this.fallbackText,
    required this.radius,
  });

  final String? storedPath;
  final String fallbackText;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarAsync = ref.watch(profileAvatarUrlProvider(storedPath));
    final avatarUrl = avatarAsync.asData?.value;
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      child: Text(
        fallbackText.isEmpty ? '?' : fallbackText[0].toUpperCase(),
        style: TextStyle(
          fontSize: radius * 0.72,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );

    if (avatarUrl == null) return fallback;
    return ClipOval(
      child: Image.network(
        avatarUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}
