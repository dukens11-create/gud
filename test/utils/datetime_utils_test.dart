import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gud_app/utils/datetime_utils.dart';

void main() {
  group('DateTimeUtils.parseDateTime', () {
    test('should return null for null input', () {
      expect(DateTimeUtils.parseDateTime(null), isNull);
    });

    test('should convert Timestamp to DateTime', () {
      final now = DateTime.now();
      final timestamp = Timestamp.fromDate(now);
      final result = DateTimeUtils.parseDateTime(timestamp);
      
      expect(result, isNotNull);
      expect(result!.year, equals(now.year));
      expect(result.month, equals(now.month));
      expect(result.day, equals(now.day));
      expect(result.hour, equals(now.hour));
      expect(result.minute, equals(now.minute));
    });

    test('should parse ISO8601 String to DateTime', () {
      final now = DateTime.now();
      final iso8601String = now.toIso8601String();
      final result = DateTimeUtils.parseDateTime(iso8601String);
      
      expect(result, isNotNull);
      expect(result!.year, equals(now.year));
      expect(result.month, equals(now.month));
      expect(result.day, equals(now.day));
    });

    test('should handle DateTime input (pass-through)', () {
      final now = DateTime.now();
      final result = DateTimeUtils.parseDateTime(now);
      
      expect(result, equals(now));
    });

    test('should throw FormatException for invalid String', () {
      expect(
        () => DateTimeUtils.parseDateTime('invalid-date'),
        throwsA(isA<FormatException>()),
      );
    });

    test('should throw FormatException for unsupported type', () {
      expect(
        () => DateTimeUtils.parseDateTime(123),
        throwsA(isA<FormatException>()),
      );
    });

    test('should parse various date String formats', () {
      final testDates = [
        '2024-01-15T10:30:00.000Z',
        '2024-01-15T10:30:00.000',
        '2024-01-15',
      ];

      for (final dateString in testDates) {
        final result = DateTimeUtils.parseDateTime(dateString);
        expect(result, isNotNull);
        expect(result!.year, equals(2024));
        expect(result.month, equals(1));
        expect(result.day, equals(15));
      }
    });
  });

  group('DateTimeUtils.toTimestamp', () {
    test('should return null for null input', () {
      expect(DateTimeUtils.toTimestamp(null), isNull);
    });

    test('should convert DateTime to Timestamp', () {
      final now = DateTime.now();
      final result = DateTimeUtils.toTimestamp(now);
      
      expect(result, isNotNull);
      expect(result, isA<Timestamp>());
      
      final convertedBack = result!.toDate();
      expect(convertedBack.year, equals(now.year));
      expect(convertedBack.month, equals(now.month));
      expect(convertedBack.day, equals(now.day));
    });

    test('should handle round-trip conversion', () {
      final original = DateTime(2024, 1, 15, 10, 30, 0);
      final timestamp = DateTimeUtils.toTimestamp(original);
      final backToDateTime = DateTimeUtils.parseDateTime(timestamp);
      
      expect(backToDateTime, isNotNull);
      expect(backToDateTime!.year, equals(original.year));
      expect(backToDateTime.month, equals(original.month));
      expect(backToDateTime.day, equals(original.day));
      expect(backToDateTime.hour, equals(original.hour));
      expect(backToDateTime.minute, equals(original.minute));
    });
  });
}
