// lib/state/app_state.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/vault_manager.dart';
import '../services/file_parser_service.dart';

class AppState extends ChangeNotifier {
  AppView _currentView = AppView.home;
  AppView get currentView => _currentView;
  void navigate(AppView v) { _currentView = v; notifyListeners(); }

  bool _isDarkTheme = false;
  bool get isDarkTheme => _isDarkTheme;
  void toggleTheme() { _isDarkTheme = !_isDarkTheme; notifyListeners(); }

  List<StudentRecord> _importedStudents = [];
  List<StudentRecord> get importedStudents => _importedStudents;

  String _currentFileName = '';
  String get currentFileName => _currentFileName;

  bool _isProcessed = false;
  bool get isProcessed => _isProcessed;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;
  void setSearchQuery(String q) { _searchQuery = q; _currentPage = 0; notifyListeners(); }

  SortColumn _sortColumn = SortColumn.name;
  SortColumn get sortColumn => _sortColumn;

  bool _sortAscending = true;
  bool get sortAscending => _sortAscending;

  void sortBy(SortColumn col) {
    if (_sortColumn == col) {
      _sortAscending = !_sortAscending;
    } else {
      _sortColumn = col;
      _sortAscending = true;
    }
    notifyListeners();
  }

  int _currentPage = 0;
  int get currentPage => _currentPage;
  final int pageSize = 15;
  void setPage(int p) { _currentPage = p; notifyListeners(); }

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  void _showError(String msg) {
    _errorMessage = msg;
    _successMessage = null;
    notifyListeners();
  }

