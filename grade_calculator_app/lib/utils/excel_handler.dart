// lib/utils/excel_handler.dart
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/calculator.dart';

class ExcelHandler {
  // Lazy singleton
  static final ExcelHandler _instance = ExcelHandler._internal();
  static ExcelHandler get instance => _instance;
  ExcelHandler._internal();

  // ── Import Excel File ─────────────────────────────────────
  Future<List<StudentGrade>> importStudents() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      dialogTitle: 'Select Student Marks File',
    );

    if (result == null || result.files.isEmpty) return [];

    final file = File(result.files.single.path!);
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet == null) return [];

    final students = <StudentGrade>[];

    // Skip header row (row 0), process from row 1
    for (int i = 1; i < sheet.maxRows; i++) {
      final row = sheet.row(i);
      if (row.isEmpty) continue;

      final cellVal = (int idx) {
        final cell = row.length > idx ? row[idx]?.value : null;
        return cell?.toString().trim() ?? '';
      };

      final numVal = (int idx) {
        final val = cellVal(idx);
        return double.tryParse(val) ?? 0.0;
      };

      final id = cellVal(0);
      final name = cellVal(1);
      if (id.isEmpty && name.isEmpty) continue;

      students.add(StudentGrade(
        studentId: id.isEmpty ? 'N/A' : id,
        studentName: name.isEmpty ? 'Unknown' : name,
        assignmentMark: numVal(2).clamp(0.0, 100.0),
        testMark: numVal(3).clamp(0.0, 100.0),
        examMark: numVal(4).clamp(0.0, 100.0),
      ));
    }

    return students;
  }

  // ── Export Results to Excel ───────────────────────────────
  Future<String?> exportResults(
    List<StudentGrade> students,
    Map<String, dynamic> summary,
  ) async {
    final excel = Excel.createExcel();

    // ── Sheet 1: Student Results ──
    final resultsSheet = excel['Student Results'];
    excel.setDefaultSheet('Student Results');

    // Header row with styling
    final headers = [
      'Student ID',
      'Student Name',
      'Assignment (20%)',
      'Test (30%)',
      'Exam (50%)',
      'Final Mark',
      'Grade',
      'Grade Points',
      'Remark',
    ];

    // Header style
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#0D2B6E'),
      fontColorHex: ExcelColor.fromHexString('#00D4FF'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      fontSize: 11,
    );

    for (int col = 0; col < headers.length; col++) {
      final cell = resultsSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = headerStyle;
    }

    // Grade color mapping lambda
    final gradeColor = (String grade) => switch (grade) {
          'A' => '#00C853',
          'AB' => '#00B0FF',
          'B' => '#76FF03',
          'C' => '#FFD740',
          'D' => '#FF6D00',
          'F' => '#FF1744',
          _ => '#FFFFFF',
        };

    // Data rows
    for (int i = 0; i < students.length; i++) {
      final s = students[i];
      final rowData = [
        s.studentId,
        s.studentName,
        s.assignmentMark,
        s.testMark,
        s.examMark,
        s.finalMark,
        s.grade,
        s.gradePoints,
        s.remark,
      ];

      final isEven = i % 2 == 0;
      final rowStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString(
            isEven ? '#0A1628' : '#0F1F3D'),
        fontColorHex: ExcelColor.fromHexString('#E8F4FD'),
        horizontalAlign: HorizontalAlign.Center,
      );

      for (int col = 0; col < rowData.length; col++) {
        final cell = resultsSheet.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: i + 1));

        final val = rowData[col];
        if (val is double) {
          cell.value = DoubleCellValue(val);
        } else {
          cell.value = TextCellValue(val.toString());
        }

        // Grade column gets special color
        if (col == 6) {
          cell.cellStyle = CellStyle(
            backgroundColorHex: ExcelColor.fromHexString('#0A1628'),
            fontColorHex:
                ExcelColor.fromHexString(gradeColor(s.grade)),
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
          );
        } else {
          cell.cellStyle = rowStyle;
        }
      }
    }

    // Auto column widths
    final colWidths = [15, 25, 18, 12, 12, 12, 8, 13, 15];
    for (int i = 0; i < colWidths.length; i++) {
      resultsSheet.setColumnWidth(i, colWidths[i].toDouble());
    }

    // ── Sheet 2: Summary ──
    final summarySheet = excel['Summary'];

    final summaryHeaderStyle = CellStyle(
      bold: true,
      fontSize: 13,
      backgroundColorHex: ExcelColor.fromHexString('#0D2B6E'),
      fontColorHex: ExcelColor.fromHexString('#00D4FF'),
      horizontalAlign: HorizontalAlign.Center,
    );

    // Title
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .value = TextCellValue('GRADE SUMMARY REPORT');
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .cellStyle = summaryHeaderStyle;

    final summaryData = [
      ['Total Students', summary['total'].toString()],
      ['Highest Mark', (summary['highest'] as double).toStringAsFixed(1)],
      ['Lowest Mark', (summary['lowest'] as double).toStringAsFixed(1)],
      ['Class Average', (summary['average'] as double).toStringAsFixed(1)],
      ['Pass Count', summary['passCount'].toString()],
      ['Fail Count', summary['failCount'].toString()],
      ['Pass Rate', '${(summary['passRate'] as double).toStringAsFixed(1)}%'],
    ];

    final labelStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#7B9CC4'),
      backgroundColorHex: ExcelColor.fromHexString('#0A1628'),
    );
    final valueStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#E8F4FD'),
      backgroundColorHex: ExcelColor.fromHexString('#0F1F3D'),
      horizontalAlign: HorizontalAlign.Center,
    );

    for (int i = 0; i < summaryData.length; i++) {
      final labelCell = summarySheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 2));
      labelCell.value = TextCellValue(summaryData[i][0]);
      labelCell.cellStyle = labelStyle;

      final valueCell = summarySheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 2));
      valueCell.value = TextCellValue(summaryData[i][1]);
      valueCell.cellStyle = valueStyle;
    }

    // Grade distribution
    final dist = summary['distribution'] as Map<String, int>;
    int distRow = summaryData.length + 4;
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: distRow))
        .value = TextCellValue('Grade Distribution');
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: distRow))
        .cellStyle = summaryHeaderStyle;

    distRow++;
    dist.forEach((grade, count) {
      summarySheet
          .cell(
              CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: distRow))
          .value = TextCellValue('Grade $grade');
      summarySheet
          .cell(
              CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: distRow))
          .value = TextCellValue('$count student(s)');
      distRow++;
    });

    summarySheet.setColumnWidth(0, 22);
    summarySheet.setColumnWidth(1, 18);

    // ── Save File ──
    final dir = await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();

    final timestamp = DateTime.now();
    final filename =
        'GradeReport_${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}.xlsx';
    final outputPath = '${dir.path}/$filename';

    final fileBytes = excel.save();
    if (fileBytes == null) return null;

    await File(outputPath).writeAsBytes(fileBytes);
    return outputPath;
  }

  // ── Generate sample template ──────────────────────────────
  Future<String?> downloadTemplate() async {
    final excel = Excel.createExcel();
    final sheet = excel['Students'];
    excel.setDefaultSheet('Students');

    final headers = [
      'Student ID',
      'Student Name',
      'Assignment Mark (0-100)',
      'Test Mark (0-100)',
      'Exam Mark (0-100)',
    ];

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#0D2B6E'),
      fontColorHex: ExcelColor.fromHexString('#00D4FF'),
      horizontalAlign: HorizontalAlign.Center,
    );

    for (int i = 0; i < headers.length; i++) {
      final cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // Sample data
    final samples = [
      ['STU001', 'John Smith', '78', '82', '75'],
      ['STU002', 'Jane Doe', '90', '88', '92'],
      ['STU003', 'Michael Brown', '45', '52', '48'],
    ];

    for (int i = 0; i < samples.length; i++) {
      for (int j = 0; j < samples[i].length; j++) {
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1))
            .value = TextCellValue(samples[i][j]);
      }
    }

    sheet.setColumnWidth(0, 15);
    sheet.setColumnWidth(1, 25);
    sheet.setColumnWidth(2, 22);
    sheet.setColumnWidth(3, 20);
    sheet.setColumnWidth(4, 20);

    final dir = await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final path = '${dir.path}/student_template.xlsx';
    final bytes = excel.save();
    if (bytes == null) return null;
    await File(path).writeAsBytes(bytes);
    return path;
  }
}
