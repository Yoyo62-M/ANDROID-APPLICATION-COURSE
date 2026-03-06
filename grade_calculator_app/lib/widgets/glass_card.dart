// lib/widgets/glass_card.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool glowing;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.onTap,
    this.glowing = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: glowing ? AppColors.accent : AppColors.border,
            width: glowing ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: glowing ? AppColors.accentGlow : Colors.black26,
              blurRadius: glowing ? 20 : 8,
              spreadRadius: glowing ? 2 : 0,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ─── Stat Card ───────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final IconData icon;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Grade Badge ─────────────────────────────────────────────
class GradeBadge extends StatelessWidget {
  final String grade;
  static const _gradeColors = {
    'A': AppColors.gradeA,
    'AB': AppColors.gradeAB,
    'B': AppColors.gradeB,
    'C': AppColors.gradeC,
    'D': AppColors.gradeD,
    'F': AppColors.gradeF,
  };

  const GradeBadge({super.key, required this.grade});

  @override
  Widget build(BuildContext context) {
    final color = _gradeColors[grade] ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        grade,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ─── Accent Button ───────────────────────────────────────────
class AccentButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool outlined;
  final Color? color;

  const AccentButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.outlined = false,
    this.color,
  });

  @override
  State<AccentButton> createState() => _AccentButtonState();
}

class _AccentButtonState extends State<AccentButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final col = widget.color ?? AppColors.accent;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          gradient: widget.outlined
              ? null
              : LinearGradient(
                  colors: _hovered
                      ? [col.withOpacity(0.9), col.withOpacity(0.7)]
                      : [col, col.withOpacity(0.8)],
                ),
          color: widget.outlined ? Colors.transparent : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: col, width: widget.outlined ? 1.5 : 0),
          boxShadow: _hovered && !widget.outlined
              ? [BoxShadow(color: col.withOpacity(0.4), blurRadius: 16)]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onPressed,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon,
                      size: 18,
                      color: widget.outlined ? col : AppColors.background),
                  const SizedBox(width: 10),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.outlined ? col : AppColors.background,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Snackbar helper ─────────────────────────────────────────
void showAppSnackbar(BuildContext context, String message,
    {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? AppColors.gradeF : AppColors.gradeA,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: const TextStyle(color: AppColors.textPrimary))),
        ],
      ),
      backgroundColor: AppColors.card,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: isError ? AppColors.gradeF : AppColors.gradeA,
            width: 1),
      ),
      duration: const Duration(seconds: 4),
    ),
  );
}
