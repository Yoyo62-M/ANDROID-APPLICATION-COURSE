// lib/models/models.dart
import 'dart:math';

// ─── Core Data Classes ────────────────────────────────────────────────────────

class StudentRecord {
  final String id;
  final String name;
  double caScore;
  double examScore;
  double finalScore;
  String grade;
  String status;
  bool hasError;
  String errorMessage;

  StudentRecord({
    required this.id,
    required this.name,
    this.caScore = 0.0,
    this.examScore = 0.0,
    this.finalScore = 0.0,
    this.grade = '',
    this.status = '',
    this.hasError = false,
    this.errorMessage = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'caScore': caScore,
        'examScore': examScore,
        'finalScore': finalScore,
        'grade': grade,
        'status': status,
        'hasError': hasError,
        'errorMessage': errorMessage,
      };

  factory StudentRecord.fromJson(Map<String, dynamic> j) => StudentRecord(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        caScore: (j['caScore'] as num?)?.toDouble() ?? 0.0,
        examScore: (j['examScore'] as num?)?.toDouble() ?? 0.0,
        finalScore: (j['finalScore'] as num?)?.toDouble() ?? 0.0,
        grade: j['grade'] ?? '',
        status: j['status'] ?? '',
        hasError: j['hasError'] ?? false,
        errorMessage: j['errorMessage'] ?? '',
      );

  StudentRecord copyWith({
    double? caScore,
    double? examScore,
    double? finalScore,
    String? grade,
    String? status,
    bool? hasError,
    String? errorMessage,
  }) =>
      StudentRecord(
        id: id,
        name: name,
        caScore: caScore ?? this.caScore,
        examScore: examScore ?? this.examScore,
        finalScore: finalScore ?? this.finalScore,
        grade: grade ?? this.grade,
        status: status ?? this.status,
        hasError: hasError ?? this.hasError,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class GradeRange {
  final double minScore;
  final double maxScore;
  final String grade;
  final String colorHex;

  const GradeRange({
    required this.minScore,
    required this.maxScore,
    required this.grade,
    this.colorHex = '#000000',
  });

  Map<String, dynamic> toJson() => {
        'minScore': minScore,
        'maxScore': maxScore,
        'grade': grade,
        'colorHex': colorHex,
      };

  factory GradeRange.fromJson(Map<String, dynamic> j) => GradeRange(
        minScore: (j['minScore'] as num).toDouble(),
        maxScore: (j['maxScore'] as num).toDouble(),
        grade: j['grade'],
        colorHex: j['colorHex'] ?? '#000000',
      );
}

class GradingScale {
  final String id;
  final String name;
  final List<GradeRange> ranges;
  final bool isDefault;

  const GradingScale({
    required this.id,
    required this.name,
    required this.ranges,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ranges': ranges.map((r) => r.toJson()).toList(),
        'isDefault': isDefault,
      };

  factory GradingScale.fromJson(Map<String, dynamic> j) => GradingScale(
        id: j['id'],
        name: j['name'],
        ranges: (j['ranges'] as List).map((r) => GradeRange.fromJson(r)).toList(),
        isDefault: j['isDefault'] ?? false,
      );

  String getGrade(double score) {
    for (final r in ranges) {
      if (score >= r.minScore && score <= r.maxScore) return r.grade;
    }
    return 'N/A';
  }

  String getColorHex(double score) {
    for (final r in ranges) {
      if (score >= r.minScore && score <= r.maxScore) return r.colorHex;
    }
    return '#000000';
  }
}

class ProcessedFile {
  final String id;
  final String fileName;
  final String importDateStr;
  final List<StudentRecord> students;
  final String fileType;
  final String gradingScaleUsed;

  const ProcessedFile({
    required this.id,
    required this.fileName,
    required this.importDateStr,
    required this.students,
    required this.fileType,
    required this.gradingScaleUsed,
  });

  int get totalStudents => students.length;
  int get passCount => students.where((s) => s.finalScore >= 40.0).length;
  double get passRate => totalStudents > 0 ? (passCount / totalStudents) * 100 : 0.0;
  double get average =>
      students.isEmpty ? 0.0 : students.map((s) => s.finalScore).reduce((a, b) => a + b) / students.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'importDateStr': importDateStr,
        'students': students.map((s) => s.toJson()).toList(),
        'fileType': fileType,
        'gradingScaleUsed': gradingScaleUsed,
      };

  factory ProcessedFile.fromJson(Map<String, dynamic> j) => ProcessedFile(
        id: j['id'],
        fileName: j['fileName'],
        importDateStr: j['importDateStr'],
        students: (j['students'] as List).map((s) => StudentRecord.fromJson(s)).toList(),
        fileType: j['fileType'],
        gradingScaleUsed: j['gradingScaleUsed'],
      );
}

class ClassStatistics {
  final double average;
  final double median;
  final double highest;
  final double lowest;
  final int passCount;
  final int failCount;
  final int totalStudents;
  final double standardDeviation;
  final Map<String, int> gradeDistribution;

  const ClassStatistics({
    required this.average,
    required this.median,
    required this.highest,
    required this.lowest,
    required this.passCount,
    required this.failCount,
    required this.totalStudents,
    required this.standardDeviation,
    required this.gradeDistribution,
  });

  double get passRate => totalStudents > 0 ? (passCount / totalStudents) * 100 : 0.0;
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final String studentName;

  const ValidationResult({
    required this.isValid,
    required this.errors,
    required this.studentName,
  });
}

// ─── Enums ────────────────────────────────────────────────────────────────────

enum FileType { excel, csv, googleSheet }

enum ExportFormat { excel, csv, pdf, json }

enum AppView { home, vault, settings }

enum SortColumn { id, name, caScore, examScore, finalScore, grade }

// ─── Default Grading Scales ───────────────────────────────────────────────────

const kDefaultGradingScale = GradingScale(
  id: 'standard',
  name: 'Standard (A–F)',
  isDefault: true,
  ranges: [
    GradeRange(minScore: 70.0, maxScore: 100.0, grade: 'A', colorHex: '#4CAF50'),
    GradeRange(minScore: 60.0, maxScore: 69.99, grade: 'B', colorHex: '#8BC34A'),
    GradeRange(minScore: 50.0, maxScore: 59.99, grade: 'C', colorHex: '#FF9800'),
    GradeRange(minScore: 40.0, maxScore: 49.99, grade: 'D', colorHex: '#FF5722'),
    GradeRange(minScore: 0.0,  maxScore: 39.99, grade: 'F', colorHex: '#F44336'),
  ],
);

const kDistinctionScale = GradingScale(
  id: 'distinction',
  name: 'Distinction Scale',
  ranges: [
    GradeRange(minScore: 80.0, maxScore: 100.0, grade: 'Distinction', colorHex: '#2196F3'),
    GradeRange(minScore: 65.0, maxScore: 79.99, grade: 'Credit',      colorHex: '#4CAF50'),
    GradeRange(minScore: 50.0, maxScore: 64.99, grade: 'Merit',       colorHex: '#FF9800'),
    GradeRange(minScore: 40.0, maxScore: 49.99, grade: 'Pass',        colorHex: '#FF5722'),
    GradeRange(minScore: 0.0,  maxScore: 39.99, grade: 'Fail',        colorHex: '#F44336'),
  ],
);

// ─── Extension / Helper Functions ────────────────────────────────────────────

ValidationResult validateScores(StudentRecord s) {
  final errors = <String>[];
  if (s.caScore > 30.0) errors.add('CA score (${s.caScore}) exceeds maximum of 30');
  if (s.examScore > 70.0) errors.add('Exam score (${s.examScore}) exceeds maximum of 70');
  if (s.caScore < 0 || s.examScore < 0) errors.add('Scores cannot be negative');
  return ValidationResult(isValid: errors.isEmpty, errors: errors, studentName: s.name);
}

ClassStatistics computeStatistics(List<StudentRecord> students) {
  if (students.isEmpty) {
    return const ClassStatistics(
      average: 0, median: 0, highest: 0, lowest: 0,
      passCount: 0, failCount: 0, totalStudents: 0,
      standardDeviation: 0, gradeDistribution: {},
    );
  }
  final scores = students.map((s) => s.finalScore).toList();
  final avg = scores.reduce((a, b) => a + b) / scores.length;
  final sorted = [...scores]..sort();
  final median = sorted.length % 2 == 0
      ? (sorted[sorted.length ~/ 2 - 1] + sorted[sorted.length ~/ 2]) / 2.0
      : sorted[sorted.length ~/ 2];
  final variance = scores.map((s) => (s - avg) * (s - avg)).reduce((a, b) => a + b) / scores.length;
  final dist = <String, int>{};
  for (final s in students) {
    dist[s.grade] = (dist[s.grade] ?? 0) + 1;
  }
  return ClassStatistics(
    average: avg,
    median: median,
    highest: scores.reduce((a, b) => a > b ? a : b),
    lowest: scores.reduce((a, b) => a < b ? a : b),
    passCount: students.where((s) => s.finalScore >= 40.0).length,
    failCount: students.where((s) => s.finalScore < 40.0).length,
    totalStudents: students.length,
    standardDeviation: sqrt(variance),
    gradeDistribution: dist,
  );
}
