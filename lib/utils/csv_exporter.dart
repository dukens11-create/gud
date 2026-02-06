import 'package:csv/csv.dart';

class CsvExporter {
  static String listToCSV(List<List<dynamic>> data) {
    return const ListToCsvConverter().convert(data);
  }
  
  static String mapListToCSV(List<Map<String, dynamic>> data, List<String> headers) {
    if (data.isEmpty) {
      return const ListToCsvConverter().convert([headers]);
    }
    
    final rows = <List<dynamic>>[headers];
    
    for (final item in data) {
      final row = headers.map((header) {
        final value = item[header];
        return _formatValue(value);
      }).toList();
      rows.add(row);
    }
    
    return const ListToCsvConverter().convert(rows);
  }
  
  static String _formatValue(dynamic value) {
    if (value == null) return '';
    
    String stringValue;
    if (value is DateTime) {
      stringValue = value.toIso8601String();
    } else if (value is double) {
      stringValue = value.toStringAsFixed(2);
    } else if (value is num) {
      stringValue = value.toString();
    } else {
      stringValue = value.toString();
    }
    
    // Prevent CSV injection by sanitizing values that start with formula characters
    return _sanitizeForCSV(stringValue);
  }
  
  /// Sanitizes CSV values to prevent formula injection attacks
  /// Values starting with =, +, -, @, or tab are prefixed with a single quote
  static String _sanitizeForCSV(String value) {
    if (value.isEmpty) return value;
    
    final firstChar = value[0];
    // Check for formula injection characters
    if (firstChar == '=' || 
        firstChar == '+' || 
        firstChar == '-' || 
        firstChar == '@' ||
        firstChar == '\t' ||
        firstChar == '\r') {
      // Prefix with single quote to treat as text
      return "'$value";
    }
    
    return value;
  }
  
  static List<List<String>> parseCSV(String csvString) {
    return const CsvToListConverter().convert(csvString)
        .map((row) => row.map((cell) => cell.toString()).toList())
        .toList();
  }
  
  static String escapeCSVValue(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
