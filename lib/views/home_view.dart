// lib/views/home_view.dart
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/models.dart' hide FileType;
import '../theme/app_theme.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grade Calculator',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          if (state.importedStudents.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear data',
              onPressed: state.clearCurrentData,
            ),
          IconButton(
            icon: Icon(state.isDarkTheme ? Icons.light_mode : Icons.dark_mode),
            onPressed: state.toggleTheme,
          ),
        ],
        bottom: state.importedStudents.isNotEmpty
            ? PreferredSize(
                preferredSize: const Size.fromHeight(32),
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${state.importedStudents.length} students  •  ${state.currentFileName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(153),
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.importedStudents.isEmpty
              ? _EmptyState(onSampleLoad: state.loadSampleData)
              : _StudentsContent(state: state),
      floatingActionButton: state.importedStudents.isEmpty
          ? null
          : state.isProcessed
              ? FloatingActionButton.extended(
                  onPressed: state.saveToVault,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save to Vault'),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                )
              : FloatingActionButton.extended(
                  onPressed: state.processGrades,
                  icon: const Icon(Icons.calculate),
                  label: const Text('Process Grades'),
                ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onSampleLoad;
  const _EmptyState({required this.onSampleLoad});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.upload_file_outlined,
                size: 80, color: cs.primary.withAlpha(128)),
            const SizedBox(height: 24),
            Text(
              'Import Student Grades',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Upload a file with student ID, name, CA score, and exam score.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withAlpha(153),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // ── Supported formats row ──────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FormatBadge('CSV', Icons.table_rows_outlined, const Color(0xFF4CAF50)),
                _FormatBadge('Excel', Icons.grid_on_outlined, const Color(0xFF2196F3)),
                _FormatBadge('PDF', Icons.picture_as_pdf_outlined, const Color(0xFFF44336)),
                _FormatBadge('JSON', Icons.code_outlined, const Color(0xFFFF9800)),
              ],
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => _showImportSheet(context),
              icon: const Icon(Icons.upload_file),
              label: const Text('Import File'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onSampleLoad,
              icon: const Icon(Icons.science_outlined),
              label: const Text('Load Sample Data'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small badge showing a supported format ────────────────────────────────────
class _FormatBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _FormatBadge(this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

// ─── Import Bottom Sheet ──────────────────────────────────────────────────────

void _showImportSheet(BuildContext context) {
  final state = context.read<AppState>();
  final textCtrl = TextEditingController();
  final nameCtrl = TextEditingController(text: 'grades.csv');

  String selectedType = 'CSV';

  String _hintForType(String t) {
    switch (t) {
      case 'Excel':
        return 'Copy rows from Excel. Columns:\nStudent ID | Name | CA Score | Exam Score';
      case 'PDF':
        return 'Copy the table text from your PDF.\nOne student per line, values comma or tab separated.';
      case 'JSON':
        return 'Format: [{"id":"STU001","name":"Alice","ca":28,"exam":65}, ...]';
      default:
        return 'Columns: Student ID, Student Name, CA Score, Exam Score\nExample: STU001,Alice Johnson,28,65';
    }
  }

  String _placeholderForType(String t) {
    switch (t) {
      case 'Excel':
        return 'STU001\tAlice Johnson\t28\t65\nSTU002\tBob Smith\t22\t58';
      case 'PDF':
        return 'STU001, Alice Johnson, 28, 65\nSTU002, Bob Smith, 22, 58';
      case 'JSON':
        return '[\n  {"id":"STU001","name":"Alice Johnson","ca":28,"exam":65},\n  {"id":"STU002","name":"Bob Smith","ca":22,"exam":58}\n]';
      default:
        return 'Student ID,Student Name,CA Score,Exam Score\nSTU001,Alice Johnson,28,65\nSTU002,Bob Smith,22,58';
    }
  }

  String _convertToCsv(String raw, String type) {
    if (type == 'JSON') {
      try {
        final sb = StringBuffer();
        sb.writeln('Student ID,Student Name,CA Score,Exam Score');
        final objRx = RegExp(r'\{([^}]+)\}');
        final fldRx = RegExp(r'"(\w+)"\s*:\s*"?([^",}]+)"?');
        for (final m in objRx.allMatches(raw)) {
          String id = '', name = '', ca = '0', exam = '0';
          for (final f in fldRx.allMatches(m.group(1)!)) {
            final k = f.group(1)!.toLowerCase();
            final v = f.group(2)!.trim();
            if (k == 'id' || k == 'student_id') id = v;
            if (k == 'name' || k == 'student_name') name = v;
            if (k == 'ca' || k == 'ca_score') ca = v;
            if (k == 'exam' || k == 'exam_score') exam = v;
          }
          sb.writeln('$id,$name,$ca,$exam');
        }
        return sb.toString();
      } catch (_) {
        return raw;
      }
    }
    if (type == 'Excel') {
      return raw.split('\n').map((l) => l.replaceAll('\t', ',')).join('\n');
    }
    return raw;
  }

  // ── Allowed extensions per type ────────────────────────────────────────────
  Map<String, List<String>> _extMap() => {
        'CSV':   ['csv'],
        'Excel': ['xlsx', 'xls'],
        'PDF':   ['pdf'],
        'JSON':  ['json'],
      };

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag handle ───────────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.onSurface.withAlpha(51),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const Text('Import Student Data',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                'Pick a file from your device or paste data below.',
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(ctx).colorScheme.onSurface.withAlpha(153)),
              ),
              const SizedBox(height: 20),

              // ── File type selector ────────────────────────────────────
              const Text('File Type',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final entry in [
                    ('CSV', Icons.table_rows_outlined),
                    ('Excel', Icons.grid_on_outlined),
                    ('PDF', Icons.picture_as_pdf_outlined),
                    ('JSON', Icons.code_outlined),
                  ])
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          selectedType = entry.$1;
                          final ext = {
                            'CSV':   '.csv',
                            'Excel': '.xlsx',
                            'PDF':   '.pdf',
                            'JSON':  '.json',
                          }[entry.$1]!;
                          final base = nameCtrl.text.replaceAll(
                              RegExp(r'\.(csv|xlsx|pdf|json)$',
                                  caseSensitive: false),
                              '');
                          nameCtrl.text = '$base$ext';
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selectedType == entry.$1
                                ? Theme.of(ctx).colorScheme.primaryContainer
                                : Theme.of(ctx).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedType == entry.$1
                                  ? Theme.of(ctx).colorScheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                entry.$2,
                                size: 22,
                                color: selectedType == entry.$1
                                    ? Theme.of(ctx).colorScheme.primary
                                    : Theme.of(ctx).colorScheme.onSurface.withAlpha(153),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry.$1,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: selectedType == entry.$1
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: selectedType == entry.$1
                                      ? Theme.of(ctx).colorScheme.primary
                                      : Theme.of(ctx).colorScheme.onSurface.withAlpha(153),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Format hint banner ────────────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Container(
                  key: ValueKey(selectedType),
                  width: double.infinity,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx)
                        .colorScheme
                        .secondaryContainer
                        .withAlpha(120),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          size: 15,
                          color: Theme.of(ctx).colorScheme.secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _hintForType(selectedType),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(ctx).colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── PICK FILE BUTTON ──────────────────────────────────────
              // file_picker ^11.x: FilePicker.platform was removed.
              // Use FilePicker.pickFiles() directly as a static method.
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: _extMap()[selectedType] ?? ['csv'],
                      withData: true,
                    );
                    if (result != null && result.files.isNotEmpty) {
                      final picked = result.files.single;
                      final bytes = picked.bytes;
                      if (bytes != null) {
                        nameCtrl.text = picked.name;
                        textCtrl.text = utf8.decode(bytes, allowMalformed: true);
                        setState(() {});
                      }
                    }
                  },
                  icon: const Icon(Icons.folder_open_outlined),
                  label: Text('Pick $selectedType File from Device'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 50),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── OR divider ────────────────────────────────────────────
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or paste manually',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(ctx).colorScheme.onSurface.withAlpha(120),
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 12),

              // ── File name field ───────────────────────────────────────
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'File name',
                  isDense: true,
                  prefixIcon: Icon(Icons.insert_drive_file_outlined, size: 18),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // ── Data paste area ───────────────────────────────────────
              TextField(
                controller: textCtrl,
                maxLines: 7,
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  labelText:
                      'Paste ${selectedType == 'JSON' ? 'JSON' : selectedType} data here',
                  alignLabelWithHint: true,
                  hintText: _placeholderForType(selectedType),
                  hintStyle: const TextStyle(fontSize: 12),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // ── Import button ─────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    final raw = textCtrl.text.trim();
                    if (raw.isNotEmpty) {
                      final csv = _convertToCsv(raw, selectedType);
                      state.importCsvText(csv, nameCtrl.text);
                      Navigator.pop(ctx);
                    }
                  },
                  icon: const Icon(Icons.upload_file),
                  label: Text('Import $selectedType'),
                  style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 50)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50)),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ─── Students Content ─────────────────────────────────────────────────────────

