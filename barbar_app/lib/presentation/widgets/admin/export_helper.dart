import 'package:flutter/material.dart';

class ExportHelper {
  static String generateCsv({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(headers.map((h) => _escapeCsvField(h)).join(','));
    for (final row in rows) {
      buffer.writeln(row.map((cell) => _escapeCsvField(cell)).join(','));
    }
    return buffer.toString();
  }

  static String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  static void copyToClipboard(BuildContext context, String content) {
    // Placeholder — in real app, clipboard or share sheet
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CSV data generated (copy/share in real app)'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