  void _showSuccess(String msg) {
    _successMessage = msg;
    _errorMessage = null;
    notifyListeners();
    Future.delayed(const Duration(seconds: 4), () {
      _successMessage = null;
      notifyListeners();
    });
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  List<ProcessedFile> _savedFiles = [];
  List<ProcessedFile> get savedFiles => _savedFiles;

  ProcessedFile? _selectedVaultFile;
  ProcessedFile? get selectedVaultFile => _selectedVaultFile;
  void selectVaultFile(ProcessedFile? f) { _selectedVaultFile = f; notifyListeners(); }

  String _vaultSearchQuery = '';
  String get vaultSearchQuery => _vaultSearchQuery;
  void setVaultSearchQuery(String q) { _vaultSearchQuery = q; notifyListeners(); }

  String _vaultViewMode = 'grid';
  String get vaultViewMode => _vaultViewMode;
  void setVaultViewMode(String m) { _vaultViewMode = m; notifyListeners(); }

  List<GradingScale> _gradingScales = [kDefaultGradingScale, kDistinctionScale];
  List<GradingScale> get gradingScales => _gradingScales;

  GradingScale _selectedScale = kDefaultGradingScale;
  GradingScale get selectedScale => _selectedScale;

  ExportFormat _defaultExportFormat = ExportFormat.csv;
  ExportFormat get defaultExportFormat => _defaultExportFormat;
  void setDefaultExportFormat(ExportFormat f) {
    _defaultExportFormat = f;
    notifyListeners();
  }

  final _vaultManager = VaultManager();

  AppState() { _loadVault(); }

  List<StudentRecord> get filteredStudents {
    final q = _searchQuery.toLowerCase().trim();
    var list = q.isEmpty
        ? [..._importedStudents]
        : _importedStudents
            .where((s) => s.name.toLowerCase().contains(q) || s.id.toLowerCase().contains(q))
            .toList();
    list.sort((a, b) {
      int cmp;
      switch (_sortColumn) {
        case SortColumn.id:         cmp = a.id.compareTo(b.id); break;
        case SortColumn.name:       cmp = a.name.compareTo(b.name); break;
        case SortColumn.caScore:    cmp = a.caScore.compareTo(b.caScore); break;
        case SortColumn.examScore:  cmp = a.examScore.compareTo(b.examScore); break;
        case SortColumn.finalScore: cmp = a.finalScore.compareTo(b.finalScore); break;
        case SortColumn.grade:      cmp = a.grade.compareTo(b.grade); break;
      }
      return _sortAscending ? cmp : -cmp;
    });
    return list;
  }

  List<StudentRecord> get paginatedStudents {
    final all = filteredStudents;
    final start = _currentPage * pageSize;
    if (start >= all.length) return [];
    return all.skip(start).take(pageSize).toList();
  }

  int get totalPages => (filteredStudents.length / pageSize).ceil().clamp(1, 999);

  ClassStatistics? get classStats =>
      _importedStudents.isEmpty ? null : computeStatistics(_importedStudents);

  List<ProcessedFile> get filteredVaultFiles => _vaultSearchQuery.isEmpty
      ? _savedFiles
      : _savedFiles.where((f) => f.fileName.toLowerCase().contains(_vaultSearchQuery.toLowerCase())).toList();

  Future<void> importCsvText(String csvContent, String fileName) async {
    _isLoading = true;
    _isProcessed = false;
    notifyListeners();
    try {
      final students = FileParserService.parseCsvText(csvContent);
      if (students.isEmpty) throw Exception('No student records found');
      _importedStudents = students;
      _currentFileName = fileName;
      _currentPage = 0;
      _showSuccess('${students.length} students loaded from $fileName');
    } catch (e) {
      _showError(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void loadSampleData() {
    importCsvText(FileParserService.generateSampleCsv(), 'sample_grades.csv');
  }

  void processGrades() {
    if (_importedStudents.isEmpty) return;
    _isLoading = true;
    notifyListeners();
    _importedStudents = _importedStudents.map((s) {
      final validation = validateScores(s);
      if (!validation.isValid) {
        return s.copyWith(hasError: true, errorMessage: validation.errors.join('; '));
      }
      final finalScore = s.caScore + s.examScore;
      return s.copyWith(
        finalScore: finalScore,
        grade: _selectedScale.getGrade(finalScore),
        status: finalScore >= 40.0 ? 'Pass' : 'Fail',
        hasError: false,
        errorMessage: '',
      );
    }).toList();
    _isProcessed = true;
    _isLoading = false;
    _showSuccess('Grades processed for ${_importedStudents.length} students');
  }

  Future<void> saveToVault() async {
    if (!_isProcessed || _importedStudents.isEmpty) return;
    final now = DateTime.now();
    final file = ProcessedFile(
      id: now.millisecondsSinceEpoch.toString(),
      fileName: _currentFileName,
      importDateStr: '${now.day}/${now.month}/${now.year}',
      students: [..._importedStudents],
      fileType: 'CSV',
      gradingScaleUsed: _selectedScale.name,
    );
    await _vaultManager.addFile(file);
    await _loadVault();
    _showSuccess('Saved to vault successfully');
  }

  Future<void> deleteFromVault(String id) async {
    await _vaultManager.removeFile(id);
    if (_selectedVaultFile?.id == id) _selectedVaultFile = null;
    await _loadVault();
    _showSuccess('Deleted from vault');
  }

  Future<void> _loadVault() async {
    _savedFiles = await _vaultManager.loadVault();
    notifyListeners();
  }

  void setDefaultScale(GradingScale scale) {
    _selectedScale = scale;
    if (_isProcessed) {
      _isProcessed = false;
      _showSuccess('Grading scale changed. Please re-process grades.');
    }
    notifyListeners();
  }

  void addOrUpdateScale(GradingScale scale) {
    final idx = _gradingScales.indexWhere((s) => s.id == scale.id);
    if (idx >= 0) {
      _gradingScales = [..._gradingScales]..[idx] = scale;
    } else {
      _gradingScales = [..._gradingScales, scale];
    }
    notifyListeners();
  }

  void clearCurrentData() {
    _importedStudents = [];
    _currentFileName = '';
    _isProcessed = false;
    _currentPage = 0;
    notifyListeners();
  }

  void exportData(ExportFormat format, BuildContext context) {
    if (_importedStudents.isEmpty || !_isProcessed) {
      _showError('Process grades before exporting.');
      return;
    }
    final content = _buildExportContent(format);
    final label = _formatLabel(format);
    final icon = _formatIcon(format);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: Theme.of(ctx).colorScheme.primary),
            const SizedBox(width: 8),
            Text('Export as $label'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_importedStudents.length} students  •  $_currentFileName',
                style: TextStyle(fontSize: 12,
                    color: Theme.of(ctx).colorScheme.onSurface.withAlpha(153)),
              ),
              const SizedBox(height: 10),
              Container(
                height: 220,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    content,
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap "Copy All" to copy data to clipboard.',
                style: TextStyle(fontSize: 12,
                    color: Theme.of(ctx).colorScheme.onSurface.withAlpha(153)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: content));
              if (ctx.mounted) {
                Navigator.pop(ctx);
                _showSuccess('$label data copied to clipboard!');
              }
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy All'),
          ),
        ],
      ),
    );
  }

  String _buildExportContent(ExportFormat format) {
    switch (format) {
      case ExportFormat.csv:   return _buildCsv();
      case ExportFormat.excel: return _buildTsv();
      case ExportFormat.pdf:   return _buildPlainTable();
      case ExportFormat.json:  return _buildJson();
    }
  }

  String _buildCsv() {
    final sb = StringBuffer();
    sb.writeln('Student ID,Student Name,CA Score,Exam Score,Final Score,Grade,Status');
    for (final s in _importedStudents) {
      sb.writeln('${s.id},${s.name},${s.caScore.toStringAsFixed(2)},${s.examScore.toStringAsFixed(2)},${s.finalScore.toStringAsFixed(2)},${s.grade},${s.status}');
    }
    return sb.toString();
  }

  String _buildTsv() {
    final sb = StringBuffer();
    sb.writeln('Student ID\tStudent Name\tCA Score\tExam Score\tFinal Score\tGrade\tStatus');
    for (final s in _importedStudents) {
      sb.writeln('${s.id}\t${s.name}\t${s.caScore.toStringAsFixed(2)}\t${s.examScore.toStringAsFixed(2)}\t${s.finalScore.toStringAsFixed(2)}\t${s.grade}\t${s.status}');
    }
    return sb.toString();
  }

  String _buildPlainTable() {
    final sb = StringBuffer();
    sb.writeln('GRADE REPORT — $_currentFileName');
    sb.writeln('Grading Scale: ${_selectedScale.name}');
    sb.writeln('=' * 65);
    sb.writeln('${'ID'.padRight(10)}${'Name'.padRight(24)}${'CA'.padLeft(5)}${'Exam'.padLeft(6)}${'Final'.padLeft(7)}${'Grade'.padLeft(8)}${'Status'.padLeft(8)}');
    sb.writeln('-' * 65);
    for (final s in _importedStudents) {
      sb.writeln('${s.id.padRight(10)}${s.name.padRight(24)}${s.caScore.toStringAsFixed(1).padLeft(5)}${s.examScore.toStringAsFixed(1).padLeft(6)}${s.finalScore.toStringAsFixed(1).padLeft(7)}${s.grade.padLeft(8)}${s.status.padLeft(8)}');
    }
    sb.writeln('=' * 65);
    final stats = computeStatistics(_importedStudents);
    sb.writeln('Total: ${stats.totalStudents}   Pass: ${stats.passCount}   Fail: ${stats.failCount}   Average: ${stats.average.toStringAsFixed(1)}   Pass Rate: ${stats.passRate.toStringAsFixed(0)}%');
    return sb.toString();
  }

  String _buildJson() {
    final stats = computeStatistics(_importedStudents);
    final sb = StringBuffer();
    sb.writeln('{');
    sb.writeln('  "file": "$_currentFileName",');
    sb.writeln('  "gradingScale": "${_selectedScale.name}",');
    sb.writeln('  "summary": {');
    sb.writeln('    "total": ${stats.totalStudents},');
    sb.writeln('    "pass": ${stats.passCount},');
    sb.writeln('    "fail": ${stats.failCount},');
    sb.writeln('    "average": ${stats.average.toStringAsFixed(2)},');
    sb.writeln('    "passRate": ${stats.passRate.toStringAsFixed(2)}');
    sb.writeln('  },');
    sb.writeln('  "students": [');
    for (int i = 0; i < _importedStudents.length; i++) {
      final s = _importedStudents[i];
      final comma = i < _importedStudents.length - 1 ? ',' : '';
      sb.writeln('    {"id":"${s.id}","name":"${s.name}","ca":${s.caScore.toStringAsFixed(2)},"exam":${s.examScore.toStringAsFixed(2)},"final":${s.finalScore.toStringAsFixed(2)},"grade":"${s.grade}","status":"${s.status}"}$comma');
    }
    sb.writeln('  ]');
    sb.write('}');
    return sb.toString();
  }

  String _formatLabel(ExportFormat f) {
    switch (f) {
      case ExportFormat.csv:   return 'CSV';
      case ExportFormat.excel: return 'Excel';
      case ExportFormat.pdf:   return 'PDF';
      case ExportFormat.json:  return 'JSON';
    }
  }

  IconData _formatIcon(ExportFormat f) {
    switch (f) {
      case ExportFormat.csv:   return Icons.table_rows_outlined;
      case ExportFormat.excel: return Icons.grid_on_outlined;
      case ExportFormat.pdf:   return Icons.picture_as_pdf_outlined;
      case ExportFormat.json:  return Icons.code_outlined;
    }
  }

  String exportAsCSV() => _buildCsv();
}