class _StudentsContent extends StatelessWidget {
  final AppState state;
  const _StudentsContent({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Stats row
        if (state.isProcessed && state.classStats != null)
          _StatsRow(stats: state.classStats!),
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            onChanged: state.setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Search students...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: state.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => state.setSearchQuery(''),
                    )
                  : null,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
              filled: true,
            ),
          ),
        ),
        // Export button row (only when processed)
        if (state.isProcessed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: _ExportBar(state: state),
          ),
        // Table header
        _TableHeader(state: state),
        // Student list
        Expanded(
          child: state.paginatedStudents.isEmpty
              ? const Center(child: Text('No students found'))
              : ListView.builder(
                  itemCount: state.paginatedStudents.length,
                  itemBuilder: (ctx, i) => _StudentRow(
                    student: state.paginatedStudents[i],
                    isProcessed: state.isProcessed,
                  ),
                ),
        ),
        // Pagination
        _PaginationBar(state: state),
      ],
    );
  }
}

// ─── Export Bar ───────────────────────────────────────────────────────────────

class _ExportBar extends StatelessWidget {
  final AppState state;
  const _ExportBar({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.file_download_outlined, size: 16),
        const SizedBox(width: 6),
        const Text('Export:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        for (final fmt in ExportFormat.values)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _ExportChip(format: fmt, state: state),
          ),
      ],
    );
  }
}

