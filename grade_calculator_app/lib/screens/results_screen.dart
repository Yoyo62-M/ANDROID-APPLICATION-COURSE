// lib/screens/results_screen.dart
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../models/calculator.dart';
import '../utils/excel_handler.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class ResultsScreen extends StatefulWidget {
  final List<StudentGrade> students;
  final Map<String, dynamic> summary;

  const ResultsScreen({
    super.key,
    required this.students,
    required this.summary,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _isDownloading = false;
  String _searchQuery = '';
  String _filterGrade = 'All';

  // Delayed init — computed once on first access
  late final List<String> _gradeOptions = [
    'All',
    ...{...widget.students.map((s) => s.grade)}.toList()..sort()
  ];

  // Lambda-style filtered list
  List<StudentGrade> get _filteredStudents => widget.students.where((s) {
        final matchSearch = _searchQuery.isEmpty ||
            s.studentName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            s.studentId.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchGrade =
            _filterGrade == 'All' || s.grade == _filterGrade;
        return matchSearch && matchGrade;
      }).toList();

  // Lambda for grade color
  Color _gradeColor(String grade) => switch (grade) {
        'A' => AppColors.gradeA,
        'AB' => AppColors.gradeAB,
        'B' => AppColors.gradeB,
        'C' => AppColors.gradeC,
        'D' => AppColors.gradeD,
        'F' => AppColors.gradeF,
        _ => AppColors.textSecondary,
      };

  Future<void> _downloadReport() async {
    setState(() => _isDownloading = true);
    try {
      final path = await ExcelHandler.instance.exportResults(
        widget.students,
        widget.summary,
      );
      if (!mounted) return;
      if (path != null) {
        showAppSnackbar(context, 'Report saved to: $path');
      } else {
        showAppSnackbar(context, 'Failed to save report.', isError: true);
      }
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: Row(
                  children: [
                    _buildSideSummary(),
                    Expanded(child: _buildTableArea()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios,
                color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RESULTS',
                  style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2)),
              Text('Grade Report',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const Spacer(),
          // Search bar
          Container(
            width: 240,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Search student...',
                hintStyle: TextStyle(color: AppColors.textMuted),
                prefixIcon:
                    Icon(Icons.search, color: AppColors.textMuted, size: 18),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Grade filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filterGrade,
                dropdownColor: AppColors.card,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13),
                items: _gradeOptions
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _filterGrade = v!),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Download button
          AccentButton(
            label: _isDownloading ? 'SAVING...' : 'DOWNLOAD REPORT',
            icon: Icons.download_rounded,
            onPressed: _isDownloading ? null : _downloadReport,
          ),
        ],
      ),
    );
  }

  Widget _buildSideSummary() {
    final s = widget.summary;
    final dist = s['distribution'] as Map<String, int>;

    return Container(
      width: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SUMMARY',
                style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2)),
            const SizedBox(height: 16),
            _summaryItem(Icons.people, 'Total Students',
                s['total'].toString(), AppColors.accent),
            _summaryItem(Icons.trending_up, 'Highest',
                (s['highest'] as double).toStringAsFixed(1), AppColors.gradeA),
            _summaryItem(Icons.trending_down, 'Lowest',
                (s['lowest'] as double).toStringAsFixed(1), AppColors.gradeF),
            _summaryItem(Icons.calculate, 'Class Avg',
                (s['average'] as double).toStringAsFixed(1), AppColors.gradeC),
            const SizedBox(height: 24),
            // Pass/Fail bar
            _buildPassFailBar(s),
            const SizedBox(height: 24),
            const Text('DISTRIBUTION',
                style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2)),
            const SizedBox(height: 12),
            ...dist.entries
                .map((e) => _gradeDistBar(e.key, e.value, s['total'] as int)),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(
      IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 10)),
                  Text(value,
                      style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassFailBar(Map<String, dynamic> s) {
    final total = s['total'] as int;
    final passCount = s['passCount'] as int;
    final passRate = s['passRate'] as double;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pass Rate: ${passRate.toStringAsFixed(0)}%',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: passCount / total,
            minHeight: 8,
            backgroundColor: AppColors.gradeF.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation(AppColors.gradeA),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pass: $passCount',
                style: const TextStyle(
                    color: AppColors.gradeA, fontSize: 11)),
            Text('Fail: ${s['failCount']}',
                style: const TextStyle(
                    color: AppColors.gradeF, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _gradeDistBar(String grade, int count, int total) {
    final color = _gradeColor(grade);
    final pct = count / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(grade,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              Text('$count (${(pct * 100).toStringAsFixed(0)}%)',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableArea() {
    final filtered = _filteredStudents;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text('${filtered.length} of ${widget.students.length} students',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: GlassCard(
              padding: EdgeInsets.zero,
              child: DataTable2(
                columnSpacing: 12,
                horizontalMargin: 16,
                headingRowHeight: 48,
                dataRowHeight: 52,
                headingRowColor: WidgetStateProperty.all(AppColors.surface),
                border: TableBorder(
                  horizontalInside:
                      BorderSide(color: AppColors.border, width: 0.5),
                ),
                columns: [
                  _col('Student ID', ColumnSize.S),
                  _col('Name', ColumnSize.L),
                  _col('Assignment', ColumnSize.S),
                  _col('Test', ColumnSize.S),
                  _col('Exam', ColumnSize.S),
                  _col('Final', ColumnSize.S),
                  _col('Grade', ColumnSize.S),
                  _col('Remark', ColumnSize.M),
                ],
                rows: filtered.map((s) {
                  final finalColor = s.finalMark >= 50
                      ? AppColors.gradeA
                      : AppColors.gradeF;
                  return DataRow2(
                    cells: [
                      _cell(s.studentId, AppColors.textSecondary),
                      _cell(s.studentName, AppColors.textPrimary,
                          bold: true),
                      _cell(s.assignmentMark.toStringAsFixed(1),
                          AppColors.textSecondary),
                      _cell(s.testMark.toStringAsFixed(1),
                          AppColors.textSecondary),
                      _cell(s.examMark.toStringAsFixed(1),
                          AppColors.textSecondary),
                      _cell(s.finalMark.toStringAsFixed(1), finalColor,
                          bold: true),
                      DataCell(GradeBadge(grade: s.grade)),
                      _cell(s.remark,
                          _gradeColor(s.grade).withOpacity(0.8)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataColumn2 _col(String label, ColumnSize size) => DataColumn2(
        label: Text(label,
            style: const TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
        size: size,
      );

  DataCell _cell(String val, Color color, {bool bold = false}) => DataCell(
        Text(val,
            style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
      );
}
