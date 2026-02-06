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
    if (value is DateTime) return value.toIso8601String();
    if (value is double) return value.toStringAsFixed(2);
    if (value is num) return value.toString();
    return value.toString();
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
