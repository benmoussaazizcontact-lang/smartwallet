import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/supabase_provider.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseProvider));
});

String? _avatarObjectPath(String storedValue) {
  final value = storedValue.trim();
  if (value.isEmpty) return null;

  final uri = Uri.tryParse(value);
  if (uri?.hasScheme == true) {
    final segments = uri!.pathSegments;
    final objectIndex = segments.indexOf('object');
    if (objectIndex >= 0 && objectIndex + 2 < segments.length) {
      final bucketIndex = objectIndex + 2;
      if (segments[bucketIndex] == 'avatars' &&
          bucketIndex + 1 < segments.length) {
        return Uri.decodeComponent(segments.skip(bucketIndex + 1).join('/'));
      }
    }
    // Keep URLs from external avatar providers working as before.
    return null;
  }

  const legacyPrefix = '/object/public/avatars/';
  final legacyIndex = value.indexOf(legacyPrefix);
  if (legacyIndex >= 0) {
    return Uri.decodeComponent(
      value.substring(legacyIndex + legacyPrefix.length),
    );
  }
  final normalized = value.startsWith('avatars/')
      ? value.substring('avatars/'.length)
      : value.startsWith('/')
      ? value.substring(1)
      : value;
  return Uri.decodeComponent(normalized);
}

final profileAvatarUrlProvider = FutureProvider.family<String?, String?>((
  ref,
  storedPath,
) async {
  if (storedPath == null || storedPath.isEmpty) return null;
  final objectPath = _avatarObjectPath(storedPath);
  if (objectPath == null) return storedPath;
  return ref
      .watch(supabaseProvider)
      .storage
      .from('avatars')
      .createSignedUrl(objectPath, 60 * 60);
});

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  /// Met à jour le profil dans la table `profiles`.
  /// RLS garantit que l'utilisateur ne peut modifier que son propre profil.
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? bio,
    String? avatarUrl,
    String? preferredCurrency,
    String? themeMode,
  }) async {
    final userId = _client.auth.currentSession?.user.id;
    if (userId == null) throw const AppException('Session expirée');

    final updates = <String, dynamic>{
      if (firstName != null) 'first_name': firstName.trim(),
      if (lastName != null) 'last_name': lastName.trim(),
      if (firstName != null || lastName != null)
        'full_name': '${(firstName ?? '').trim()} ${(lastName ?? '').trim()}'
            .trim(),
      if (phone != null) 'phone': phone.trim(),
      if (bio != null) 'bio': bio.trim(),
      'avatar_url': ?avatarUrl,
      'preferred_currency': ?preferredCurrency,
      'theme_mode': ?themeMode,
    };
    if (updates.isEmpty) return;

    try {
      // `upsert` requires broad UPDATE table privileges for its ON CONFLICT
      // path. This app intentionally grants only column-level UPDATE access.
      // Update the authenticated user's existing profile first, then insert
      // only when the profile row has not yet been created.
      final updated = await _client
          .from('profiles')
          .update(updates)
          .eq('id', userId)
          .select('id')
          .maybeSingle();
      if (updated == null) {
        await _client.from('profiles').insert({'id': userId, ...updates});
      }
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Upload d'avatar vers Supabase Storage et retourne l'URL publique.
  Future<String> uploadAvatar({
    required List<int> bytes,
    required String extension,
  }) async {
    final userId = _client.auth.currentSession?.user.id;
    if (userId == null) throw const AppException('Session expirée');

    final path = '$userId/avatar.$extension';
    try {
      final normalizedExtension = extension.toLowerCase();
      final contentType = switch (normalizedExtension) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => throw const AppException('Format d’image non pris en charge.'),
      };
      await _client.storage
          .from('avatars')
          .uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );
      return path;
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
