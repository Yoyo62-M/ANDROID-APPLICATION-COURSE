// lib/views/vault_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class VaultView extends StatelessWidget {
  const VaultView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(state.vaultViewMode == 'grid' ? Icons.view_list_outlined : Icons.grid_view_outlined),
            onPressed: () => state.setVaultViewMode(state.vaultViewMode == 'grid' ? 'list' : 'grid'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: TextField(
              onChanged: state.setVaultSearchQuery,
              decoration: InputDecoration(
                hintText: 'Search saved files...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: state.vaultSearchQuery.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => state.setVaultSearchQuery(''))
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: state.filteredVaultFiles.isEmpty
                ? _EmptyVault()
                : state.vaultViewMode == 'grid'
                    ? _GridView(state: state)
                    : _ListView(state: state),
          ),
        ],
      ),
    );
  }
}

class _EmptyVault extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(color: cs.primaryContainer, shape: BoxShape.circle),
              child: Icon(Icons.folder_open_outlined, size: 50, color: cs.primary),
            ),
            const SizedBox(height: 24),
            Text('Vault is Empty', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              'Process grades on the Home tab then tap "Save to Vault".',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurface.withAlpha(153)),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridView extends StatelessWidget {
  final AppState state;
  const _GridView({required this.state});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.05,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: state.filteredVaultFiles.length,
      itemBuilder: (ctx, i) => _FileCard(file: state.filteredVaultFiles[i], state: state),
    );
  }
}

class _ListView extends StatelessWidget {
  final AppState state;
  const _ListView({required this.state});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemCount: state.filteredVaultFiles.length,
      itemBuilder: (ctx, i) => _FileListTile(file: state.filteredVaultFiles[i], state: state),
    );
  }
}

class _FileCard extends StatelessWidget {
  final ProcessedFile file;
  final AppState state;
  const _FileCard({required this.file, required this.state});

  @override
  Widget build(BuildContext context) {
    final passColor = file.passRate >= 60 ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
    return Card(
      child: InkWell(
        onTap: () => _showFileDetail(context, file, state),
        onLongPress: () => _confirmDelete(context, file.id, state),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.description_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
                  const Spacer(),
                  Text(file.importDateStr, style: const TextStyle(fontSize: 10)),
                ],
              ),
              const SizedBox(height: 8),
              Text(file.fileName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  overflow: TextOverflow.ellipsis, maxLines: 2),
              const Spacer(),
              Text('${file.totalStudents} students', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withAlpha(153))),
              const SizedBox(height: 2),
              Text('${file.passRate.toStringAsFixed(0)}% pass',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: passColor)),
              const SizedBox(height: 2),
              Text('Avg: ${file.average.toStringAsFixed(1)}',
                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withAlpha(153))),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileListTile extends StatelessWidget {
  final ProcessedFile file;
  final AppState state;
  const _FileListTile({required this.file, required this.state});

  @override
  Widget build(BuildContext context) {
    final passColor = file.passRate >= 60 ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.description_outlined, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(file.fileName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text('${file.totalStudents} students • Avg ${file.average.toStringAsFixed(1)}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${file.passRate.toStringAsFixed(0)}%',
                style: TextStyle(fontWeight: FontWeight.bold, color: passColor, fontSize: 15)),
            Text('pass', style: TextStyle(fontSize: 10, color: passColor)),
          ],
        ),
        onTap: () => _showFileDetail(context, file, state),
        onLongPress: () => _confirmDelete(context, file.id, state),
      ),
    );
  }
}

void _showFileDetail(BuildContext context, ProcessedFile file, AppState state) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => _FileDetailPage(file: file, state: state)),
  );
}

void _confirmDelete(BuildContext context, String id, AppState state) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete File'),
      content: const Text('Remove this file from the vault?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () { Navigator.pop(ctx); state.deleteFromVault(id); },
          style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

// ─── File Detail Page ─────────────────────────────────────────────────────────

class _FileDetailPage extends StatelessWidget {
  final ProcessedFile file;
  final AppState state;
  const _FileDetailPage({required this.file, required this.state});

  @override
  Widget build(BuildContext context) {
    final stats = computeStatistics(file.students);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(file.fileName, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: cs.error),
            onPressed: () {
              Navigator.pop(context);
              _confirmDelete(context, file.id, state);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats summary
          Container(
            padding: const EdgeInsets.all(16),
            color: cs.surfaceContainerHighest,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _DetailStat('Students', '${stats.totalStudents}', cs.primary),
                    _DetailStat('Average', stats.average.toStringAsFixed(1), cs.secondary),
                    _DetailStat('Pass Rate', '${stats.passRate.toStringAsFixed(0)}%',
                        stats.passRate >= 60 ? const Color(0xFF4CAF50) : const Color(0xFFF44336)),
                    _DetailStat('Highest', stats.highest.toStringAsFixed(1), const Color(0xFF4CAF50)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Icon(Icons.info_outline, size: 13, color: cs.onSurface.withAlpha(128)),
                  const SizedBox(width: 6),
                  Text('Scale: ${file.gradingScaleUsed} • ${file.importDateStr}',
                      style: TextStyle(fontSize: 12, color: cs.onSurface.withAlpha(153))),
                ]),
              ],
            ),
          ),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: cs.surfaceContainerHighest.withAlpha(128),
            child: const Row(
              children: [
                Expanded(flex: 5, child: Text('Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('CA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Exam', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Final', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Grade', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: file.students.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: cs.outlineVariant.withAlpha(80)),
              itemBuilder: (ctx, i) {
                final s = file.students[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
                            Text(s.id, style: TextStyle(fontSize: 10, color: cs.onSurface.withAlpha(128))),
                          ],
                        ),
                      ),
                      Expanded(flex: 2, child: Text(s.caScore.toStringAsFixed(1), style: const TextStyle(fontSize: 12))),
                      Expanded(flex: 2, child: Text(s.examScore.toStringAsFixed(1), style: const TextStyle(fontSize: 12))),
                      Expanded(flex: 2, child: Text(s.finalScore.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                          decoration: BoxDecoration(
                            color: gradeColor(s.grade, ctx).withAlpha(26),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(s.grade,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: gradeColor(s.grade, ctx)),
                              textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _DetailStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
