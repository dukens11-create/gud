import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility functions for handling DateTime conversions from Firestore.
/// 
/// Firestore can store dates in two formats:
/// 1. Timestamp objects (when using FieldValue.serverTimestamp() or Timestamp.fromDate())
/// 2. ISO8601 Strings (when using DateTime.toIso8601String())
/// 
/// This utility provides safe conversion between both formats.
class DateTimeUtils {
  /// Safely converts a Firestore value to DateTime.
  /// 
  /// Handles both:
  /// - Firestore Timestamp objects → DateTime via .toDate()
  /// - ISO8601 String values → DateTime via DateTime.parse()
  /// - null values → returns null
  /// 
  /// Example usage:
  /// ```dart
  /// DateTime? createdAt = DateTimeUtils.parseDateTime(data['createdAt']);
  /// ```
  /// 
  /// Throws [FormatException] if the value is neither null, Timestamp, nor a valid date String.
  static DateTime? parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    
    // Handle Firestore Timestamp
    if (value is Timestamp) {
      return value.toDate();
    }
    
    // Handle ISO8601 String
    if (value is String) {
      return DateTime.parse(value);
    }
    
    // Handle DateTime (already converted)
    if (value is DateTime) {
      return value;
    }
    
    throw FormatException(
      'Cannot parse DateTime from type ${value.runtimeType}. '
      'Expected Timestamp, String, or null.',
    );
  }
  
  /// Converts a DateTime to Firestore Timestamp.
  /// 
  /// Use this when writing DateTime values to Firestore to ensure
  /// consistent storage format.
  /// 
  /// Returns null if the input is null.
  static Timestamp? toTimestamp(DateTime? dateTime) {
    return dateTime != null ? Timestamp.fromDate(dateTime) : null;
  }

  /// Format DateTime for display in UI
  /// 
  /// Formats as "MM/DD/YYYY HH:MM"
  /// 
  /// Example: "1/15/2024 14:30"
  static String formatDisplayDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
