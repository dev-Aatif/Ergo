import 'package:flutter/material.dart';

/// Safely parses a hex color string like '#FF9800' or '0xFF9800'.
/// Returns [fallback] if parsing fails.
Color safeParseColor(String hex, {Color fallback = const Color(0xFF607D8B)}) {
  try {
    final trimmed = hex.trim();
    if (trimmed.startsWith('#')) {
      return Color(int.parse(trimmed.replaceFirst('#', '0xFF')));
    } else if (trimmed.startsWith('0x') || trimmed.startsWith('0X')) {
      return Color(int.parse(trimmed));
    } else {
      return Color(int.parse('0xFF$trimmed'));
    }
  } catch (_) {
    return fallback;
  }
}

/// Single source of truth for mapping icon names to IconData.
/// Checks the DB `iconName` first, then falls back to category name matching.
IconData getIconForName(String name) {
  switch (name.toLowerCase()) {
    // DB icon_name values
    case 'history':
    case 'auto_stories':
    case 'auto_stories_rounded':
      return Icons.auto_stories_rounded;
    case 'movie_filter_rounded':
    case 'anime':
      return Icons.movie_filter_rounded;
    case 'theaters_rounded':
    case 'theaters':
    case 'movies':
      return Icons.theaters_rounded;
    case 'science':
    case 'science_rounded':
      return Icons.science_rounded;
    case 'sports_cricket':
    case 'sports_cricket_rounded':
    case 'sports':
      return Icons.sports_cricket_rounded;
    case 'earth':
    case 'public':
    case 'geography':
      return Icons.public_rounded;
    case 'movie':
    case 'entertainment':
      return Icons.movie_rounded;
    case 'landmark':
      return Icons.account_balance_rounded;
    case 'music_note':
    case 'music':
      return Icons.music_note_rounded;
    case 'computer':
    case 'technology':
      return Icons.computer_rounded;
    default:
      return Icons.menu_book_rounded;
  }
}
