// lib/views/settings_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/models.dart';


class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Grading Scales ─────────────────────────────────────────────
          _SectionCard(
            title: 'Grading Scales',
            icon: Icons.grading,
            child: Column(
              children: [
                ...state.gradingScales.map((scale) => _GradingScaleRow(
                      scale: scale,
                      isSelected:
                          state.selectedScale.id == scale.id,
                      onSelect: () => state.setDefaultScale(scale),
                      onEdit: () =>
                          _showScaleDialog(context, state, scale),
                    )),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () =>
                      _showScaleDialog(context, state, null),
                  icon: const Icon(Icons.add, size: 18),
                  label:
                      const Text('Create Custom Grading Scale'),
                  style: OutlinedButton.styleFrom(
                      minimumSize:
                          const Size(double.infinity, 44)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Export Format Preferences ──────────────────────────────────
          _SectionCard(
            title: 'Export Format',
            icon: Icons.file_download_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose the default format when exporting grades.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(153),
                  ),
                ),
                const SizedBox(height: 14),
                // 2×2 grid of format cards
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.4,
                  children: [
                    _ExportFormatCard(
                      format: ExportFormat.csv,
                      icon: Icons.table_rows_outlined,
                      label: 'CSV',
                      description: 'Comma separated',
                      color: const Color(0xFF4CAF50),
                      isSelected:
                          state.defaultExportFormat ==
                              ExportFormat.csv,
                      onTap: () => state
                          .setDefaultExportFormat(ExportFormat.csv),
                    ),
                    _ExportFormatCard(
                      format: ExportFormat.excel,
                      icon: Icons.grid_on_outlined,
                      label: 'Excel',
                      description: '.xlsx spreadsheet',
                      color: const Color(0xFF2196F3),
                      isSelected:
                          state.defaultExportFormat ==
                              ExportFormat.excel,
                      onTap: () => state.setDefaultExportFormat(
                          ExportFormat.excel),
                    ),
                    _ExportFormatCard(
                      format: ExportFormat.pdf,
                      icon: Icons.picture_as_pdf_outlined,
                      label: 'PDF',
                      description: 'Printable report',
                      color: const Color(0xFFF44336),
                      isSelected:
                          state.defaultExportFormat ==
                              ExportFormat.pdf,
                      onTap: () => state
                          .setDefaultExportFormat(ExportFormat.pdf),
                    ),
                    _ExportFormatCard(
                      format: ExportFormat.json,
                      icon: Icons.code_outlined,
                      label: 'JSON',
                      description: 'Structured data',
                      color: const Color(0xFFFF9800),
                      isSelected:
                          state.defaultExportFormat ==
                              ExportFormat.json,
                      onTap: () => state.setDefaultExportFormat(
                          ExportFormat.json),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Active format banner
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withAlpha(120),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 16,
                          color:
                              Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Default export: ${_formatName(state.defaultExportFormat)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .colorScheme
                              .primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Appearance ─────────────────────────────────────────────────
          _SectionCard(
            title: 'Appearance',
            icon: Icons.palette_outlined,
            child: SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle:
                  const Text('Toggle dark/light theme'),
              value: state.isDarkTheme,
              onChanged: (_) => state.toggleTheme(),
              contentPadding: EdgeInsets.zero,
            ),
          ),

          const SizedBox(height: 16),

          // ── About ──────────────────────────────────────────────────────
          _SectionCard(
            title: 'About',
            icon: Icons.info_outline,
            child: Column(
              children: [
                _InfoRow('App', 'Grade Calculator'),
                _InfoRow('Version', '1.0.0'),
                _InfoRow('Platform', 'Flutter / Dart'),
                _InfoRow('Pass Threshold', '40 / 100'),
                _InfoRow('Max CA Score', '30'),
                _InfoRow('Max Exam Score', '70'),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _formatName(ExportFormat f) {
    switch (f) {
      case ExportFormat.csv:   return 'CSV (.csv)';
      case ExportFormat.excel: return 'Excel (.xlsx)';
      case ExportFormat.pdf:   return 'PDF (.pdf)';
      case ExportFormat.json:  return 'JSON (.json)';
    }
  }

  void _showScaleDialog(
      BuildContext context, AppState state, GradingScale? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) =>
          _GradingScaleDialog(state: state, existing: existing),
    );
  }
}

// ─── Export Format Card ───────────────────────────────────────────────────────

class _ExportFormatCard extends StatelessWidget {
  final ExportFormat format;
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ExportFormatCard({
    required this.format,
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withAlpha(30)
              : Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 22,
                color: isSelected
                    ? color
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(153)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? color
                          : Theme.of(context)
                              .colorScheme
                              .onSurface,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected
                          ? color.withAlpha(180)
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(128),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle,
                  size: 16, color: color),
          ],
        ),
      ),
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard(
      {required this.title,
      required this.icon,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 20,
                    color:
                        Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                          fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withAlpha(179))),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── Grading Scale Row ────────────────────────────────────────────────────────

class _GradingScaleRow extends StatelessWidget {
  final GradingScale scale;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  const _GradingScaleRow({
    required this.scale,
    required this.isSelected,
    required this.onSelect,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).dividerColor,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isSelected
            ? Theme.of(context)
                .colorScheme
                .primaryContainer
                .withAlpha(77)
            : null,
      ),
      child: ListTile(
        dense: true,
        leading: Radio<String>(
          value: scale.id,
          groupValue: isSelected ? scale.id : null,
          onChanged: (_) => onSelect(),
        ),
        title: Text(scale.name,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14)),
        subtitle: Text(
          scale.ranges
              .map((r) =>
                  '${r.grade}:${r.minScore.toInt()}-${r.maxScore.toInt()}')
              .join('  '),
          style: const TextStyle(fontSize: 11),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          onPressed: onEdit,
        ),
      ),
    );
  }
}

// ─── Grading Scale Dialog ─────────────────────────────────────────────────────

class _GradingScaleDialog extends StatefulWidget {
  final AppState state;
  final GradingScale? existing;
  const _GradingScaleDialog(
      {required this.state, this.existing});

  @override
  State<_GradingScaleDialog> createState() =>
      _GradingScaleDialogState();
}

class _GradingScaleDialogState
    extends State<_GradingScaleDialog> {
  late final TextEditingController _nameCtrl;
  late List<_RangeEntry> _entries;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.existing?.name ?? '');
    _entries = widget.existing?.ranges
            .map((r) => _RangeEntry(
                  grade: r.grade,
                  min: r.minScore,
                  max: r.maxScore,
                  colorHex: r.colorHex,
                ))
            .toList() ??
        [
          _RangeEntry(
              grade: 'A',
              min: 70,
              max: 100,
              colorHex: '#4CAF50'),
          _RangeEntry(
              grade: 'B',
              min: 60,
              max: 69.99,
              colorHex: '#8BC34A'),
          _RangeEntry(
              grade: 'C',
              min: 50,
              max: 59.99,
              colorHex: '#FF9800'),
          _RangeEntry(
              grade: 'D',
              min: 40,
              max: 49.99,
              colorHex: '#FF5722'),
          _RangeEntry(
              grade: 'F',
              min: 0,
              max: 39.99,
              colorHex: '#F44336'),
        ];
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final scale = GradingScale(
      id: widget.existing?.id ??
          name.toLowerCase().replaceAll(' ', '_'),
      name: name,
      ranges: _entries
          .map((e) => GradeRange(
                minScore: e.min,
                maxScore: e.max,
                grade: e.grade,
                colorHex: e.colorHex,
              ))
          .toList(),
    );
    widget.state.addOrUpdateScale(scale);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext ctx) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom:
              MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  widget.existing == null
                      ? 'Create Scale'
                      : 'Edit Scale',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Scale Name',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Text('Grade',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                FontWeight.bold))),
                Expanded(
                    flex: 2,
                    child: Text('Min',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                FontWeight.bold))),
                Expanded(
                    flex: 2,
                    child: Text('Max',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                FontWeight.bold))),
                SizedBox(width: 32),
              ],
            ),
            const Divider(height: 8),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: _entries.length,
                itemBuilder: (_, i) => _RangeRow(
                  entry: _entries[i],
                  onChanged: () => setState(() {}),
                  onRemove: _entries.length > 1
                      ? () => setState(
                          () => _entries.removeAt(i))
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => setState(() => _entries.add(
                  _RangeEntry(
                      grade: '',
                      min: 0,
                      max: 0,
                      colorHex: '#000000'))),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Range'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                      onPressed: _save,
                      child: const Text('Save')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                      onPressed: () =>
                          Navigator.pop(ctx),
                      child: const Text('Cancel')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RangeEntry {
  String grade;
  double min;
  double max;
  String colorHex;
  _RangeEntry(
      {required this.grade,
      required this.min,
      required this.max,
      required this.colorHex});
}

class _RangeRow extends StatelessWidget {
  final _RangeEntry entry;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;
  const _RangeRow(
      {required this.entry,
      required this.onChanged,
      this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: entry.grade,
              onChanged: (v) {
                entry.grade = v;
                onChanged();
              },
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: entry.min.toString(),
              onChanged: (v) {
                entry.min = double.tryParse(v) ?? 0;
                onChanged();
              },
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: entry.max.toString(),
              onChanged: (v) {
                entry.max = double.tryParse(v) ?? 0;
                onChanged();
              },
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          SizedBox(
            width: 32,
            child: onRemove != null
                ? IconButton(
                    icon: const Icon(
                        Icons.remove_circle_outline,
                        size: 18,
                        color: Colors.red),
                    onPressed: onRemove,
                    padding: EdgeInsets.zero,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}