class _ExportChip extends StatelessWidget {
  final ExportFormat format;
  final AppState state;
  const _ExportChip({required this.format, required this.state});

  IconData get _icon {
    switch (format) {
      case ExportFormat.csv:   return Icons.table_rows_outlined;
      case ExportFormat.excel: return Icons.grid_on_outlined;
      case ExportFormat.pdf:   return Icons.picture_as_pdf_outlined;
      case ExportFormat.json:  return Icons.code_outlined;
    }
  }

  String get _label {
    switch (format) {
      case ExportFormat.csv:   return 'CSV';
      case ExportFormat.excel: return 'Excel';
      case ExportFormat.pdf:   return 'PDF';
      case ExportFormat.json:  return 'JSON';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDefault = state.defaultExportFormat == format;
    return GestureDetector(
      onTap: () {
        state.setDefaultExportFormat(format);
        state.exportData(format, context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDefault
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDefault
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon,
                size: 14,
                color: isDefault
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withAlpha(153)),
            const SizedBox(width: 4),
            Text(_label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isDefault ? FontWeight.bold : FontWeight.normal,
                  color: isDefault
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withAlpha(153),
                )),
          ],
        ),
      ),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final ClassStatistics stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _StatChip(
              label: 'Avg',
              value: stats.average.toStringAsFixed(1),
              color: Theme.of(context).colorScheme.primary),
          _StatChip(
              label: 'High',
              value: stats.highest.toStringAsFixed(1),
              color: const Color(0xFF4CAF50)),
          _StatChip(
              label: 'Low',
              value: stats.lowest.toStringAsFixed(1),
              color: const Color(0xFFF44336)),
          _StatChip(
              label: 'Pass',
              value: '${stats.passRate.toStringAsFixed(0)}%',
              color: const Color(0xFF4CAF50)),
          _StatChip(
              label: 'Total',
              value: '${stats.totalStudents}',
              color: Theme.of(context).colorScheme.secondary),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(fontSize: 11, color: color.withAlpha(179))),
          const SizedBox(width: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

// ─── Table Header ─────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  final AppState state;
  const _TableHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _SortHeader('ID', SortColumn.id, state, flex: 2),
          _SortHeader('Name', SortColumn.name, state, flex: 4),
          _SortHeader('CA', SortColumn.caScore, state, flex: 2),
          _SortHeader('Exam', SortColumn.examScore, state, flex: 2),
          if (state.isProcessed) ...[
            _SortHeader('Final', SortColumn.finalScore, state, flex: 2),
            _SortHeader('Grade', SortColumn.grade, state, flex: 2),
          ],
        ],
      ),
    );
  }
}

class _SortHeader extends StatelessWidget {
  final String label;
  final SortColumn col;
  final AppState state;
  final int flex;
  const _SortHeader(this.label, this.col, this.state, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    final active = state.sortColumn == col;
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: () => state.sortBy(col),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.bold : FontWeight.w600,
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withAlpha(179),
              ),
            ),
            if (active)
              Icon(
                state.sortAscending
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                size: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Student Row ──────────────────────────────────────────────────────────────

class _StudentRow extends StatelessWidget {
  final StudentRecord student;
  final bool isProcessed;
  const _StudentRow({required this.student, required this.isProcessed});

  @override
  Widget build(BuildContext context) {
    final errorBg = student.hasError
        ? Theme.of(context).colorScheme.errorContainer.withAlpha(77)
        : Colors.transparent;

    return Container(
      color: errorBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(student.id,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis)),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                if (student.hasError)
                  Tooltip(
                    message: student.errorMessage,
                    child: const Icon(Icons.warning_amber,
                        size: 14, color: Colors.orange),
                  ),
                Expanded(
                  child: Text(
                    student.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
              flex: 2,
              child: Text(student.caScore.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 13))),
          Expanded(
              flex: 2,
              child: Text(student.examScore.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 13))),
          if (isProcessed) ...[
            Expanded(
              flex: 2,
              child: Text(
                student.finalScore.toStringAsFixed(1),
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: gradeColor(student.grade, context).withAlpha(26),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  student.grade,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: gradeColor(student.grade, context),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Pagination Bar ───────────────────────────────────────────────────────────

class _PaginationBar extends StatelessWidget {
  final AppState state;
  const _PaginationBar({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border:
            Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${state.filteredStudents.length} students',
            style: const TextStyle(fontSize: 12),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: state.currentPage > 0
                    ? () => state.setPage(state.currentPage - 1)
                    : null,
                iconSize: 20,
              ),
              Text(
                'Page ${state.currentPage + 1} / ${state.totalPages}',
                style: const TextStyle(fontSize: 12),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: state.currentPage < state.totalPages - 1
                    ? () => state.setPage(state.currentPage + 1)
                    : null,
                iconSize: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}