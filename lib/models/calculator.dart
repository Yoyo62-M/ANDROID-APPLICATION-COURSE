// lib/models/calculator.dart
// ============================================================
// OOP: Abstract base class — Calculator
// GradeCalculator inherits from Calculator (Inheritance)
// Polymorphism via overriding calculate()
// Lazy/Delayed initialization via late keyword
// Lambdas used throughout
// ============================================================

// ── Abstract Base Class ──────────────────────────────────────
abstract class Calculator {
  // Abstract method — must be overridden by subclasses (Polymorphism)
  double calculate(List<double> values);

  // Concrete method shared by all calculators
  double sum(List<double> values) =>
      values.fold(0.0, (prev, element) => prev + element); // Lambda

  double average(List<double> values) =>
      values.isEmpty ? 0.0 : sum(values) / values.length; // Lambda
}

// ── Grade Model ──────────────────────────────────────────────
class StudentGrade {
  final String studentId;
  final String studentName;
  final double assignmentMark;
  final double testMark;
  final double examMark;

  // Delayed / Lazy initialization
  late final double finalMark;
  late final String grade;
  late final String remark;
  late final String gradePoints;

  StudentGrade({
    required this.studentId,
    required this.studentName,
    required this.assignmentMark,
    required this.testMark,
    required this.examMark,
  }) {
    // Delayed init — calculated once after construction
    finalMark = _computeFinalMark();
    grade = GradeCalculator.instance.assignGrade(finalMark);
    remark = GradeCalculator.instance.assignRemark(finalMark);
    gradePoints = GradeCalculator.instance.assignGradePoints(finalMark);
  }

  // Lambda-style private computation
  double _computeFinalMark() =>
      (assignmentMark * 0.20) + (testMark * 0.30) + (examMark * 0.50);

  Map<String, dynamic> toMap() => {
        'Student ID': studentId,
        'Student Name': studentName,
        'Assignment (20%)': assignmentMark.toStringAsFixed(1),
        'Test (30%)': testMark.toStringAsFixed(1),
        'Exam (50%)': examMark.toStringAsFixed(1),
        'Final Mark': finalMark.toStringAsFixed(1),
        'Grade': grade,
        'Grade Points': gradePoints,
        'Remark': remark,
      };
}

// ── Grade Calculation Config ─────────────────────────────────
class GradeRange {
  final double min;
  final double max;
  final String grade;
  final String gradePoints;
  final String remark;
  const GradeRange(this.min, this.max, this.grade, this.gradePoints, this.remark);
}

// ── Derived Class: GradeCalculator (Inherits Calculator) ─────
class GradeCalculator extends Calculator {
  // Singleton instance (lazy)
  static final GradeCalculator instance = GradeCalculator._internal();
  GradeCalculator._internal();

  // Lazy initialization of grade ranges (Delayed init)
  late final List<GradeRange> _gradeRanges = _buildGradeRanges();

  // Lambda to build grade ranges
  List<GradeRange> _buildGradeRanges() => [
        const GradeRange(75, 100, 'A', '4.0', 'Distinction'),
        const GradeRange(70, 74.99, 'AB', '3.5', 'Merit'),
        const GradeRange(60, 69.99, 'B', '3.0', 'Credit'),
        const GradeRange(50, 59.99, 'C', '2.0', 'Pass'),
        const GradeRange(40, 49.99, 'D', '1.0', 'Supplementary'),
        const GradeRange(0, 39.99, 'F', '0.0', 'Fail'),
      ];

  // Polymorphism — overrides abstract calculate()
  @override
  double calculate(List<double> values) {
    // Weighted: assignment 20%, test 30%, exam 50%
    if (values.length < 3) return 0.0;
    return (values[0] * 0.20) + (values[1] * 0.30) + (values[2] * 0.50);
  }

  // Lambda-style grade lookup
  String assignGrade(double mark) =>
      _gradeRanges
          .firstWhere(
            (r) => mark >= r.min && mark <= r.max,
            orElse: () => const GradeRange(0, 0, 'F', '0.0', 'Fail'),
          )
          .grade;

  String assignRemark(double mark) =>
      _gradeRanges
          .firstWhere(
            (r) => mark >= r.min && mark <= r.max,
            orElse: () => const GradeRange(0, 0, 'F', '0.0', 'Fail'),
          )
          .remark;

  String assignGradePoints(double mark) =>
      _gradeRanges
          .firstWhere(
            (r) => mark >= r.min && mark <= r.max,
            orElse: () => const GradeRange(0, 0, 'F', '0.0', 'Fail'),
          )
          .gradePoints;

  // Process a full list of students using lambdas
  List<StudentGrade> processStudents(List<StudentGrade> students) =>
      students.map((s) => s).toList(); // already processed in constructor

  // Summary statistics using lambdas
  Map<String, dynamic> generateSummary(List<StudentGrade> students) {
    if (students.isEmpty) return {};

    final marks = students.map((s) => s.finalMark).toList();
    final highest = marks.reduce((a, b) => a > b ? a : b);
    final lowest = marks.reduce((a, b) => a < b ? a : b);
    final avg = average(marks);

    // Grade distribution using lambda + fold
    final distribution = students.fold<Map<String, int>>(
      {},
      (map, s) {
        map[s.grade] = (map[s.grade] ?? 0) + 1;
        return map;
      },
    );

    final passCount = students.where((s) => s.finalMark >= 50).length;
    final failCount = students.length - passCount;
    final passRate = (passCount / students.length * 100);

    return {
      'total': students.length,
      'highest': highest,
      'lowest': lowest,
      'average': avg,
      'distribution': distribution,
      'passCount': passCount,
      'failCount': failCount,
      'passRate': passRate,
    };
  }
}
