import 'package:flutter/material.dart';

/// Describes a single premium avatar option backed by a real image asset.
class AvatarOption {
  const AvatarOption({
    required this.id,
    required this.label,
    required this.assetPath,
    this.fallbackColorA = const Color(0xFF0984E3),
    this.fallbackColorB = const Color(0xFF74B9FF),
  });

  /// Unique identifier stored in user preferences.
  final String id;

  /// Human-readable label (e.g. "Tiger", "Panda").
  final String label;

  /// Path to the image asset under assets/avatars/.
  final String assetPath;

  /// Fallback gradient color A for when the image fails to load.
  final Color fallbackColorA;

  /// Fallback gradient color B for when the image fails to load.
  final Color fallbackColorB;
}

/// Premium avatar catalog — 12 image-backed premium avatars.
const List<AvatarOption> avatarOptions = [
  AvatarOption(
    id: 'fox_01',
    label: 'Fox',
    assetPath: 'assets/avatars/fox.png',
    fallbackColorA: Color(0xFFFF6B35),
    fallbackColorB: Color(0xFFF7931E),
  ),
  AvatarOption(
    id: 'panda_01',
    label: 'Panda',
    assetPath: 'assets/avatars/panda.png',
    fallbackColorA: Color(0xFF636E72),
    fallbackColorB: Color(0xFFB2BEC3),
  ),
  AvatarOption(
    id: 'wolf_01',
    label: 'Wolf',
    assetPath: 'assets/avatars/wolf.png',
    fallbackColorA: Color(0xFF4A69BD),
    fallbackColorB: Color(0xFF6A89CC),
  ),
  AvatarOption(
    id: 'owl_01',
    label: 'Owl',
    assetPath: 'assets/avatars/owl.png',
    fallbackColorA: Color(0xFF6C5CE7),
    fallbackColorB: Color(0xFFA29BFE),
  ),
  AvatarOption(
    id: 'tiger_01',
    label: 'Tiger',
    assetPath: 'assets/avatars/tiger.png',
    fallbackColorA: Color(0xFFE17055),
    fallbackColorB: Color(0xFFFF7675),
  ),
  AvatarOption(
    id: 'lion_01',
    label: 'Lion',
    assetPath: 'assets/avatars/lion.png',
    fallbackColorA: Color(0xFF00B894),
    fallbackColorB: Color(0xFF55EFC4),
  ),
  AvatarOption(
    id: 'cat_01',
    label: 'Cat',
    assetPath: 'assets/avatars/cat.png',
    fallbackColorA: Color(0xFFE84393),
    fallbackColorB: Color(0xFFFD79A8),
  ),
  AvatarOption(
    id: 'bear_01',
    label: 'Bear',
    assetPath: 'assets/avatars/bear.png',
    fallbackColorA: Color(0xFF6C5CE7),
    fallbackColorB: Color(0xFF4834D4),
  ),
  AvatarOption(
    id: 'ninja_01',
    label: 'Ninja',
    assetPath: 'assets/avatars/cyber_ninja.png',
    fallbackColorA: Color(0xFF0984E3),
    fallbackColorB: Color(0xFF74B9FF),
  ),
  AvatarOption(
    id: 'hacker_01',
    label: 'Hacker',
    assetPath: 'assets/avatars/hacker_boy.png',
    fallbackColorA: Color(0xFFFDCB6E),
    fallbackColorB: Color(0xFFE17055),
  ),
  AvatarOption(
    id: 'cipher_01',
    label: 'Cipher',
    assetPath: 'assets/avatars/cipher.svg',
    fallbackColorA: Color(0xFF00CEC9),
    fallbackColorB: Color(0xFF81ECEC),
  ),
  AvatarOption(
    id: 'nova_01',
    label: 'Nova',
    assetPath: 'assets/avatars/nova.svg',
    fallbackColorA: Color(0xFFFD79A8),
    fallbackColorB: Color(0xFF6C5CE7),
  ),
];

/// Returns the [AvatarOption] matching [id], or the first option as fallback.
AvatarOption avatarOptionById(String id) {
  return avatarOptions.firstWhere(
    (a) => a.id == id,
    orElse: () => avatarOptions.first,
  );
}

/// Returns the fallback color A for the avatar's primary gradient.
Color avatarColorForId(String id) {
  return avatarOptionById(id).fallbackColorA;
}

/// Returns the display label for an avatar ID.
String avatarLabelForId(String id) {
  return avatarOptionById(id).label;
}
