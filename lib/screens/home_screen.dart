// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../models/calculator.dart';
import '../utils/excel_handler.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String? _loadedFileName;
  int _studentCount = 0;
  late AnimationController _pulseController;

  // Delayed init of animation
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Delayed init — animation only built after controller exists
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // Lambda-style import handler
  Future<void> _handleImport() async {
    setState(() => _isLoading = true);

    try {
      final students = await ExcelHandler.instance.importStudents();

      if (!mounted) return;
      if (students.isEmpty) {
        showAppSnackbar(context, 'No students found. Check your Excel format.',
            isError: true);
        return;
      }

      setState(() {
        _loadedFileName = 'File loaded';
        _studentCount = students.length;
      });

      final summary = GradeCalculator.instance.generateSummary(students);

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              ResultsScreen(students: students, summary: summary),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        showAppSnackbar(context, 'Error reading file: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Lambda for template download
  Future<void> _downloadTemplate() async {
    setState(() => _isLoading = true);
    try {
      final path = await ExcelHandler.instance.downloadTemplate();
      if (!mounted) return;
      if (path != null) {
        showAppSnackbar(context, 'Template saved to: $path');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Stack(
          children: [
            // Background grid decoration
            _buildGridDecoration(),
            // Main content
            SafeArea(
              child: Row(
                children: [
                  // Left sidebar
                  _buildSidebar(),
                  // Main area
                  Expanded(child: _buildMainContent()),
                ],
              ),
            ),
            if (_isLoading) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildGridDecoration() {
    return Positioned.fill(
      child: CustomPaint(painter: _GridPainter()),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 72,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Logo
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 40),
          _sidebarIcon(Icons.home_rounded, true),
          _sidebarIcon(Icons.bar_chart_rounded, false),
          _sidebarIcon(Icons.history, false),
          const Spacer(),
          _sidebarIcon(Icons.settings_outlined, false),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sidebarIcon(IconData icon, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: active ? AppColors.accentGlow : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: active
              ? Border.all(color: AppColors.accent.withOpacity(0.5))
              : null,
        ),
        child: Icon(icon,
            color: active ? AppColors.accent : AppColors.textMuted, size: 20),
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 48),
          // Drop zone
          _buildDropZone(),
          const SizedBox(height: 32),
          // Grade legend
          _buildGradeLegend(),
          const SizedBox(height: 32),
          // Formula info
          _buildFormulaCard(),
          const SizedBox(height: 32),
          // Template download
          _buildTemplateCard(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentGlow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accent.withOpacity(0.4)),
              ),
              child: const Text('ACADEMIC TOOL',
                  style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Student Grade\nCalculator',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 42,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -1,
            )),
        const SizedBox(height: 12),
        const Text(
          'Upload your student marks Excel file to auto-calculate\ngrades and download the complete report.',
          style: TextStyle(
              color: AppColors.textSecondary, fontSize: 15, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildDropZone() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleImport,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (_, child) => Transform.scale(
          scale: _loadedFileName == null ? _pulseAnimation.value : 1.0,
          child: child,
        ),
        child: Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _loadedFileName != null
                  ? AppColors.gradeA
                  : AppColors.accent.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _loadedFileName != null
                    ? AppColors.gradeA.withOpacity(0.1)
                    : AppColors.accentGlow,
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_loadedFileName == null) ...[
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.accentGlow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.upload_file_rounded,
                      color: AppColors.accent, size: 30),
                ),
                const SizedBox(height: 20),
                const Text('Click to Upload Student File',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('Supports .xlsx and .xls files',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ] else ...[
                const Icon(Icons.check_circle,
                    color: AppColors.gradeA, size: 48),
                const SizedBox(height: 16),
                Text('$_studentCount Students Loaded',
                    style: const TextStyle(
                        color: AppColors.gradeA,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _handleImport,
                  child: const Text('Upload Different File',
                      style: TextStyle(color: AppColors.accent)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradeLegend() {
    final grades = [
      ('A', '75–100', AppColors.gradeA, 'Distinction'),
      ('AB', '70–74', AppColors.gradeAB, 'Merit'),
      ('B', '60–69', AppColors.gradeB, 'Credit'),
      ('C', '50–59', AppColors.gradeC, 'Pass'),
      ('D', '40–49', AppColors.gradeD, 'Supplementary'),
      ('F', '0–39', AppColors.gradeF, 'Fail'),
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('GRADING SCALE',
              style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: grades
                .map((g) => _gradePill(g.$1, g.$2, g.$3, g.$4))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _gradePill(String grade, String range, Color color, String remark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(grade,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(range,
                  style: TextStyle(
                      color: color.withOpacity(0.8), fontSize: 12)),
              Text(remark,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaCard() {
    return GlassCard(
      glowing: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.functions, color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              const Text('MARK CALCULATION FORMULA',
                  style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'Final Mark = (Assignment × 20%) + (Test × 30%) + (Exam × 50%)',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Courier New'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard() {
    return GlassCard(
      child: Row(
        children: [
          const Icon(Icons.download_outlined,
              color: AppColors.accent, size: 32),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Download Excel Template',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                SizedBox(height: 4),
                Text(
                    'Get a pre-formatted template with the correct column structure',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          AccentButton(
            label: 'GET TEMPLATE',
            icon: Icons.download,
            onPressed: _isLoading ? null : _downloadTemplate,
            outlined: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.accent),
            SizedBox(height: 16),
            Text('Processing...',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

// ── Background Grid Painter ───────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0D2B6E).withOpacity(0.3)
      ..strokeWidth = 0.5;

    const spacing = 50.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
