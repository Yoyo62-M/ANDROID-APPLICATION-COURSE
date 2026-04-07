// lib/services/file_parser_service.dart
import '../models/models.dart';

class FileParserService {
  /// Parse CSV text into StudentRecord list.
  /// Expected columns: id/student_id, name/student_name, ca/ca_score, exam/exam_score
  static List<StudentRecord> parseCsvText(String content) {
    final lines = content.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return [];

    // Detect header
    final header = lines.first.split(',').map((c) => c.trim().toLowerCase().replaceAll('"', '')).toList();

    int idIdx   = _findCol(header, ['student id', 'studentid', 'id', 'matric', 'reg']);
    int nameIdx = _findCol(header, ['student name', 'studentname', 'name', 'full name']);
    int caIdx   = _findCol(header, ['ca score', 'ca', 'ca_score', 'continuous', 'coursework']);
    int examIdx = _findCol(header, ['exam score', 'exam', 'exam_score', 'examination']);

    if (nameIdx < 0) nameIdx = 1;
    if (idIdx < 0) idIdx = 0;
    if (caIdx < 0) caIdx = 2;
    if (examIdx < 0) examIdx = 3;

    final records = <StudentRecord>[];
    for (int i = 1; i < lines.length; i++) {
      final cols = _splitCsvLine(lines[i]);
      if (cols.length < 2) continue;

      final id   = idIdx   < cols.length ? cols[idIdx].trim()   : 'S${i.toString().padLeft(3, '0')}';
      final name = nameIdx < cols.length ? cols[nameIdx].trim() : 'Student $i';
      final ca   = caIdx   < cols.length ? double.tryParse(cols[caIdx].trim())   ?? 0.0 : 0.0;
      final exam = examIdx < cols.length ? double.tryParse(cols[examIdx].trim()) ?? 0.0 : 0.0;

      records.add(StudentRecord(
        id: id,
        name: name,
        caScore: ca,
        examScore: exam,
      ));
    }
    return records;
  }

  static int _findCol(List<String> header, List<String> candidates) {
    for (final c in candidates) {
      final idx = header.indexWhere((h) => h.contains(c));
      if (idx >= 0) return idx;
    }
    return -1;
  }

  static List<String> _splitCsvLine(String line) {
    final result = <String>[];
    bool inQuotes = false;
    final buf = StringBuffer();
    for (final ch in line.runes) {
      final c = String.fromCharCode(ch);
      if (c == '"') {
        inQuotes = !inQuotes;
      } else if (c == ',' && !inQuotes) {
        result.add(buf.toString());
        buf.clear();
      } else {
        buf.write(c);
      }
    }
    result.add(buf.toString());
    return result;
  }

  /// Generate sample CSV data for demo
  static String generateSampleCsv() {
    return '''Student ID,Student Name,CA Score,Exam Score
STU001,Alice Johnson,28,65
STU002,Bob Smith,22,58
STU003,Carol Williams,30,70
STU004,David Brown,15,40
STU005,Eve Davis,25,62
STU006,Frank Miller,18,35
STU007,Grace Wilson,27,68
STU008,Henry Moore,20,50
STU009,Ivy Taylor,29,72
STU010,Jack Anderson,12,28
STU011,Karen Thomas,26,61
STU012,Liam Jackson,24,55
STU013,Mia White,30,69
STU014,Noah Harris,16,42
STU015,Olivia Martin,23,60
STU016,Peter Garcia,19,48
STU017,Quinn Martinez,28,66
STU018,Rachel Robinson,21,52
STU019,Sam Clark,17,38
STU020,Tina Rodriguez,25,63''';
  }
}
