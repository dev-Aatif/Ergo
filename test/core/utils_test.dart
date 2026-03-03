import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ergo/core/utils.dart';

void main() {
  group('safeParseColor', () {
    test('parses standard hex with # prefix', () {
      final color = safeParseColor('#FF9800');
      expect(color, const Color(0xFFFF9800));
    });

    test('parses hex without # prefix', () {
      final color = safeParseColor('0xFFFF9800');
      expect(color, const Color(0xFFFF9800));
    });

    test('returns fallback for invalid hex', () {
      final color = safeParseColor('not-a-color');
      expect(color, const Color(0xFF607D8B)); // default fallback
    });

    test('returns custom fallback for invalid hex', () {
      final color = safeParseColor('broken', fallback: const Color(0xFFFF0000));
      expect(color, const Color(0xFFFF0000));
    });

    test('returns fallback for empty string', () {
      final color = safeParseColor('');
      expect(color, const Color(0xFF607D8B));
    });

    test('returns fallback for partial hex', () {
      final color = safeParseColor('#GGG');
      expect(color, const Color(0xFF607D8B));
    });

    test('handles hex with extra whitespace', () {
      final color = safeParseColor('  #FF9800  ');
      expect(color, const Color(0xFFFF9800));
    });
  });

  group('getIconForName', () {
    test('returns correct icon for history', () {
      expect(getIconForName('history'), Icons.auto_stories_rounded);
    });

    test('returns correct icon for anime', () {
      expect(getIconForName('anime'), Icons.movie_filter_rounded);
    });

    test('returns correct icon for movies', () {
      expect(getIconForName('movies'), Icons.theaters_rounded);
    });

    test('returns correct icon for science', () {
      expect(getIconForName('science'), Icons.science_rounded);
    });

    test('returns correct icon for sports', () {
      expect(getIconForName('sports'), Icons.sports_cricket_rounded);
    });

    test('returns correct icon for geography (earth)', () {
      expect(getIconForName('earth'), Icons.public_rounded);
    });

    test('returns correct icon for entertainment', () {
      expect(getIconForName('entertainment'), Icons.movie_rounded);
    });

    test('returns correct icon for landmark', () {
      expect(getIconForName('landmark'), Icons.account_balance_rounded);
    });

    test('returns default icon for unknown name', () {
      expect(getIconForName('xyz_unknown'), Icons.menu_book_rounded);
    });

    test('is case insensitive', () {
      expect(getIconForName('HISTORY'), Icons.auto_stories_rounded);
      expect(getIconForName('Movies'), Icons.theaters_rounded);
    });
  });
}
